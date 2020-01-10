module grpc.core;
import std.string : fromStringz;
import interop.headers;
public import grpc.core.core;

template assertNotReady() {
    bool assertNotReady = () { assert(grpcReady(), "Assertion: gRPC has not been initialized"); return true; }();
}
    

bool grpcReady() {
    if(grpc_is_initialized() == true) {
        return true;
    }

    return false;
}

void init() {
	grpc_init();
	assert(grpc_is_initialized(), "failed to intiialize gRPC");
}

void shutdown() {
	grpc_shutdown();
}

string g_stands_for() {
	auto g = grpc_g_stands_for();
	return g.fromStringz.dup;
}

string version_string() {
	auto g = grpc_version_string();
	return g.fromStringz.dup;
}


