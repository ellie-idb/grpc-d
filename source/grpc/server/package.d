module grpc.server;
import interop.headers;
import grpc.core.mutex;
import grpc.core.resource;
import grpc.core.tag;
import grpc.core;
import grpc.common.call;
import grpc.common.cq;
import grpc.service;
import grpc.logger;
import google.rpc.status;
import core.thread;

struct Server 
{
    private {
        GPRMutex mutex;
        SharedResource _server;
        ServiceHandlerInterface[string] services;
        bool started;
        bool shutdownPath;
    }
    
    @property inout(grpc_server)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _server.handle;
    }
    
    void lock() {
        mutex.lock;
    }
    
    void unlock() {
        mutex.unlock;
    }

    CompletionQueue!"Next" masterQueue;
    /* 
       Thread which runs the main loop
    */

    bool _run;
    bool collecting;

    // Fires 

    bool bind(string host, ushort port) {
        import std.format;
        import std.string : toStringz;
        string fmt = format!"%s:%d"(host, port);
        
        lock;
        scope(exit) unlock;

        auto status = grpc_server_add_insecure_http2_port(handle, fmt.toStringz);
        if(status == port) {
            INFO!"server binded to %s"(fmt);
            return true;
        } 

        return false;
    }

    void registerQueue(ref CompletionQueue!"Next" queue) {
        auto ptr = queue.ptr();
        lock;
        scope(exit) unlock;
        grpc_server_register_completion_queue(handle, ptr, null); 
    }

    void wait() {
        while(_run) {
            auto item = masterQueue.next(10.seconds);
            if(item.type == GRPC_OP_COMPLETE) {
                DEBUG!"MAIN QUEUE: New event"();
                Tag* tag = cast(Tag*)item.tag;
                //DEBUG!"item.tag: %x"(item.tag);
                
                if (shutdownPath) {
                    DEBUG!"in shutdown path, not adding to queue";
                    continue;
                }

                if (tag == null) {
                    continue;
                }

                if (tag.metadata[0] != 0xDE) {
                    continue;
                }

                if (tag.metadata[2] >= services.keys.length) {
                    continue;
                }
                
                //DEBUG!"tag.metadata: %s"(tag.metadata);
                //DEBUG!"services: %d"(srv.services.keys.length);
                //DEBUG!"Adding to service queue %s"(srv.services.keys[tag.metadata[2]]);
                services[services.keys[tag.metadata[2]]].addToQueue(tag);
                DEBUG!"placed onto queue";
            }
            else if(item.type == GRPC_QUEUE_TIMEOUT) {
                foreach(service; services) {
                    if (service.runners() == 0) {
                        ERROR!"service crashed?";
                    }
                }
            }
            else if(item.type == GRPC_QUEUE_SHUTDOWN) {
                _run = false;
            }
        }
        
        shutdown();
    }
    
    void shutdown() @trusted {
        DEBUG!"stopping all services";
        shutdownPath = true;
        foreach(service; services) {
            service.stop();
        }
        grpc_server_shutdown_and_notify(handle, masterQueue.handle, null);
    }

    void registerService(T)() {
        assert(!started, "Cannot register a new service after Server.start() has been called.");
        import std.typecons;
        import std.traits;

        void* registerMethod(const(char*) remoteName, const(char*) host, grpc_server_register_method_payload_handling payload_handle, uint flags) 
        {
            import std.string;
            void* ptr;
            lock;
            ptr = grpc_server_register_method(handle, remoteName, null, payload_handle, flags);
            unlock;
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
        lock;
        scope(exit) unlock;
        grpc_server_start(handle);
        started = true;
    }

    void run() {
        foreach(service; services.keys) {
            services[service].register(&this);
        }
    }
    
    package static Server opCall(grpc_channel_args args) @trusted {
        Server obj;
        grpc_server* srv = grpc_server_create(&args, null);
        if (srv != null) {
            obj.masterQueue = CompletionQueue!"Next"();
            
            static Exception release(shared(void)* ptr) @trusted nothrow {
                grpc_server_destroy(cast(grpc_server*)ptr);
                return null;
            }
            obj._run = true;
            obj._server = SharedResource(cast(shared)srv, &release);
            obj.mutex = GPRMutex();
            obj.registerQueue(obj.masterQueue);
        } else {
            throw new Exception("server creation failed");
        }
        
        return obj;
    }
        
    @disable this(this);
}
