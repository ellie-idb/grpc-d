module grpc.common.byte_buffer;
import grpc.logger;
import interop.headers;
import grpc.core.resource;
import grpc.core.mutex;

class ByteBuffer {
    private {
        GPRMutex mutex;
        SharedResource _buf;
        grpc_byte_buffer_reader reader;
        bool _readerInit;
        bool _freeOnExit;
    }
    
    @property inout(grpc_byte_buffer)** handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _buf.handle;
    }
    
    @property inout(grpc_byte_buffer)* unsafeHandle() inout @trusted pure nothrow {
        return cast(typeof(return)) *handle;
    }
    
    @property bool valid() {
        return unsafeHandle != null;
    }

    @property bool compressed() {
        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");
        
        return unsafeHandle.type == GRPC_BB_RAW;
    }

    @property ulong length() {
        lock;
        scope(exit) unlock;
        
        if (!valid) {
            return 0;
        } else {
            return grpc_byte_buffer_length(unsafeHandle);
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

    auto ref readAll() {
        import grpc.core.utils;
        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");

        return byte_buffer_to_type!(ubyte[])(unsafeHandle);
    }

    ubyte[] read() {
        ubyte[] ret;
        lock;
        scope(exit) unlock;
        
        assert(valid, "byte buffer was not valid");
        
        if(_readerInit == false) {
            grpc_byte_buffer_reader_init(&reader, unsafeHandle);
            _readerInit = true;
        }

        grpc_slice slice;
        reader.current.index = 0;
        if(grpc_byte_buffer_reader_next(&reader, &slice) != 0) {
            import grpc.core.utils;

            ret = slice_to_type!(ubyte[])(slice);
            grpc_slice_unref(slice);
        }
        else {
            grpc_byte_buffer_reader_destroy(&reader);
            reader = reader.init;
        }

        return ret;
    }


    static ByteBuffer copy(ByteBuffer obj) {
        obj.lock;
        scope(exit) obj.unlock;

        assert(obj.valid, "byte buffer was not valid");
        auto buf_2 = grpc_byte_buffer_copy(obj.unsafeHandle);
        ByteBuffer ret = theAllocator.make!ByteBuffer();
        *(ret.handle) = buf_2;
        return ret;
    }
    
    void cleanup() {
        lock;
        scope(exit) unlock;
        assert(valid, "byte buffer must be valid to clean");
        grpc_byte_buffer_destroy(unsafeHandle);
        *(handle) = null;
        assert(!valid, "byte buffer must be invalid now");
    }
    
    static ByteBuffer opCall(ref ubyte[] data) @trusted {
        ByteBuffer obj = theAllocator.make!ByteBuffer(data);
        return obj;
    }
    
    static ByteBuffer opCall() @trusted {
        ByteBuffer obj = theAllocator.make!ByteBuffer();
        return obj;
    }

    this() @trusted {
        static Exception release(shared(void)* ptr) @trusted nothrow {
            grpc_byte_buffer** v = cast(grpc_byte_buffer**)ptr;
            if (v != null) {
                if (*v != null) {
                    grpc_byte_buffer_destroy(*v);
                    *v = null;
                }
                gpr_free(cast(void*)v);
                v = null;
            }
            return null;
        }
        
        grpc_byte_buffer** buf = cast(grpc_byte_buffer**)gpr_zalloc((grpc_byte_buffer**).sizeof);
        
        assert(buf != null, "malloc failed");
        
        _buf = SharedResource(cast(shared)buf, &release);
        mutex = theAllocator.make!GPRMutex();
    }

    this(ref ubyte[] _data) @trusted {
        import grpc.core.utils;
        grpc_slice _dat = type_to_slice!(ubyte[])(_data);
        DEBUG!"sliced, creating new buf (%x)"(&_dat);
        grpc_byte_buffer* buf = grpc_raw_byte_buffer_create(&_dat, 1);
        grpc_slice_unref(_dat);
        this(buf);
        DEBUG!"ok!";
    }

    
    private this(grpc_byte_buffer* bb) @trusted {
        DEBUG!"setting unsafe handle";
        this();
        *(handle) = bb;
    }
    
    ~this() {
        _buf.forceRelease();
        theAllocator.dispose(mutex);
    }
}
