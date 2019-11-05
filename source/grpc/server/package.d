module grpc.server;
import grpc.core.grpc_preproc;
import grpc.core.cq;
import core.thread;
import google.rpc.status;
import std.stdio;
import grpc.core.tag;
import std.concurrency;
import std.parallelism;
import std.signals;
import fearless;

struct ServerPtr {
    grpc_server* server;
}

class Server 
{
    class NotificationThread : Thread {
        bool run_ = true;
        this() {
            super(&run);
        }

        mixin Signal!(Tag);
    private:
        void run() {
            
            while(run_) { 
                auto item = masterQueue.next(1.msecs);
                if(item.type == GRPC_OP_COMPLETE) {
                    writeln("NEXT: ", item.tag);
                    Tag tag = *cast(Tag*)item.tag;
                    emit(tag);
                }
            }
        }
    }

    interface ServerThreadInterface {
        void watch(Tag received);
    }

    class ServerThread(T) : Thread, ServerThreadInterface {
        import std.typecons;
        import std.traits;

        bool run_ = true;
        ulong threadIndex;
        this() {
            serverInstance_ = new T();

            super(&run);
        }

        void watch(Tag received) {
            if(received.metadata[0] == 0xDE) {
                if(received.metadata[2] == cast(ubyte)threadIndex) {
                    newTag = true;
                    newTag_index = cast(ulong)received.metadata[1];
                }
            }
        }
        
    private:
        static Status function(T, ubyte[], ref ubyte[])[string] _arr; //table holds all of the lambdas created from CTFE earlier
        static void*[string] registeredMethods; //pointers from grpc_server_register_method
        static Tag[] tagTable;

        __gshared bool newTag;
        __gshared ulong newTag_index;

        bool initDone;

        T serverInstance_;
        void run() {
            grpc_init();
            CompletionQueue!"Pluck" cq = new CompletionQueue!"Pluck"();

            registerAll();

            grpc_call_details _details;
            grpc_metadata_array _metadata;
            grpc_call* _call;
            grpc_byte_buffer* bytebuffer;
            gpr_timespec time;

            grpc_metadata_array_init(&_metadata);
            grpc_call_details_init(&_details);


            /* 
               Wait for grpc_server_start to be called..
            */

            while(!started) {
                Thread.sleep(1.msecs);
            }

            /*
               CTFE
            */
            alias parent = BaseTypeTuple!T[1];
            static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
                /*
                   The remote name (what is sent over the wire) is encoded
                   into the function with the help of the @RPC UDA.
                   This is part of the protobuf compiler, and gRPCD does
                   not require an additional pass with a gRPC compiler, as
                   UDAs eliminate the need for a second pass.
                */

                enum remoteName = getUDAs!(val, RPC)[0].methodName;

                debug writeln("REGISTER: " ~ remoteName);
                if(remoteName !in registeredMethods) {
                    assert(0, "Expected the method to be present in the registered table..");
                }

                /* 
                   Create a unique tag for each call, and preserve it, as it contains
                   valuable metadata that we refer to when the main notification thread emits
                   a tag corresponding to a function call.
                */

                Tag rpcTag = new Tag();
                rpcTag.metadata[0] = 0xDE;
                rpcTag.metadata[1] = cast(ubyte)i;
                rpcTag.metadata[2] = cast(ubyte)threadIndex;
                tagTable ~= rpcTag;

                /*
                   Register the call to the server.
                */
                requestRegisteredCall(registeredMethods[remoteName],
                        &_call, &time, &_metadata,
                        &bytebuffer, cq, masterQueue,  
                        rpcTag);

            }

            /*
               We want to register all of our services (theoretically) before the main completion queue
               has a chance to enter it's loop.
            */

            servicesDoneRegistering++;

            while(run_) {
                /* 
                   newTag is a shared variable that is set when the main NotificationThread emits a new tag,
                   that is for us. We check in the watch() function that the thread ID encoded in the tag
                   is equal to our thread ID
                */
                if(newTag) {

                    newTag = false;

                    debug writeln("New tag: ", newTag_index);
                    if(newTag_index > _arr.keys.length) {
                        writeln("Invalid..");
                        continue;
                    }
                    import std.string : fromStringz;

                    /*
                       Since the tag is for us, then that must mean
                       that the byte buffer is full of data transmitted
                       over the wire. Read it, and convert it to a ubyte[] array here
                       so we can parse it as a protobuf.
                    */

                    grpc_byte_buffer_reader reader;
                    grpc_byte_buffer_reader_init(&reader, bytebuffer);
                    grpc_slice slices = grpc_byte_buffer_reader_readall(&reader);
                    ubyte[] msgIn = cast(ubyte[])grpc_slice_to_c_string(slices).fromStringz;
                    ubyte[] protoOut;

                    /* 
                       We generated this array full of lambdas which would decode the message,
                       then encode the message, provided ubyte[] arrays.
                    */
                    Status userCall;
                    try {
                        userCall = _arr[_arr.keys[newTag_index]](serverInstance_, msgIn, protoOut); 
                    } catch(Exception e) {
                        userCall.code = GRPC_STATUS_INTERNAL;
                        userCall.message = "Exception: " ~ e.msg;
                    }


                    /*
                       Re-register this call, so we get future notifications if it is
                       present.
                    */

                    requestRegisteredCall(registeredMethods[_arr.keys[newTag_index]],
                        &_call, &time, &_metadata,
                        &bytebuffer, cq, masterQueue,  
                        rpcTag);

                    /*
                       Free the allocated memory that the reader has alloc'd
                    */

                    grpc_byte_buffer_reader_destroy(&reader);


                    /*
                       Close the receive side on the server
                       Stage 1 of sending back a reply.
                    */

                    grpc_op[] op_1;
                    {
                        int closed;
                        grpc_op op;
                        op.op = GRPC_OP_RECV_CLOSE_ON_SERVER;
                        op.data.recv_close_on_server.cancelled = &closed;
                        op_1 ~= op;
                        auto status = grpc_call_start_batch(_call, op_1.ptr, op_1.length, &rpcTag, null);
                        if(status == GRPC_CALL_OK) {
                            cq.next(rpcTag, 1.msecs);
                            writeln("OK");
                        } 

                        if(closed) {
                            continue;
                        }
                    }
                    
                    /*
                       We send the full message here,
                       and the status from the function call.
                    */

                    grpc_op[3] op_2;
                    {
                        op_2[0].op = GRPC_OP_SEND_INITIAL_METADATA;
//                                op_2[2].flags = 0x00000002u;

                        op_2[1].op = GRPC_OP_SEND_MESSAGE;
                        grpc_slice msg = grpc_slice_ref(grpc_slice_from_copied_buffer(cast(const(char*))protoOut, protoOut.length));
                        grpc_byte_buffer* bytebuf = grpc_raw_byte_buffer_create(&msg, 1);
                        op_2[1].data.send_message.send_message = bytebuf;


                        op_2[2].op = GRPC_OP_SEND_STATUS_FROM_SERVER;
                        grpc_slice statusDetails;
                        if(userCall.code != 0) {
                            op_2[2].data.send_status_from_server.status = cast(grpc_status_code)userCall.code;
                            if(userCall.message != "") {
                                import std.string : toStringz;
                                statusDetails = grpc_slice_ref(grpc_slice_from_copied_buffer(userCall.message.toStringz, userCall.message.length));
                                op_2[2].data.send_status_from_server.status_details = &statusDetails;
                            }
                        }
                        else {
                            op_2[2].data.send_status_from_server.status = GRPC_STATUS_OK;
                        }
                        int tag = 1;

                        auto status = grpc_call_start_batch(_call, op_2.ptr, op_2.length, &rpcTag, null);
                        if(status == GRPC_CALL_OK) {
                            cq.next(rpcTag, 1.msecs);
                        }

                        grpc_slice_unref(msg);

                        if(userCall.code != 0) {
                            if(userCall.message != "") {
                                grpc_slice_unref(statusDetails);
                            }
                        }
                    }
                }
                Thread.sleep(1.msecs);
            }
        }

        void registerAll() {
            assert(!initDone, "registerAll() can only be called once.");

            initDone = true;

            alias parent = BaseTypeTuple!T[1];
            pragma(msg, "gRPC (" ~ fullyQualifiedName!T ~ ")");
            static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
                enum remoteName = getUDAs!(val, RPC)[0].methodName;
                import std.conv : to;
                pragma(msg, "RPC (" ~ to!string(i) ~ "): " ~ fullyQualifiedName!(val));
                pragma(msg, "\tRemote: " ~ remoteName);

                mixin("import " ~ moduleName!val ~ ";");
                _arr[remoteName] = (T obj, ubyte[] _in, ref ubyte[] _out) {
                    Status stat;

                    import google.protobuf;

                    Parameters!val[0] funcIn = _in.fromProtobuf!(Parameters!val[0]);
                    Parameters!val[1] funcOut;
                    import std.array;


                    mixin("stat = obj." ~ __traits(identifier, val) ~ "(funcIn, funcOut);");

                    _out = funcOut.toProtobuf.array;

                    return stat;
                };

                registeredMethods[remoteName] = registerMethod(remoteName, "", GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER, 0);
            }

            servicesDoneStage1++;

        }

    }

    private {
        Exclusive!ServerPtr* server_;
        __gshared CompletionQueue!"Next" masterQueue;
        Thread[] services;
        __gshared int servicesDoneRegistering;
        __gshared int servicesDoneStage1;

        __gshared bool started;
        TaskPool _runners;

    }

    grpc_call_error requestRegisteredCall(void* registeredMethod, grpc_call** call,
            gpr_timespec* time, grpc_metadata_array* metadata,
            grpc_byte_buffer** bytebuffer, CompletionQueue!"Pluck" _method,
            CompletionQueue!"Next" notification, ref Tag tag) 
    {
        assert(started, "call requestRegisteredCall after started a server..");
        auto server_ptr = server_.lock();
        debug writeln("Acquired lock on server");
        auto method_cq = _method.ptr();
        debug writeln("Acquired lock on 1/2 completion queues");
        auto notification_cq = notification.ptr();
        debug writeln("Acquired lock on 2/2 completion queues");

        return grpc_server_request_registered_call(server_ptr.server, 
                registeredMethod, call, time, metadata,
                bytebuffer, method_cq.cq,
                notification_cq.cq, &tag); 
    }

    bool bind(string host, ushort port) {
        import std.format;
        import std.string : toStringz;
        string fmt = format!"%s:%d"(host, port);

        auto server = server_.lock();

        auto status = grpc_server_add_insecure_http2_port(server.server, fmt.toStringz);
        if(status == port) {
            return true;
        } 

        return false;
    }

    void* registerMethod(const(char*) remoteName, const(char*) host, grpc_server_register_method_payload_handling payload_handle, uint flags) 
    {
        import std.string;
        void* ptr;
        auto server = server_.lock();
        ptr = grpc_server_register_method(server.server, remoteName, null, payload_handle, flags);

        return ptr;
    }

    void registerQueue(CompletionQueue!"Next" queue) {
        auto ptr = queue.ptr();

        auto server = server_.lock();
        grpc_server_register_completion_queue(server.server, ptr.cq, null); 
    }

    void wait() {
        foreach(thread; services) {
            thread.join(true);
        }
    }

    void registerService(T)() {
        assert(!started, "Cannot register a new service after Server.start() has been called.");

        auto service = new ServerThread!T();
        service.threadIndex = services.length;
        service.isDaemon = true;
        service.start();

        services ~= service;
    }

    void finish() {
        while(servicesDoneStage1 != services.length) {
            Thread.sleep(1.msecs);
        }

        auto server = server_.lock(); 
        grpc_server_start(server.server);
        started = true;
    }


    void run() {
        while(servicesDoneRegistering != services.length) {
            Thread.sleep(1.msecs);
        }

        NotificationThread notificationService = new NotificationThread();
        notificationService.isDaemon = true;
        notificationService.start();

        foreach(service; services) {
            ServerThreadInterface s = cast(ServerThreadInterface)service;
            notificationService.connect(&s.watch);
        }

        services ~= notificationService;
    }

    package this(grpc_channel_args args) {
        masterQueue = new CompletionQueue!"Next"();

        grpc_server* ptr = grpc_server_create(&args, null);
        server_ = new Exclusive!ServerPtr(ptr);

        registerQueue(masterQueue);
    }

    @disable public this() {

    }

    ~this() {
    }

}
