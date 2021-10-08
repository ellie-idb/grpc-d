module grpc.common.byte_buffer;
import grpc.logger;
import interop.headers;
import grpc.core.resource;
import grpc.core.sync.mutex;
import core.lifetime;

struct ByteBuffer {
@nogc:
    private {
        shared(Mutex) mutex;
        SharedResource buf;
        grpc_byte_buffer_reader reader;

        static bool release(shared(void)* ptr) @trusted nothrow {
            grpc_byte_buffer** v = cast(grpc_byte_buffer**)ptr;
            if (v != null) {
                if (*v != null) {
                    grpc_byte_buffer_destroy(*v);
                }
                gpr_free(cast(void*)v);
                v = null;
            }
            return true;
        }
    }

    inout(grpc_byte_buffer)** safeHandle() inout @trusted nothrow {
        return cast(typeof(return)) buf.handle;
    }
    
    inout(grpc_byte_buffer)* handle() inout @trusted nothrow {
        return cast(typeof(return)) *safeHandle;
    }
    
    bool valid() {
        return handle != null;
    }

    bool compressed() {
        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");
        
        return handle.type == GRPC_BB_RAW;
    }

    ulong length() {
        lock;
        scope(exit) unlock;
        
        if (!valid) {
            return 0;
        } else {
            return grpc_byte_buffer_length(handle);
        }
    }
    
    void lock() {
        DEBUG!"bf lock";
        mutex.lock;
    }
    
    void unlock() {
        DEBUG!"bf unlock";
        mutex.unlock;
    }

    auto readAll() {
        import grpc.core.utils;
        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");

        return byte_buffer_to_type!(ubyte[])(handle);
    }

    ubyte[] read() {
        import grpc.core.utils;

        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");
        
        if(reader == grpc_byte_buffer_reader.init) {
            grpc_byte_buffer_reader_init(&reader, handle);
        }

        grpc_slice slice;
        reader.current.index = 0;
        if(grpc_byte_buffer_reader_next(&reader, &slice) == 0) {
            grpc_byte_buffer_reader_destroy(&reader);
            reader = reader.init;
        }
        
        return slice_to_type!(ubyte[])(slice);
    }


    static ByteBuffer copy(ByteBuffer obj) {
        obj.lock;
        scope(exit) obj.unlock;

        assert(obj.valid, "byte buffer was not valid");
        auto buf_2 = grpc_byte_buffer_copy(obj.handle);
        ByteBuffer ret = ByteBuffer.create();
        *(ret.safeHandle) = buf_2;
        return ret;
    }
    
    void cleanup() {
        lock;
        scope(exit) unlock;
        assert(valid, "byte buffer must be valid to clean");
        grpc_byte_buffer_destroy(handle);
        *(safeHandle) = null;
        assert(!valid, "byte buffer must be invalid now");
    }

    static ByteBuffer create() @trusted {
        grpc_byte_buffer** res = cast(grpc_byte_buffer**)gpr_zalloc((void*).sizeof);
        return ByteBuffer(cast(shared)Mutex.create(), SharedResource(cast(shared)res, &release));
    }


    static ByteBuffer create(ref ubyte[] _data) @trusted {
        import grpc.core.utils;
        grpc_slice _dat = type_to_slice!(ubyte[])(_data);
        grpc_byte_buffer** res = cast(grpc_byte_buffer**)gpr_zalloc((void*).sizeof);
        grpc_byte_buffer* _buf = grpc_raw_byte_buffer_create(&_dat, 1);
        *res = _buf;
        return ByteBuffer(cast(shared)Mutex.create(), SharedResource(cast(shared)res, &release));
    }
    
    ~this() {
        buf.forceRelease();
    }
}
