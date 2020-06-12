module grpc.common.metadata;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import fearless;
import automem;
import grpc.core.mutex;
import grpc.core.resource;

@nogc: 
struct MetadataArrayWrapper {
    alias metadata this;
    grpc_metadata_array metadata;
} 

struct MetadataWrapper {
    alias metadata this;
    grpc_metadata metadata;
}

/*
    INFO: This ARRAY SHOULD *NEVER* be shared across threads.
    It is not thread-safe.
*/
struct MetadataArray {
    private {
        GPRMutex mutex;
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

    static MetadataArray opCall() @trusted {
        MetadataArray obj;
        
        static Exception release(shared(void)* ptr) @trusted nothrow {
            grpc_metadata_array_destroy(cast(grpc_metadata_array*)ptr);
            gpr_free(cast(void*)ptr);

            return null;
        }
        grpc_metadata_array* mt = cast(grpc_metadata_array*)gpr_zalloc((grpc_metadata_array).sizeof);
        if(mt != null) {
            grpc_metadata_array_init(mt);
            obj._metadata = SharedResource(cast(shared)mt, &release);
            obj.mutex = GPRMutex();
        } else {
            throw new Exception("malloc error");
        }
        return obj;
    }
    
    @disable this(this);
}

