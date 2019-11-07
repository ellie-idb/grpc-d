module grpc.common.byte_buffer;
import grpc.core.grpc_preproc;
import grpc.core.alloc;
import fearless;

struct ByteBufferWrapper {
    grpc_byte_buffer* _buf;
    alias _buf this;
}

class ByteBuffer {
    private {
        Exclusive!ByteBufferWrapper* _buf;
    }
    
    auto borrow() {
        synchronized {
            return _buf.lock();
        }
    }

    @property ulong length() {
        auto buf = _buf.lock();
        return grpc_byte_buffer_length(buf);
    }

    ubyte[] readAll() {
        import grpc.core.utils;
        auto buf = _buf.lock();
        ubyte[] dat = cast(ubyte[])byte_buffer_to_string(buf);

        return dat;
    }

    ByteBuffer copy() {
        auto buf = _buf.lock();
        auto buf2 = grpc_byte_buffer_copy(buf);
        ByteBuffer ret = new ByteBuffer(buf2);
        return ret;
    }

    package this(grpc_byte_buffer* buf) {
        _buf = new Exclusive!ByteBufferWrapper(buf);
    }
    
    this() {
        _buf = new Exclusive!ByteBufferWrapper(cast(grpc_byte_buffer*)0);
    }

    this(ubyte[] data) {
        import grpc.core.utils;
        grpc_slice _dat = type_to_slice!(ubyte[])(data);
        grpc_byte_buffer* buf = grpc_raw_byte_buffer_create(&_dat, data.length);
        grpc_slice_unref(_dat);

        _buf = new Exclusive!ByteBufferWrapper(buf);
    }

    ~this() {
        auto buf = _buf.lock();
        grpc_byte_buffer_destroy(buf);
    }
}
