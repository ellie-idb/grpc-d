module grpc.core.core;
import grpc.core;

class GRPCModule {

    this() {

    }

    ~this() {

    }

    import std.stdio;
    shared static this() {
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
    
