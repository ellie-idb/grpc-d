module grpc.core.core;
import grpc.core;
import grpc.logger;

class GRPCModule {

    this() {

    }

    ~this() {

    }

    import std.stdio;
    shared static this() {
        grpc.core.init();

        INFO("gRPC " ~ grpc.core.version_string() ~ " started");
        __grpcmodule = new GRPCModule(); 
    }

    shared static ~this() {
        debug writeln("gRPC " ~ grpc.core.version_string() ~ " shutting down");
        grpc.core.shutdown();
    }
}

__gshared GRPCModule __grpcmodule;
    
