module grpc.common.metadata;
import interop.headers;
import grpc.logger;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.mutex;
import grpc.core.resource;

/*
    INFO: This ARRAY SHOULD *NEVER* be shared across threads.
    It is not thread-safe.
*/
class MetadataArray {
    private {
        shared GPRMutex mutex;
        SharedResource _metadata;
    }
    
    @property inout(grpc_metadata_array)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _metadata.handle;
    }
    
    @property inout(grpc_metadata)* data() inout @trusted pure nothrow {
        return cast(typeof(return)) handle.metadata;
    }

    @property ulong capacity() {
        mutex.lock;
        scope(exit) mutex.unlock;
        return handle.capacity;
    }

    @property ulong count() {
        mutex.lock;
        scope(exit) mutex.unlock;
        return handle.count;
    }

    grpc_metadata* opIndex(size_t i1) {
        mutex.lock;
        scope(exit) mutex.unlock;
        if(i1 > count) 
        {
            import core.exception;
            throw new RangeError();
        }

        return &handle.metadata[i1];
    }

    this() {
        static Exception release(shared(void)* ptr) @trusted nothrow {
            import std.stdio;
            grpc_metadata_array* array = cast(grpc_metadata_array*)ptr;
            for(int i = 0; i < array.count; i++) {
                grpc_slice_unref(array.metadata[i].value);
            }
            grpc_metadata_array_destroy(array);
            gpr_free(cast(void*)ptr);

            return null;
        }
        grpc_metadata_array* mt = cast(grpc_metadata_array*)gpr_zalloc((grpc_metadata_array).sizeof);
        if(mt != null) {
            grpc_metadata_array_init(mt);
            _metadata = SharedResource(cast(shared)mt, &release);
            mutex = GPRMutex();
        } else {
            throw new Exception("malloc error");
        }
    }


    static MetadataArray opCall() @trusted {
        MetadataArray obj = new MetadataArray();
        return obj;
    }
}

