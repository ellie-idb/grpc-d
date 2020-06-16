module grpc.service;
import interop.headers;
import grpc.logger;
import core.thread;
import grpc.server : Server;
import grpc.common.call;
import google.rpc.status;
import grpc.core.tag;
import grpc.common.cq;
import grpc.service.queue;
import std.parallelism;
import grpc.core.utils;

//should/can be overridden by clients
interface ServiceHandlerInterface {
    bool register(Server* server);
    void addToQueue(Tag* t);
    void stop();
    ulong runners();
    int queueLength();
    int totalQueued();
    int totalServiced();
}

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
    class ServicerThread : Thread {
        this() {
            super(&run);
        }
        
        ~this() {
            INFO!"service thread";
        }
        
        Tag*[] tags;
        Queue!(Tag*) servicerQueue;
        void function(CompletionQueue!"Next"*, T, Tag*)[] handlers;
        ulong workerIndex;
        T _serviceInstance;
    
    private:
        void run() {
            /* First, request all calls (this will be done when the Server requests us to initialize) */
            /* As well, create a thread-local completion queue */
            _serviceInstance = new T();
            auto _cq = CompletionQueue!"Next"();
            servicerQueue = new Queue!(Tag*)();

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
                
                _cq.requestCall(tag.method, tag, _server); 
            }
            
            while (_run) {
                DEBUG!"hello from task %d"(workerIndex);
                servicerQueue.notify(); // if the notify gets called, we have an exclusive lock on the mutex
                {
                    //DEBUG!"hit event on task %d"(workerIndex);
                    if (servicerQueue.empty()) {
                        DEBUG!"service queue was actually empty..";
                        servicerQueue.unlock;
                        continue;
                    }
                    DEBUG!"grabbing tag";
                    Tag* tag = servicerQueue.front;
                    DEBUG!"got tag: %x"(tag);
                    if (tag == null) {
                        ERROR!"got null tag?";
                        servicerQueue.unlock;
                        continue;
                    }
                    
                    // xxx: should never happen
                    if (tag.metadata[5] != cast(ubyte)workerIndex) {
                        DEBUG!"hit a tag that isn't meant for us (%d vs %d)"(tag.metadata[5], cast(ubyte)workerIndex);
                        Thread.sleep(100.msecs);
                        servicerQueue.unlock;
                        servicerQueue.signal;
                        continue;
                    }
                    
                    // otherwise, it's our tag and we have to pop it off 
                    servicerQueue.pop;
                    servicerQueue.unlock;

                    if (tag.metadata[4] >= tlsTags.length) {
                        ERROR!"got a large tag??";
                        continue;
                    }

                    tag = tlsTags[tag.metadata[4]]; // grab it off of our local cache
                    string remoteName = tag.methodName;
                    DEBUG!"done";

                    try { 
                        handlers[tag.metadata[4]](&_cq, _serviceInstance, tag);
                    } catch(Exception e) {
                        import grpc.common.batchcall;
                        import interop.headers;
                        ERROR!"CAUGHT EXCEPTION: %s"(e.msg);

                        BatchCall call = new BatchCall();
                        int cancelled = 0;
                        call.addOp(new RecvCloseOnServerOp(&cancelled));
                        call.addOp(new SendInitialMetadataOp());
                        call.addOp(new SendStatusFromServerOp(GRPC_STATUS_INTERNAL, e.msg));
                        call.run(&_cq, tag);
                    }

                    grpc_call_error error = _cq.requestCall(tag.method, tag, _server);
                    if (error != GRPC_CALL_OK) {
                        ERROR!"could not request call %s"(error);
                    }
                }
            }
        }
    }
    import std.typecons;
    import std.traits;
    private {
        int[funcType] _funcCount;
        
        void*[string] registeredMethods;
        string[] methodNames;
        Server* _server;
        ThreadGroup threads;
        ServicerThread[] _threads; // do not ever use
        ulong workingThreads;
        immutable ulong _serviceId;

        enum funcType {
            NORMAL,
            STREAM_CLIENT,
            STREAM_SERVER,
            STREAM_CLIENT_SERVER
        }

        bool _run;
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
        _run = false;
        threads.joinAll();
        foreach(thread; _threads) {
            thread.servicerQueue.notifyAll();
        }
    }

    void addToQueue(Tag* t) {
        if(t.metadata[0] != 0xDE) {
            return;
        }

        assert(t.metadata[5] < workingThreads, "should never have a metadata value this high?"); 

        ServicerThread tgt = _threads[t.metadata[5]];

        if (!tgt.isRunning()) {
            DEBUG!"WTF?";
            tgt.join();
            return;
        }

        tgt.servicerQueue.put(t);
        DEBUG!"placed tag on queue";
    }


    // this function will always be called by main()

    bool register(Server* server) {
        alias parent = BaseTypeTuple!T[1];

        _server = server;
        Tag*[] tags;
        void function(CompletionQueue!"Next"*, T, Tag*)[] _handlers;
        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
            () {
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
                    rpcTag.metadata[0] = 0xDE;
                    rpcTag.metadata[1] = cast(ubyte)_funcCount[NORMAL];
                    rpcTag.metadata[2] = cast(ubyte)_serviceId;
                    rpcTag.metadata[4] = cast(ubyte)i;
                    _handlers ~= (CompletionQueue!"Next"* queue, T instance, Tag* _tag) {
                            DEBUG!"hello";
                            DEBUG!"grabbing mutex lock";
                            if (_tag == null) {
                                ERROR!"received null tag";
                                return;
                            }
                            _tag.ctx.mutex.lock;
                            scope(exit) _tag.ctx.mutex.unlock;
                            
                            DEBUG!"locked!";
                            ServerReader!(input) reader = new ServerReader!(input)(queue, _tag);
                            ServerWriter!(output) writer = new ServerWriter!(output)(queue, _tag);
                            
                            /* results from our call */
                            Status stat;
                            input funcIn;
                            output funcOut;
                            DEBUG!"func call: %s"(remoteName);
                            static if(hasUDA!(val, ClientStreaming) == 0 && hasUDA!(val, ServerStreaming) == 0) {
                                DEBUG!"func call: regular";
                                DEBUG!"reading";
                                funcIn = reader.readOne();
                                reader.finish();
                                
                                DEBUG!"passing off to user";
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, funcOut);");
                                DEBUG!"starting write";
                                writer.start(_tag);
                                DEBUG!"writing";
                                writer.write(funcOut);
                                DEBUG!"done write";
                            }
                            else static if(hasUDA!(val, ClientStreaming) && hasUDA!(val, ServerStreaming)) {
                                DEBUG("func call: bidi");

                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, writer);");
                            }
                            else static if(hasUDA!(val, ClientStreaming)) {
                                DEBUG("func call: client streaming");
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, funcOut);");
                                writer.start();
                                writer.write(funcOut);
                            }   
                            else static if(hasUDA!(val, ServerStreaming)) {
                                DEBUG("func call: server streaming");
                                funcIn = reader.readOne();

                                writer.start();
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, writer);");
                            }

                            DEBUG!"func call: writing";
                            writer.finish(stat);
                            DEBUG!"func call: done";
                            
                            //destroy(reader);
                            //destroy(writer);
                            
                            
                            
                           /*
                                IMPORTANT:
                                As we are now done with the call,
                                we have to unref it, so that the call is freed,
                                as well as any memory allocated in the call arena.
                            */
                            grpc_call_unref(*_tag.ctx.call);
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
            }();
        }

        for (ulong i = 0; i < workingThreads; i++) {
            auto t = new ServicerThread();
            threads.add(t);
            _threads ~= t;
            t.handlers = _handlers.dup;
            t.workerIndex = i;
            t.isDaemon = true;
            t.tags = tags.dup;
            t.start();

        }


        return true;
    }

    this(ulong serviceId, ref CompletionQueue!"Next" cq, void*[string] methodTable) {

        _run = true;

        registeredMethods = methodTable.dup;
        _serviceId = serviceId;
        threads = new ThreadGroup();

        workingThreads = 4;

        with(funcType) { 
            _funcCount[NORMAL] = 0;
            _funcCount[STREAM_CLIENT] = 0;
            _funcCount[STREAM_SERVER] = 0;
            _funcCount[STREAM_CLIENT_SERVER] = 0;
        }

    }
        
}
    
