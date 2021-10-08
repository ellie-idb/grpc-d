module grpc.service;
import core.atomic;
import interop.headers;
import grpc.logger;
import core.thread;
import grpc.server : Server;
import grpc.common.call;
import google.rpc.status;
import grpc.core.tag;
import grpc.common.cq;
import grpc.core.utils;
import std.experimental.allocator : theAllocator, make, dispose;

// Every Service template class is guaranteed to at least implement these functions
interface ServiceHandlerInterface {
    bool register(Server server);
    void stop();
    void kickstart();
    ulong runners();
    int queueLength();
    int totalQueued();
    int totalServiced();
}

// Since we dynamically generate the function handler through UDAs,
// we need some way to get the type that it is expecting (be it, through a ServerReader/ServerWriter interface, or a POD type)
// These two templates resolve that, and get us the type.

mixin template Reader(T) {
    static if(is(TemplateOf!T == void)) {
        alias input = T;
    }
    else {
        alias input = TemplateArgsOf!(T)[0];
    }

}

mixin template Writer(T) {
    static if(is(TemplateOf!T == void)) {
        alias output = T;
    }
    else {
        alias output = TemplateArgsOf!(T)[0];
    }
}

class Service(T) : ServiceHandlerInterface {
    alias ServiceHandlerType = void function(CompletionQueue!"Next", T, Tag*);
    class ServicerThread : Thread {
        this() {
            super(&run);
        }
        
        ~this() {
        }
        
        /* Set by the main thread */
        Tag*[] tags;
        ServiceHandlerType[] handlers;
        ulong workerIndex;

    private:
        /* Thread local things */
        CompletionQueue!"Next" notificationCq;
        CompletionQueue!"Next" callCq;
        T _serviceInstance;
        shared bool _run;

        void run() {

            /* 
               PHASE 1:
               First, we create every thread-local structure. This includes:
               a servicerInstance, where we send requests to. (DO NOT EXPECT a global instance to exist)
               As well, we generate our thread-local completion queues here (to avoid pitfalls with global CQs and queues),
               and register them with the server, then block while we wait for every thread to synchronize progress.

               As well, we ALSO register a custom allocator (so we can avoid using the GC)
            */
            import core.memory : GC;   
            import std.experimental.allocator.mallocator: Mallocator;
            import std.experimental.allocator : theAllocator, allocatorObject;
            
            theAllocator = allocatorObject(Mallocator.instance);

            _serviceInstance = theAllocator.make!T();
            notificationCq = theAllocator.make!(CompletionQueue!"Next")();
            callCq = theAllocator.make!(CompletionQueue!"Next")();

            DEBUG!"registering (thread: %d)"(workerIndex);
            // This allows us to receive notifications of calls of ANY kind (but we only listen for the calls specified in the service definition)
            _server.registerQueue(notificationCq);
            DEBUG!"registered (thread: %d)"(workerIndex);
            atomicOp!"+="(threadInitDone, 1);

            // Block while the rest of the threads spool up, and wait for the server to signal
            // that it has started, and it is safe to request calls on our CQ
            while (!atomicLoad(threadOk)) {
                Thread.sleep(1.msecs);
            }

            /* 
               PHASE 2:
               Here, we duplicate the global Tag table, and register the call associated with it
               to our thread-local completion queue. This ensures that we'll get notified when the Server 
               receives a call with it's method name.
            */

            DEBUG!"beginning phase 2 (thread: %d)"(workerIndex);
            // DUPLICATE every tag into a thread-local tag cache, and mark it such
            Tag*[] tlsTags;
            foreach (_tag; tags) {
                Tag* tag = Tag();
                DEBUG!"duplicating tags for method (%x)"(tag);
                tag.method = _tag.method;
                tag.methodName = _tag.methodName.dup;
                tag.metadata = _tag.metadata.dup;            
                // TODO: fix metadata array so we can have more then sizeof(ubyte) workers!
                // this is an arbitrary limitation that i eventually want to fix- either by
                // adding an associated worker index, or something along those lines
                tag.metadata[5] = cast(ubyte)workerIndex;
                DEBUG!"tag.metadata: %s"(tag.metadata);
                tlsTags ~= tag;
                
                // this OFFICIALLY binds the _cq to a specific tag
                
                callCq.requestCall(tag.method, tag, _server, notificationCq); 
            }

            /*
                PHASE 3:
                Here, we begin the main loop to service requests. This continues,
                until the queue is shutdown, or _run is set to false.
            */

            // GC gets in the way (and leads to spurious segfaults)
            

            atomicStore(_run, true);
            while (atomicLoad(_run)) {
                auto item = notificationCq.next(10.seconds);
                notificationCq.lock();
                scope(exit) notificationCq.unlock();
                if (item.type == GRPC_OP_COMPLETE) {
                    DEBUG!"hello from task %d"(workerIndex);
                    DEBUG!"hit something";
                } else if (item.type == GRPC_QUEUE_SHUTDOWN) {
                    DEBUG!"shutdown";
                    _run = false;
                    continue;
                } else if(item.type == GRPC_QUEUE_TIMEOUT) {
                    DEBUG!"timeout";
                    continue;
                }

                if (notificationCq.inShutdownPath) {
                    DEBUG!"we are in shutdown path";
                    _run = false;
                    break;
                }

                DEBUG!"grabbing tag";
                Tag* tag = cast(Tag*)item.tag;
                DEBUG!"got tag: %x"(tag);

                // xxx: should never happen
                if (tag == null) {
                    ERROR!"got null tag?";
                    continue;
                }

                // ditto, should never happen
                if (tag.metadata[5] != cast(ubyte)workerIndex) {
                    ERROR!"DROPPED CALL";
                    continue;
                }

                // ditto, should never happen
                if (tag.metadata[4] >= tlsTags.length) {
                    ERROR!"got a large tag??";
                    continue;
                }

                DEBUG!"running handler";

                // call the compiler-generated handler here with our thread-local data
                try { 
                    handlers[tag.metadata[4]](callCq, _serviceInstance, tag);
                } catch(Exception e) {
                    ERROR!"SHOULD NEVER HAPPEN XXX";
                    ERROR!"CAUGHT EXCEPTION: %s"(e.msg);
                    ERROR!"FILE: %s:%d"(e.file, e.line);
                    ERROR!"BACKTRACE: %s"(e.info);
                    assert(0);
                }

                // make sure we can live to service another call!
                grpc_call_error error = callCq.requestCall(tag.method, tag, _server, notificationCq);
                if (error != GRPC_CALL_OK) {
                    ERROR!"could not request call %s"(error);
                }
            }

            theAllocator.dispose(callCq);
            theAllocator.dispose(notificationCq);
            theAllocator.dispose(_serviceInstance);
        }
    }
    import std.typecons;
    import std.traits;
    private {
        shared int threadInitDone = 0;
        // shared synchronization primitive
        shared bool threadOk;
        int[funcType] _funcCount;
        
        void*[string] registeredMethods;
        string[] methodNames;
        Server _server;
        ThreadGroup threads;
        ServicerThread[] _threads; // do not ever use
        immutable ulong workingThreads;
        immutable ulong _serviceId;

        enum funcType {
            NORMAL,
            STREAM_CLIENT,
            STREAM_SERVER,
            STREAM_CLIENT_SERVER
        }
    }

    int _totalServiced;
    int _totalQueued;

    // function may be called by another thread other then the main() thread
    // make sure that doesnt muck up
    
    ulong runners() {
        ulong r = 0;
        foreach(thread; threads) {
            if (thread.isRunning()) r += 1;
        }
        
        return r;
    }

    void kickstart() {
        atomicStore(threadOk, true);
    }

    int totalServiced() {
        return _totalServiced;
    }         

    int totalQueued() {
        return _totalQueued;
    }

    int queueLength() {
        return 0;
    }
    
    void stop() {
        // block while every thread terminates
        threads.joinAll();
    }

    // this function will always be called by main()

    bool register(Server server) {
        alias parent = BaseTypeTuple!T[1];

        _server = server;
        Tag*[] tags;
        ServiceHandlerType[] _handlers;
        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {{
                /*
                   The remote name (what is sent over the wire) is encoded
                   into the function with the help of the @RPC UDA.
                   This is part of the protobuf compiler, and gRPCD does
                   not require an additional pass with a gRPC compiler, as
                   UDAs eliminate the need for a second pass.
                */

                enum remoteName = getUDAs!(val, RPC)[0].methodName;
                
                DEBUG!"REGISTER: %s"(remoteName);
                if(remoteName !in registeredMethods) {
                    assert(0, "Expected the method to be present in the registered table..");
                }

                /* 
                   Create a unique tag for each call, and preserve it, as it contains
                   valuable metadata that we refer to when the main notification thread emits
                   a tag corresponding to a function call.
                */

                import grpc.stream.server.reader;
                import grpc.stream.server.writer;

                import std.traits;
                import std.meta;
                mixin Reader!(Parameters!val[0]);

                mixin Writer!(Parameters!val[1]);

                Tag* rpcTag = Tag();
                tags ~= rpcTag;
                DEBUG!"call: %x"(rpcTag.ctx.call);
                DEBUG!"adding tag to global";
                with(funcType) { 
                    // Why 0xDE? Well, *just* in case the Tag is corrupted,
                    // it should allow us to immediately ignore it
                    rpcTag.metadata[0] = 0xDE;
                    rpcTag.metadata[1] = cast(ubyte)_funcCount[NORMAL];
                    rpcTag.metadata[2] = cast(ubyte)_serviceId;
                    rpcTag.metadata[4] = cast(ubyte)i;
                    _handlers ~= (CompletionQueue!"Next" queue, T instance, Tag* _tag) {
                            import core.exception;
                            import core.time;
                            Exception thrownException = null;
                            DEBUG!"hello";
                            DEBUG!"grabbing mutex lock";
                            if (_tag == null) {
                                ERROR!"received null tag";
                                return;
                            }
                            _tag.ctx.mutex.lock;
                            scope(exit) _tag.ctx.mutex.unlock;
                            
                            _tag.ctx.timestamp = MonoTime.currTime;

                            DEBUG!"locked!";
                            ServerReader!(input) reader = theAllocator.make!(ServerReader!(input))(_tag, queue);
                            ServerWriter!(output) writer = theAllocator.make!(ServerWriter!(output))(_tag, queue);

                            /* results from our call */
                            Status stat;
                            input funcIn;
                            output funcOut;
                            DEBUG!"func call: %s"(remoteName);
                            try {
                                static if(hasUDA!(val, ClientStreaming) == 0 && hasUDA!(val, ServerStreaming) == 0) {
                                    DEBUG!"func call: regular";
                                    DEBUG!"reading";
                                    funcIn = reader.readOne();

                                    DEBUG!"passing off to user";
                                    mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, funcOut);");
                                    DEBUG!"starting write";
                                    writer.start();
                                    DEBUG!"writing";
                                    writer.write(funcOut);
                                    DEBUG!"done write";
                                }                                
                                else static if(hasUDA!(val, ClientStreaming) && hasUDA!(val, ServerStreaming)) {
                                    DEBUG!"func call: bidi";

                                    mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, writer);");
                                }
                                else static if(hasUDA!(val, ClientStreaming)) {
                                    DEBUG!"func call: client streaming";
                                    mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, funcOut);");
                                    writer.start();
                                    writer.write(funcOut);

                                }   
                                else static if(hasUDA!(val, ServerStreaming)) {
                                    DEBUG!"func call: server streaming";
                                    funcIn = reader.readOne();

                                    writer.start();
                                    mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, writer);");
                                }
                            } catch (Exception e) {
                                DEBUG!"caught an exception somewhere in the flow";
                                thrownException = e;
                            }

                            /* exception handling code */
                            /* throwing an exception DOES mean that some objects may leak */
                            if (thrownException !is null) {
                                import grpc.common.batchcall;
                                // try to flush the execution context if something threw
                                // not guaranteed to work
                                // basically an edge case to ensure that if an in-progress batch call failed, we drop it
                                grpc_call_cancel(*_tag.ctx.call, null);
                                
                                // update the status of the call
                                stat.code = GRPC_STATUS_INTERNAL;
                                stat.message = thrownException.msg;
                            }
                            DEBUG!"func call: writing with status %s"(stat);
                            DEBUG!"func call: done";
                            writer.finish(stat);
                            // RecvCloseOnServerOp needs to be at the end, or we will
                            // run into heap corruption (since we free every operation at the end)
                            reader.finish();

                           /*
                                IMPORTANT:
                                As we are now done with the call,
                                we have to unref it, so that the call is freed,
                                as well as any memory allocated in the call arena.
                            */

                            theAllocator.dispose(reader);
                            theAllocator.dispose(writer);

                            // Even though this may be allocated in the call arena,
                            // we still want to free it (just to be safe)
                            _tag.ctx.metadata.cleanup;
                            
                            // As well, free the byte buffer's memory (even IF it is in the call arena)
                            if (_tag.ctx.data.valid) {
                                _tag.ctx.data.cleanup;
                            }

                            grpc_call_unref(*_tag.ctx.call);
                            *_tag.ctx.call = null;
                     };

                    static if(hasUDA!(val, ClientStreaming) && hasUDA!(val, ServerStreaming)) {
                        pragma(msg, remoteName ~ ": Client && Server");
                        rpcTag.metadata[3] = STREAM_CLIENT_SERVER;
                        rpcTag.metadata[1] = cast(ubyte)_funcCount[STREAM_CLIENT_SERVER];
                        _funcCount[STREAM_CLIENT_SERVER]++;
                    }
                    else static if(hasUDA!(val, ClientStreaming)) {
                        pragma(msg, remoteName ~ ": Client");
                        rpcTag.metadata[3] = STREAM_CLIENT;
                        rpcTag.metadata[1] = cast(ubyte)_funcCount[STREAM_CLIENT];
                        _funcCount[STREAM_CLIENT]++;
                    }
                    else static if(hasUDA!(val, ServerStreaming)) {
                        pragma(msg, remoteName ~ ": Server");
                        rpcTag.metadata[3] = STREAM_SERVER;
                        rpcTag.metadata[1] = cast(ubyte)_funcCount[STREAM_SERVER];
                        _funcCount[STREAM_SERVER]++;
                    }
                    else {
                        _funcCount[NORMAL]++;
                    }
                }

                rpcTag.methodName = remoteName;
                rpcTag.method = registeredMethods[remoteName];
            }
        }

        /* Fork and spawn new threads for each worker */

        for (ulong i = 0; i < workingThreads; i++) {
            auto t = new ServicerThread();
            t.handlers = _handlers;
            t.workerIndex = i;
            // We *should* block for this thread to stop execution at the end
            t.isDaemon = false;
            // Duplicate the tag cache (but this WILL be duplicated once again to ensure thread-locality)
            t.tags = tags;
            t.start();

            threads.add(t);
            _threads ~= t;
        }

        // avoid race condition while we wait for all threads to fully spool

        while (atomicLoad(threadInitDone) != workingThreads) {
            Thread.sleep(1.msecs);
        }

        return true;
    }

    this(ulong serviceId, void*[string] methodTable) {
        registeredMethods = methodTable.dup;
        _serviceId = serviceId;
        threads = new ThreadGroup();

        // TODO: make this user-specifiable
        workingThreads = 8;

        with(funcType) { 
            _funcCount[NORMAL] = 0;
            _funcCount[STREAM_CLIENT] = 0;
            _funcCount[STREAM_SERVER] = 0;
            _funcCount[STREAM_CLIENT_SERVER] = 0;
        }

    }
        
}
    
