module grpc.service;
import core.thread;
import fearless;
import grpc.server : ServerPtr;
import grpc.common.call;
import google.rpc.status;
import grpc.core.tag;
import grpc.common.cq;
import grpc.service.queue;
import grpc.logger;

//should/can be overridden by clients
interface ServiceHandlerInterface {
    bool register(Exclusive!ServerPtr* server_);
    void addToQueue(Tag t);
    void stop();
    int totalQueued();
    int totalServiced();
}

//
/*
        _streamTable1[remoteName] = (T obj, ubyte[] _in, grpc_call* call, ref Tag tag) {
                            Status s;
                            import google.protobuf;

                            Parameters!val[0] funcIn = _in.fromProtobuf!(Parameters!val[0]);

                            mixin("auto writer = new " ~ __traits(identifier, Parameters!val[1]) ~ "!(" ~ __traits(identifier, TemplateArgsOf!(Parameters!val[1])[0]) ~ ")(cq, call, tag);");
//                            auto writer = new Parameters!(val[1])(cq, call, tag);
                            writer.start();

                            mixin("s = obj." ~ __traits(identifier, val) ~ "(funcIn, writer);");

                            writer.finish(s);
                        };

*/

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
        Object queueLock = new Object;
        void*[string] registeredMethods;

        CompletionQueue!"Next" globalCq;

        int[funcType] _funcCount;

        string[] methodNames;

        __gshared RemoteCall[string] callData;
        __gshared Exclusive!ServerPtr* _server;
        __gshared Tag[] _tagTable;

        void delegate(T, ref RemoteCall, ref Tag)[string] _handlers;
        immutable ulong _serviceId;

        enum funcType {
            NORMAL,
            STREAM_CLIENT,
            STREAM_SERVER,
            STREAM_CLIENT_SERVER
        }

        T _serviceInstance;
    }

    int _totalServiced;
    int _totalQueued;

    class ServicerThread : Thread {
        this() {
            _run = true;

            serviceQueue = new Queue!Tag();

            super(&run);
        }

        Queue!Tag serviceQueue;
        bool _run;

    private:
        void run() {
           // grpc_init();
            DEBUG("waiting on new events");
            serviceQueue.notify();
            {
                Tag tag = serviceQueue.front;
                serviceQueue.popFront;

                
                string remoteName = methodNames[tag.metadata[4]];

                auto oldTag = _tagTable[tag.metadata[4]];
                DEBUG("CALL: ", remoteName, " ID?: ", tag.metadata[5]);

                DEBUG(_tagTable[tag.metadata[4]].metadata, " ", oldTag.metadata);

                _tagTable[tag.metadata[4]] = _tagTable[tag.metadata[4]].dup();

                DEBUG("tag duplicated");

                _tagTable[tag.metadata[4]].metadata[5]++;

                DEBUG("incrementing tags");

                auto _oldCallData = callData[remoteName];

                DEBUG("call data copied");

                auto __cq = new CompletionQueue!"Pluck"();

                DEBUG("new CompletionQueue instantiated");

                callData[remoteName] = new RemoteCall(globalCq, __cq);
                callData[remoteName].requestCall(registeredMethods[remoteName], _tagTable[tag.metadata[4]], _server);

                DEBUG("registered fine!");

                try { 
                    _handlers[remoteName](_serviceInstance, _oldCallData, oldTag);
                } catch(Exception e) {
                    import grpc.common.batchcall;
                    import grpc.core.grpc_preproc;

                    ERROR("CAUGHT EXCEPTION: ", e.msg);

                    BatchCall call = new BatchCall(_oldCallData);
                    int cancelled = 0;
                    call.addOp(new RecvCloseOnServerOp(&cancelled));
                    call.addOp(new SendInitialMetadataOp());
                    call.addOp(new SendStatusFromServerOp(GRPC_STATUS_INTERNAL, e.msg));
                    call.run(oldTag);
                }

                DEBUG("func handler finished?");

//                DEBUG("TAGS MATCH?: ", oldTag == _tagTable[tag.metadata[4]]);

                _totalServiced++;
            }
            _run = false;
        }

    }

    // function may be called by another thread other then the main() thread
    // make sure that doesnt muck up

    int totalServiced() {
        return _totalServiced;
    }

    int totalQueued() {
        return _totalQueued;
    }

    void stop() {
//        mainThread._run = false;
    }

    void addToQueue(Tag t) {
        if(t.metadata[0] != 0xDE) {
            return;
        }

        auto thread = new ServicerThread();
        thread.start();

        thread.serviceQueue.put(t);
    }


    // this function will always be called by main()

    bool register(Exclusive!ServerPtr* server_) {
        alias parent = BaseTypeTuple!T[1];

        _server = server_;

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
                
                DEBUG("REGISTER: " ~ remoteName);
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

                with(funcType) { 

                    Tag rpcTag = new Tag();
                    rpcTag.metadata[0] = 0xDE;
                    rpcTag.metadata[1] = cast(ubyte)_funcCount[NORMAL];
                    rpcTag.metadata[2] = cast(ubyte)_serviceId;
                    rpcTag.metadata[4] = cast(ubyte)i;
                    _handlers[remoteName] = (T instance, ref RemoteCall data, ref Tag _tag) {
                            DEBUG("entered func body for ", remoteName);
                            Status stat;


                            ServerReader!(input) reader = new ServerReader!(input)(data, _tag);

                            DEBUG("Created read stream");

                            ServerWriter!(output) writer = new ServerWriter!(output)(data, _tag);

                            DEBUG("created write stream");


                            input funcIn;
                            output funcOut;
                            DEBUG("func call: ", remoteName);
                            static if(hasUDA!(val, ClientStreaming) == 0 && hasUDA!(val, ServerStreaming) == 0) {
                                DEBUG("func call: regular");
                                writer.start();

                                auto r = reader.read(1);
                                funcIn = r.front;
                                r.popFront;

                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, funcOut);");
                                DEBUG("writing out!");
                                writer.write(funcOut);
                            }
                            else static if(hasUDA!(val, ClientStreaming) && hasUDA!(val, ServerStreaming)) {
                                DEBUG("func call: bidi");

                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, writer);");
                            }
                            else static if(hasUDA!(val, ClientStreaming)) {
                                DEBUG("func call: client streaming");

                                DEBUG("calling..");
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(reader, funcOut);");

                                DEBUG("CLIENT STREAMING DONE");
                                writer.start();
                                writer.write(funcOut);
                            } 
                            else static if(hasUDA!(val, ServerStreaming)) {
                                DEBUG("func call: server streaming");
                                auto r = reader.read(1);
                                funcIn = r.front;
                                r.popFront;
                                DEBUG("OK!");

                                writer.start();
                                DEBUG("calling func..");
                                mixin("stat = instance." ~ __traits(identifier, val) ~ "(funcIn, writer);");
                            }

                            import grpc.common.batchcall;

                            DEBUG("done with func.. RecvClose");
/*
                            BatchCall batch = new BatchCall(data);
                            int cancelled = 0;
                            batch.addOp(new RecvCloseOnServerOp(&cancelled));
                            auto _s = batch.run(_tag, 1.msecs);
                            */


                            DEBUG("func call: writing");
                            writer.finish(stat);
                            DEBUG("func call: done");

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
                    _tagTable ~= rpcTag;
                }

                methodNames ~= remoteName;

                auto callMeta = callData[remoteName];
                callMeta.requestCall(registeredMethods[remoteName], _tagTable[$ - 1], _server);

            }();
        }
        return true;
    }

    this(ulong serviceId, CompletionQueue!"Next" cq, void*[string] methodTable) {

        _serviceInstance = new T();

        registeredMethods = methodTable.dup;
        _serviceId = serviceId;

        globalCq = cq;

        foreach(method; methodTable.keys) {
            auto _cq = new CompletionQueue!"Pluck"();
            callData[method] = new RemoteCall(cq, _cq);
        }

        with(funcType) { 
            _funcCount[NORMAL] = 0;
            _funcCount[STREAM_CLIENT] = 0;
            _funcCount[STREAM_SERVER] = 0;
            _funcCount[STREAM_CLIENT_SERVER] = 0;
        }

//        mainThread = new ServicerThread();
//        mainThread.isDaemon = true;
//        mainThread.start();
    }
        
}
    
