module grpc.core.mutex;
import interop.headers;
import grpc.core.resource;
import grpc.core.utils;
import core.memory : GC;
import std.experimental.allocator : theAllocator, make, dispose;
import core.sync.mutex;

alias GPRMutex = Mutex;
