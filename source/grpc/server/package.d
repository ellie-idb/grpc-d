module grpc.server;
import interop.headers;
import grpc.core.sync.mutex;
import grpc.core.resource;
import grpc.core.tag;
import grpc.core;
import grpc.common.call;
import grpc.common.cq;
import grpc.service;
import grpc.logger;
import google.rpc.status;
import core.thread;
import core.lifetime;

class Server 
{
    private {
        shared(Mutex) mutex;
        SharedResource _server;
        shared(CompletionQueue!"Next")[] _registeredCqs;
        ServiceHandlerInterface[string] services;
        bool started;
        shared bool _run;

        void handleShutdown() {
            grpc_server_cancel_all_calls(handle);
            foreach(cq; _registeredCqs) {
                cq.lock();
                cq.inShutdownPath(true);
                cq.unlock();

                grpc_server_shutdown_and_notify(handle, cq.handle, null);
            }
        }
    }
    
    inout(grpc_server)* handle() inout @trusted nothrow shared {
        return cast(typeof(return)) _server.handle;
    }

    inout(grpc_server)* handle() inout @trusted nothrow {
        return cast(typeof(return)) _server.handle;
    }

    void lock() shared {
        mutex.lock;
    }

    void lock()  {
        mutex.lock;
    }
    
    void unlock() shared {
        mutex.unlock;
    }

    void unlock()  {
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

    void registerQueue(shared(CompletionQueue!"Next") queue) shared {
        lock;
        scope(exit) unlock;
        _registeredCqs ~= queue;
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

        handleShutdown();
    }

    // this is expected to be called from an ISR (interrupt service routine, Ctrl+C whatever)
    
    void shutdown() @trusted @nogc nothrow {
        try { 
            atomicStore(_run, false);
        } catch(Exception e) {
            // basically, unless the world burns down this shouldn't *ever* throw
        }
    }

    void* registerMethod(const(char)[] remoteName, const(char)[] host, grpc_server_register_method_payload_handling payload_handle, uint flags) 
    {
        import std.string : toStringz;
        debug import std.stdio;
        debug writefln("hello");
        DEBUG!"lock";
        lock;
        scope(exit) unlock;
        DEBUG!"register method %s"(remoteName);
        void* ptr = grpc_server_register_method(handle, remoteName.toStringz, null, payload_handle, flags);
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
                    DEBUG!"register %s"(remoteName);
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
            static bool release(shared(void)* ptr) @trusted nothrow {
                grpc_server_destroy(cast(grpc_server*)ptr);
                return true;
            }

            _run = true;
            DEBUG!"creating server resource";
            _server = SharedResource(cast(shared)srv, &release);
            DEBUG!"creating mutex resource";
            mutex = cast(shared)Mutex.create();
            DEBUG!"done";
        } else {
            assert(0, "creation failed");
        }
    }

    ~this() {
        debug import std.stdio;
        debug writefln("running");
    }
}
