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
    import std.typecons;
    import std.traits;
    private {
        int[funcType] _funcCount;

        __gshared void*[string] registeredMethods;
        __gshared string[] methodNames;
        __gshared Queue!(Tag*) _serviceQueue;
        __gshared Server* _server;
        __gshared void function(CompletionQueue!"Next"*, T, Tag*)[string] _handlers;
        __gshared TaskPool _servicerPool;

        immutable ulong _serviceId;

        enum funcType {
            NORMAL,
            STREAM_CLIENT,
            STREAM_SERVER,
            STREAM_CLIENT_SERVER
        }

        __gshared T _serviceInstance;
        __gshared bool _run;
    }

    __gshared int _totalServiced;
    int _totalQueued;
    int n_threads;

    // function may be called by another thread other then the main() thread
    // make sure that doesnt muck up

    ulong runners() {
        return _servicerPool.size;
    }

    int totalServiced() {
        return _totalServiced;
    }

    int totalQueued() {
        return _totalQueued;
    }

    int queueLength() {
        return _serviceQueue.count;
    }
    
    void stop() {
        _run = false;
        _servicerPool.stop();
        _serviceQueue.notifyAll();
    }

    void addToQueue(Tag* t) {
        if(t.metadata[0] != 0xDE) {
            return;
        }

        _serviceQueue.put(t);
        DEBUG!"placed tag on queue";
        _totalQueued++;
    }


    // this function will always be called by main()

    bool register(Server* server) {
        alias parent = BaseTypeTuple!T[1];

        _server = server;
        __gshared Tag*[] tags;

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
                    _handlers[remoteName] = (CompletionQueue!"Next"* queue, T instance, Tag* _tag) {
                            DEBUG!"hello";
                            auto callMeta = &_tag.ctx;
                            DEBUG!"grabbing mutex lock";
                            callMeta.mutex.lock;
                            scope(exit) callMeta.mutex.unlock;
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
                                auto r = reader.read!(1);
                                funcIn = r.front;
                                r.popFront;
                                reader.finish();
                                
                                DEBUG!"passing off to user";
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, funcOut);");
                                DEBUG!"starting write";
                                writer.start();
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
                                auto r = reader.read(1);
                                funcIn = r.moveFront;
                                r.popFront;

                                writer.start();
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, writer);");
                            }

                            DEBUG!"func call: writing";
                            writer.finish(stat);
                            DEBUG!"func call: done";
                            
                            callMeta.data.cleanup();
                            grpc_call_unref(*callMeta.call);
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

        for (int i = 0; i < 1; i++) {
            auto t = task!(
            () {
                /* First, request all calls (this will be done when the Server requests us to initialize) */
                /* As well, create a thread-local completion queue */
                auto _cq = CompletionQueue!"Next"();
                ulong workerIndex = _servicerPool.workerIndex();
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
                    _serviceQueue.notify(); // if the notify gets called, we have an exclusive lock on the mutex
                    {
                        DEBUG!"hit event on task %d"(workerIndex);
                        if (_serviceQueue.empty()) {
                            DEBUG!"service queue was actually empty..";
                            _serviceQueue.unlock;
                            continue;
                        }

                        DEBUG!"grabbing tag";
                        Tag* tag = _serviceQueue.front;
                        //DEBUG("got tag: ", tag);
                        if (tag == null) {
                            ERROR!"got null tag?";
                            _serviceQueue.unlock;
                            continue;
                        }
                        
                        if (tag.metadata[5] != cast(ubyte)workerIndex) {
                            DEBUG!"hit a tag that isn't meant for us";
                            _serviceQueue.unlock;
                            _serviceQueue.signal;
                            continue;
                        }
                        
                        // otherwise, it's our tag and we have to pop it off 
                        _serviceQueue.pop;
                        _serviceQueue.unlock;

                        string remoteName = tag.methodName;

                        DEBUG!"done";

                        try { 
                            _handlers[remoteName](&_cq, _serviceInstance, tag);
                        } catch(Exception e) {
                            import grpc.common.batchcall;
                            import interop.headers;

                            ERROR!"CAUGHT EXCEPTION: %s"(e.msg);

                            BatchCall call = new BatchCall();
                            scope(exit) destroy(call);
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
            })();

            _servicerPool.put(t);

        }


        return true;
    }

    this(ulong serviceId, ref CompletionQueue!"Next" cq, void*[string] methodTable) {

        _run = true;
        _serviceQueue = new Queue!(Tag*)();
        _serviceInstance = new T();
        _servicerPool = new TaskPool();

        registeredMethods = methodTable.dup;
        _serviceId = serviceId;


        with(funcType) { 
            _funcCount[NORMAL] = 0;
            _funcCount[STREAM_CLIENT] = 0;
            _funcCount[STREAM_SERVER] = 0;
            _funcCount[STREAM_CLIENT_SERVER] = 0;
        }

            }
        
}
    
