module grpc.common.byte_buffer;
import grpc.logger;
import interop.headers;
import grpc.core.resource;
import grpc.core.mutex;

struct ByteBuffer {
    private {
        GPRMutex mutex;
        SharedResource _buf;
        grpc_byte_buffer_reader reader;
        bool _readerInit;
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
        mutex.lock;
        scope(exit) mutex.unlock;
        
        assert(valid, "byte buffer was not valid");
        
        return unsafeHandle.type == GRPC_BB_RAW;
    }

    @property ulong length() {
        mutex.lock;
        scope(exit) mutex.unlock;
        
        assert(valid, "byte buffer was not valid");
        
        return grpc_byte_buffer_length(unsafeHandle);
    }
    
    void lock() {
        INFO!"bf lock";
        mutex.lock;
    }
    
    void unlock() {
        INFO!"bf unlock";
        mutex.unlock;
    }

    ubyte[] readAll() {
        import grpc.core.utils;
        mutex.lock;
        scope(exit) mutex.unlock;
        
        assert(valid, "byte buffer was not valid");
        ubyte[] dat;

        dat = cast(ubyte[])byte_buffer_to_string(unsafeHandle);
        import std.stdio;

        /*
        if(dat.length != length()) {

            grpc_byte_buffer_reader reader;
            grpc_byte_buffer_reader_init(&reader, buf);

            grpc_byte_buffer* _2 = grpc_raw_byte_buffer_from_reader(&reader);
            ERROR!"byte buffer did not match what was expected?"();

            { 
                ERROR!"byte buffer: %s"(cast(ubyte[])byte_buffer_to_string(_2));
            }

            ERROR!"length: %d"(grpc_byte_buffer_length(_2));
            ERROR!"length: %d"(buf._buf.data.raw.slice_buffer.length);

            grpc_byte_buffer_destroy(_2);
            grpc_byte_buffer_reader_destroy(&reader);
        }
        */

        return dat;
    }

    ubyte[] read() {
        ubyte[] ret;
        mutex.lock;
        scope(exit) mutex.unlock;
        
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
//            grpc_slice_unref(slice);
        }
        else {
            grpc_byte_buffer_reader_destroy(&reader);
            reader = reader.init;
        }

        return ret;
    }


    static ByteBuffer copy(ByteBuffer obj) {
        obj.mutex.lock;
        scope(exit) obj.mutex.unlock;
        assert(obj.valid, "byte buffer was not valid");
        
        auto buf_2 = grpc_byte_buffer_copy(obj.unsafeHandle);
        ByteBuffer ret = ByteBuffer(buf_2);
        return ret;
    }

    static ByteBuffer opCall() @trusted {
        ByteBuffer obj;
        static Exception release(shared(void)* ptr) @trusted nothrow {
            grpc_byte_buffer** v = cast(grpc_byte_buffer**)ptr;
            if (v != null) {
                if (*v != null) {
                    grpc_byte_buffer_destroy(*v);
                }
                gpr_free(cast(void*)ptr);
            }
            return null;
        }
        
        grpc_byte_buffer** buf = cast(grpc_byte_buffer**)gpr_zalloc((grpc_byte_buffer**).sizeof);
        if (buf != null) {
            obj._buf = SharedResource(cast(shared)buf, &release);
            obj.mutex = GPRMutex();
        } else {
            throw new Exception("malloc failed");
        } 
        
        return obj;
    }

    static ByteBuffer opCall(ubyte[] _data) @trusted {
        import grpc.core.utils;
        ubyte[] data = _data.dup;
        grpc_slice _dat = type_to_slice!(ubyte[])(data);
        grpc_slice_ref(_dat);
        DEBUG!"sliced, creating new buf (%x)"(&_dat);
        grpc_byte_buffer* buf = grpc_raw_byte_buffer_create(&_dat, 1);
        DEBUG!"ok!";
        
        return ByteBuffer(buf);
    }
    
    private static ByteBuffer opCall(grpc_byte_buffer* bb) @trusted {
        ByteBuffer obj = ByteBuffer();
        DEBUG!"setting unsafe handle";
        *(obj.handle) = bb;
        
        return obj;
    }

    @disable this(this);
}
