module grpc.core;
import std.string : fromStringz;
import grpc.core.grpc_preproc;

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


