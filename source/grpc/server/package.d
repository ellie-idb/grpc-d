module grpc.server;
import grpc.logger;
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

struct ServerPtr {
    grpc_server* server;
    alias server this;
}

import std.container.dlist;

class Server 
{
    private {
        Exclusive!ServerPtr* server_;

        CompletionQueue!"Next" masterQueue;

        ServiceHandlerInterface[string] services;

        bool started;
    }

    /* 
       Thread which runs the main loop
    */

    __gshared bool run_;

    // Fires 

    class NotificationThread : Thread {
        this() {
            super(&run);
        }
    private:
        void run() {
            int count = 0;
            while(run_) {
                auto item = masterQueue.next(10.seconds);
                if(item.type == GRPC_OP_COMPLETE) {
                    DEBUG("MAIN QUEUE: New event");
                    Tag tag = *cast(Tag*)item.tag;

                    services[services.keys[tag.metadata[2]]].addToQueue(tag);
                }
                else if(item.type == GRPC_QUEUE_SHUTDOWN) {
                    run_ = false;
                }
            }
        }
    }

    NotificationThread notifier;

    bool bind(string host, ushort port) {
        import std.format;
        import std.string : toStringz;
        string fmt = format!"%s:%d"(host, port);

        auto server = server_.lock();

        auto status = grpc_server_add_insecure_http2_port(server.server, fmt.toStringz);
        if(status == port) {
            INFO("server binded to ", fmt);
            return true;
        } 

        return false;
    }

    void registerQueue(CompletionQueue!"Next" queue) {
        auto ptr = queue.ptr();

        auto server = server_.lock();
        grpc_server_register_completion_queue(server.server, ptr.cq, null); 
    }

    void wait() {
        while(run_) {
            Thread.sleep(1.msecs);
        }

        foreach(service; services.keys) {
            services[service].stop();
        }
    }

    void registerService(T)() {
        assert(!started, "Cannot register a new service after Server.start() has been called.");
        import std.typecons;
        import std.traits;

        void* registerMethod(const(char*) remoteName, const(char*) host, grpc_server_register_method_payload_handling payload_handle, uint flags) 
        {
            import std.string;
            void* ptr;
            auto server = server_.lock();
            ptr = grpc_server_register_method(server.server, remoteName, null, payload_handle, flags);

            return ptr;
        }

        alias parent = BaseTypeTuple!T[1];
        alias serviceName = fullyQualifiedName!T;
        void*[string] registeredMethods;
        pragma(msg, "gRPC (" ~ fullyQualifiedName!T ~ ")");
        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {
            () {
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

                    registeredMethods[remoteName] = registerMethod(remoteName, "", GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER, 0);
            }();
        }

        Service!T _s = new Service!T(services.keys.length, masterQueue, registeredMethods);
        services[serviceName] = _s;
    }

    void finish() {
        auto server = server_.lock(); 
        grpc_server_start(server.server);
        started = true;
    }

    void run() {
        foreach(service; services.keys) {
            services[service].register(server_);
        }

        notifier = new NotificationThread();
        notifier.isDaemon = true;
        notifier.start();

    }

    package this(grpc_channel_args args) {
        mixin assertNotReady;

        import std.concurrency;
        run_ = true;

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
