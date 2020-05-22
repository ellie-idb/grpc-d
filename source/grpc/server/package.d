module grpc.server;

import std.stdio;
import interop.headers;
import grpc.common.cq;
import grpc.core.tag;
import grpc.core;
import grpc.stream.server.reader;
import grpc.stream.server.writer;
import grpc.common.call;
import google.rpc.status;
import core.atomic;
import core.thread;
import fearless;
import grpc.service;
import grpc.logger;
import grpc.core.utils;
import grpc.core.gpr;

import grpc.core.resource;
class NotificationThread : Thread {
    this() {
        super(&run);
    }
    CompletionQueue!"Next" masterQueue;
    ServiceHandlerInterface[string] _services;
    

    __gshared bool run_ = true;
private:
    void run() {
//        grpc_postfork_child();

        int count = 0;
        while(run_) {
            DEBUG("pulling from queue");
            auto _item = masterQueue.next(10.seconds);
            auto item = _item.workForce();
            if(item.success == 0) {
                ERROR("item pulled was null?");
                continue;
            }

            INFO("pulled ", item.type);
            if(item.type == GRPC_OP_COMPLETE) {
                DEBUG("MAIN QUEUE: New event");
                Tag* tag = cast(Tag*)item.tag;

                DEBUG(tag.metadata);
                string svc = _services.keys[tag.metadata[1]];
                try { 
                    _services[svc].kick(tag);
                } catch(Exception e) {
                    DEBUG("unable to kick service");
                    return;
                }
                catch(Error e) {
                    DEBUG("unable to kick service");
                    return;
                }
            }
            else if(item.type == GRPC_QUEUE_SHUTDOWN) {
                run_ = false;
            }
        }
    }
}


struct Server 
{
@safe:
    private {
        SharedResource server_;
        CompletionQueue!"Callback" processQueue;
        CompletionQueue!"Next" masterQueue;

        ServiceHandlerInterface[string] services;
        bool s_initialized;
        bool s_started;
    }

    /* 
       Thread which runs the main loop
    */

    @property inout(grpc_server)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) server_.handle;
    }

    @property bool init() const pure nothrow { 
        return server_.handle != null;
    }

    @property bool started() const pure nothrow {
        return s_started;
    }


    NotificationThread notifier;

    bool bind(string host, ushort port) 
    in { assert(!s_started); assert(s_initialized); }
    do {
        import std.format;
        import std.string : toStringz;
        string fmt = format!"%s:%d"(host, port);

        if(auto status = unsafe!grpc_server_add_insecure_http2_port(this.handle, fmt.toStringz)) {
            if(status == port) {
                INFO("gRPC: server binded to ", fmt);
                return true;
            }
            else {
                throw new Exception("Could not bind");
            }
        }
        else {
            throw new Exception("Could not bind");
        }
    }

    void registerQueue(string target)(CompletionQueue!target queue) @trusted 
    in { assert(!s_started); assert(s_initialized); }
    do {
        auto ptr = queue.ptrNoMutex();

        grpc_server_register_completion_queue(this.handle, ptr, null); 
    }

    void wait() 
    in { assert(s_started); assert(s_initialized); }
    do {
        while(this.handle != null) {
            unsafe!(Thread.sleep)(1.msecs);
        }
    }

    void registerService(T)() 
    in { assert(!s_started); assert(s_initialized); }
    do {
        import std.typecons;
        import std.traits;

        void* registerMethod(const(char*) remoteName, const(char*) host, grpc_server_register_method_payload_handling payload_handle, uint flags) @trusted 
        {
            if(void* ptr = grpc_server_register_method(this.handle, remoteName, null, payload_handle, flags)) {
                DEBUG("Registered method");
                return ptr;
            }
            else {
                ERROR("Could not register method");
                throw new Exception("Could not register method");
            }
        }

        alias parent = BaseTypeTuple!T[1];
        alias serviceName = fullyQualifiedName!T;
        void*[string] registeredMethods;
        pragma(msg, "gRPC (" ~ fullyQualifiedName!T ~ ")");
        Service!T _s;

        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
            () @trusted {
                enum remoteName = getUDAs!(val, RPC)[0].methodName;
                import std.conv : to;
                pragma(msg, "RPC (" ~ to!string(i) ~ "): " ~ fullyQualifiedName!(val));
                pragma(msg, "\tRemote: " ~ remoteName);

                mixin("import " ~ moduleName!val ~ ";");

                static if(hasUDA!(val, ClientStreaming) && hasUDA!(val, ServerStreaming)) {
                    pragma(msg, "\tClient <- (stream) -> Server");

                }
                else static if(hasUDA!(val, ClientStreaming)) {
                    pragma(msg, "\tClient (stream) -> Server");
                }
                else static if(hasUDA!(val, ServerStreaming)) {
                    pragma(msg, "\tClient <- (stream) Server");
                }
                else {
                    pragma(msg, "\tClient <-> Server");
                }


                shared(void)* s_method = cast(shared(void)*)registerMethod(remoteName, "", GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER, 0);

                // ok to cast back, this array is only used once
                registeredMethods[remoteName] = cast(void*)s_method;

            }();


        }

 
        ulong id = () @trusted { string[] s = this.services.keys; return s.length; }();

        _s = new Service!T(id, masterQueue, registeredMethods);
        services[serviceName] = _s;
    }

    void finish() 
    in { assert(s_initialized); }
    do {
        this.bind("0.0.0.0", 50051);
        synchronized { 
            unsafe!grpc_server_start(this.handle);
        }

        DEBUG("server started");

        this.s_started = true;


        () @trusted { 
//            grpc_prefork();
            this.notifier._services = this.services;
            this.notifier.run_ = true;
            this.notifier.start();
        }();
    }

    void run() 
    in { assert(s_initialized); }
    do {
        string[] keys = () @trusted { return this.services.keys; }();
        foreach(service; keys) {
            services[service].register(this);
        }

    }

    static Server opCall(grpc_channel_args args) @trusted {
        if(grpc_server* ptr = grpc_server_create(null, null)) {

            Server srv;

            static Exception release(shared(void)* ptr) @trusted nothrow
            {
                grpc_server_destroy(cast(grpc_server*)ptr);
                return null;
            }

            srv.server_ = SharedResource(cast(shared)ptr, &release);
            srv.s_initialized = true;
//            srv.processQueue = new CompletionQueue!"Callback"();

//            srv.registerQueue!("Callback")(srv.processQueue);

            srv.notifier = new NotificationThread();
            srv.masterQueue = new CompletionQueue!"Next"();
            srv.registerQueue!("Next")(srv.masterQueue);
            srv.notifier.masterQueue = srv.masterQueue;
            srv.notifier.isDaemon = true;

            return srv;

        }
        else {
            throw new Exception("Server creation error");
        }
    }

    @disable this(this);

    ~this() {
    }

}
