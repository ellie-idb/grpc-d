module grpc.core.core;
import grpc.core;
import core.sys.posix.signal;
import core.thread.osthread;
import core.runtime : Runtime;
import core.memory : GC;

@nogc: 
class GRPCModule {
    import std.stdio;
    shared static this() {
//        thread_term();
//        thread_setGCSignals(SIGRTMIN, SIGRTMIN + 2);
//        thread_init();
        grpc.core.init();
        debug writeln("gRPC " ~ grpc.core.version_string() ~ " started");
        __grpcmodule = new GRPCModule(); 
    }

    shared static ~this() {
        debug writeln("gRPC " ~ grpc.core.version_string() ~ " shutting down");
        grpc.core.shutdown();
    }
}

__gshared GRPCModule __grpcmodule;
    
