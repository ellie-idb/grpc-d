module grpc.common.metadata;
import interop.headers;
import grpc.logger;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.sync.mutex;
import grpc.core.resource;
import interop.functors;
import automem;
import core.lifetime;

/*
    INFO: This ARRAY SHOULD *NEVER* be shared across threads.
    It is not thread-safe.
*/
struct MetadataArray {
@safe @nogc:
    private {
        shared(Mutex) mutex;
        SharedResource _meta;
    }
    
    inout(grpc_metadata_array)* handle() inout @trusted nothrow {
        return cast(typeof(return)) _meta.handle;
    }

    @property ulong capacity() {
        mutex.lock;
        scope(exit) mutex.unlock;
        
        return handle.capacity;
    }

    @property ulong count() {
        mutex.lock;
        scope(exit) mutex.unlock;
        
        grpc_metadata_array* arr = handle;
        
        ulong count = arr.count;
        return count;
    }

    grpc_metadata* opIndex(size_t i1) {
        mutex.lock;
        scope(exit) mutex.unlock;
        assert(i1 < count, "out of range");
        return () @trusted {
            return &handle.metadata[i1];
        } ();
    }

    void cleanup() {
        if (handle.metadata == null) return;

        () @trusted {
            assumeNoGC(&grpcwrap_metadata_array_destroy_metadata_only)(handle);
        } ();

        handle.metadata = null;
        handle.count = 0;
        handle.capacity = 0;
    }

    static MetadataArray create() @trusted {
        static bool release(shared(void)* ptr) @trusted nothrow {
            grpc_metadata_array* array = cast(grpc_metadata_array*)ptr;
            if (array.metadata) {
                for (int i = 0; i < array.count; i++) {
                    grpc_slice_unref(array.metadata[i].key);
                    grpc_slice_unref(array.metadata[i].value);
                }
                gpr_free(cast(void*)array.metadata);
                array.metadata = null;
            }
            gpr_free(cast(void*)ptr);
            return true;
        }

        grpc_metadata_array* mt = cast(grpc_metadata_array*)gpr_zalloc((grpc_metadata_array).sizeof);
        if(mt != null) {
            assumeNoGC(&grpcwrap_metadata_array_init)(mt, 1);
            return MetadataArray(cast(shared)Mutex.create(), SharedResource(cast(shared)mt, &release));
        }
        assert(0, "malloc error");
    }
    
    ~this() {
        _meta.forceRelease();
    }
}

