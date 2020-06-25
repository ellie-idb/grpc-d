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

class Server 
{
    private {
        GPRMutex mutex;
        SharedResource _server;
        ServiceHandlerInterface[string] services;
        bool started;
        bool shutdownPath;
        shared bool _run;
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
        lock;
        scope(exit) unlock;
        grpc_server_register_completion_queue(handle, queue.handle, null); 
    }

    import core.atomic;
    void wait() {
        foreach(service; services.keys) {
            services[service].kickstart();
        }

        while (atomicLoad(_run)) {
            foreach(service; services) {
                if (service.runners == 0) {
                    ERROR!"service is DEAD!";
                }
            }
            Thread.sleep(1.seconds);
        }

        foreach(service; services) {
            service.stop();
        }
    }

    // this is expected to be called from an ISR (interrupt service routine, Ctrl+C whatever)
    
    void shutdown() @trusted @nogc nothrow {
        try { 
            atomicStore(_run, false);
        } catch(Exception e) {
            // basically, unless the world burns down this shouldn't *ever* throw
        }
    }

    void* registerMethod(const(char*) remoteName, const(char*) host, grpc_server_register_method_payload_handling payload_handle, uint flags) 
    {
        lock;
        scope(exit) unlock;
        void* ptr = grpc_server_register_method(handle, remoteName, null, payload_handle, flags);
        return ptr;
    }


    void registerService(T)() {
        assert(!started, "Cannot register a new service after Server.start() has been called.");
        import std.typecons;
        import std.traits;


        alias parent = BaseTypeTuple!T[1];
        alias serviceName = fullyQualifiedName!T;
        void*[string] registeredMethods;
        pragma(msg, "gRPC (" ~ fullyQualifiedName!T ~ ")");
        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {{
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
                        pragma(msg, "\tClient -> Server");
                    }

                    registeredMethods[remoteName] = registerMethod(remoteName, "", GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER, 0);
            }
        }

        services[serviceName] = new Service!T(services.keys.length, registeredMethods);
    }

    void run() {
        foreach(service; services.keys) {
            services[service].register(this);
        }

        lock;
        scope(exit) unlock;

        INFO!"server is starting";
        grpc_server_start(handle);
        started = true;
    }

    this(grpc_channel_args args) @trusted {
        grpc_server* srv = grpc_server_create(&args, null);
        if (srv != null) {
            static Exception release(shared(void)* ptr) @trusted nothrow {
                grpc_server_destroy(cast(grpc_server*)ptr);
                return null;
            }

            _run = true;
            _server = SharedResource(cast(shared)srv, &release);
            mutex = theAllocator.make!GPRMutex();
        } else {
            throw new Exception("server creation failed");
        }
    }

    package static Server opCall(grpc_channel_args args) @trusted {
        Server obj = new Server(args);
        return obj;
    }
}
