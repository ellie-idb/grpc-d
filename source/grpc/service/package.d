module grpc.service;
import core.thread;
import fearless;
import grpc.server;
import grpc.common.call;
import google.rpc.status;
import grpc.core.tag;
import grpc.common.cq;
import grpc.service.queue;
import grpc.logger;
import grpc.core.gpr;
import std.conv : to;

//should/can be overridden by clients
interface ServiceHandlerInterface {
@safe:
    bool register(ref Server);
    void addToQueue(ref Tag t);
    void stop();
    int totalQueued();
    bool kick(Tag*);
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

class ServicerThread(T) : Thread {
    this() {
        super(&run);
    }

    void*[string] registeredMethods;
    bool _run = true;
    T _serviceInstance;
    CompletionQueue!"Next"* _serviceCq;
    CompletionQueue!"Next"* _globalCq;

    Server* srv;
    void delegate(T, ref RemoteCall, ref Tag) @safe [string] handlers;
    __gshared Tag[] tagTable;

private:
    void run() {
        _serviceInstance = new T();
        import interop.headers;
        while(_run) {
            auto _item = _serviceCq.next(10.seconds);
            auto item = _item.workForce();
            
            if(item.type == GRPC_OP_COMPLETE) {
                DEBUG("Queue kicked");
                RemoteCall* call = cast(RemoteCall*)item.tag;
                DEBUG("Pulled ptr: ", item.tag);
                if(call is null) {
                    ERROR("service cq received an invalid call ptr");
                    return;
                }
                
                if(call.metadata is null) {
                    ERROR("metadata null, cannot proceed");
                    return;
                }

                DEBUG(call.metadata.count);
                auto arr = *call.metadata;

                for(int i = 0; i < arr.length; i++) {
                    try { 
                        DEBUG(arr[i].key, ": ", arr[i].value);
                    } catch(Exception e) {
                        ERROR("caught an exception: ", e.msg);
                        return;
                    } catch(Error e) {
                        ERROR("caught an error: ", e.msg);
                        return;
                    }
                }

                if(arr.length != 3) {
                    DEBUG("metadata was not to size");
                    return;
                }
                string sym = arr[1].value;
                size_t tag = to!size_t(arr[2].value);
                DEBUG("got call id: {'", arr[1].key, "': '", arr[1].value, "'}");
                DEBUG("got tag id: ", tag);


                try {
                    handlers[sym](_serviceInstance, *call, tagTable[tag]); 
                } catch(Exception e) {
                    ERROR("bleh");
                }

                RemoteCall* newCall = RemoteCall(*_globalCq, *_serviceCq);

                tagTable[tag].objectPtr = cast(void*)newCall;

                newCall.requestCall(registeredMethods[sym], tagTable[tag], *srv);


                DEBUG("call ptr: ", call);
                DEBUG("new call ptr: ", newCall);

            }
            else if(item.type == GRPC_QUEUE_SHUTDOWN) {
                DEBUG("Queue nogo");
                _run = false;
            }
            else {
                DEBUG("Service queue waiting for events");
            }
        }
    }
}


class Service(T) : ServiceHandlerInterface {
@safe:
    import std.typecons;
    import std.traits;

    private {
        Object queueLock = new Object;
        void*[string] registeredMethods;

        CompletionQueue!"Next" globalCq;
        CompletionQueue!"Next" serviceCq;

        int[funcType] _funcCount;

        string[] methodNames;

        shared(RemoteCall)*[string] callData;
        shared(Server)* server;
        __gshared Tag[] _tagTable;

        void delegate(T, ref RemoteCall, ref Tag)[string] _handlers;
        immutable ulong _serviceId;

        enum funcType {
            NORMAL,
            STREAM_CLIENT,
            STREAM_SERVER,
            STREAM_CLIENT_SERVER
        }

        ServicerThread!T _servicer;

    }

    int _totalServiced;
    int _totalQueued;


    /*

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
    */

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

    void addToQueue(ref Tag t) {
        if(t.metadata[0] != 0xDE) {
            return;
        }

    }

    bool kick(Tag* tag) @trusted 
    in {
        assert(tag != null);
    }
    do {
        if(!_servicer.isRunning()) {
            DEBUG("servicer thread crashed");
            _servicer.start();
        }

        string sym = callData.keys[tag.metadata[2]];
        RemoteCall* call = cast(RemoteCall*)tag.objectPtr;
        try { 
            call.metadata.add("call-id", sym);
            call.metadata.add("tag-id", to!string(tag.metadata[2])); 
        } catch(Exception e) {
            ERROR("got an exception: ", e.msg);
            return false;
        } catch(Error e) {
            ERROR("got an error: ", e.msg);
            return false;
        }

        DEBUG("kicking");

        if(call.kick()) {
            DEBUG("kicked");
        } else {
            DEBUG("failed to kick");
        }

        return true;
    }


    bool register(ref Server srv) {
        alias parent = BaseTypeTuple!T[1];

        () @trusted {
            server = cast(shared(Server)*)&srv;
        }();

        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
            () @trusted {

                enum remoteName = getUDAs!(val, RPC)[0].methodName;

                import interop.headers;

                auto callMeta = cast(RemoteCall*)callData[remoteName];
                _tagTable.length++;
                _tagTable[i].metadata[0] = cast(ubyte)0xFF;
                _tagTable[i].metadata[1] = cast(ubyte)_serviceId;
                _tagTable[i].metadata[2] = cast(ubyte)i;
                _tagTable[i].objectPtr = cast(void*)callMeta;
                import grpc.stream.server.reader;
                import grpc.stream.server.writer;

                import std.traits;
                import std.meta;

                mixin Reader!(Parameters!val[0]);

                mixin Writer!(Parameters!val[1]);


                _handlers[remoteName] = (T instance, ref RemoteCall data, ref Tag _tag) @trusted {
                        Status stat;
                        DEBUG("func body: ", remoteName);
                        

                        ServerReader!(input) reader = new ServerReader!(input)(data, _tag);
                        ServerWriter!(output) writer = new ServerWriter!(output)(data, _tag);

                        input funcIn;
                        output funcOut;
                        DEBUG("func call: ", remoteName);
                        static if(hasUDA!(val, ClientStreaming) == 0 && hasUDA!(val, ServerStreaming) == 0) {
                            DEBUG("func call: regular");
                            writer.start();

                            DEBUG("started read");

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


                if(grpc_call_error error = callMeta.requestCall(registeredMethods[remoteName], _tagTable[i], srv)) {
                    ERROR("got call error ", error);
                }
                else {
                    INFO("Registered fine");
                }


            }();
        }
        () @trusted { 
           // grpc_prefork();
            _servicer.tagTable = _tagTable;
            _servicer.handlers = _handlers;
            _servicer.registeredMethods = registeredMethods;
            _servicer.srv = &srv;
            _servicer.start();
        }();

        
        return true;
    }


    // this function will always be called by main()
/++
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
++/

    this(ulong serviceId, ref CompletionQueue!"Next" cq, void*[string] methodTable) @trusted {

        registeredMethods = methodTable.dup;
        _serviceId = serviceId;

        _servicer = new ServicerThread!T();
        _servicer.isDaemon = true;

        serviceCq = new CompletionQueue!"Next"();
        _servicer._serviceCq = &serviceCq;
        _servicer._globalCq = &cq; 

        foreach(method; methodTable.keys) {
            import core.atomic;
            auto _callData = cast(RemoteCall*[string])callData; 
            _callData[method] = RemoteCall(cq, serviceCq);

            callData = cast(shared(RemoteCall)*[string])_callData;
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
    
