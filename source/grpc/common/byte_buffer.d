module grpc.common.byte_buffer;
import interop.headers;
import fearless;

struct ByteBufferWrapper {
    grpc_byte_buffer* _buf;
    alias _buf this;
}

class ByteBuffer {
    private {
        Exclusive!ByteBufferWrapper* _buf;
        grpc_byte_buffer_reader reader;
        bool _readerInit;
    }
    
    auto borrow() {
        import std.stdio;
        debug writeln("bf: ", _buf.isLocked);
        return _buf.lock();
    }

    @property bool compressed() {
        auto buf = _buf.lock();
        if(buf._buf == null) {
            return false;
        }
        return buf._buf.type == GRPC_BB_RAW;
    }

    @property ulong length() {
        auto buf = _buf.lock();
        if(buf._buf == null) {
            return 0;
        }
        return grpc_byte_buffer_length(buf);
    }

    ubyte[] readAll() {
        import grpc.core.utils;
        auto buf = _buf.lock();
        ubyte[] dat;
        if(buf._buf == null) {
            return dat; 
        }

        dat = cast(ubyte[])byte_buffer_to_string(buf);
        import std.stdio;

        if(dat.length != length()) {

            grpc_byte_buffer_reader reader;
            grpc_byte_buffer_reader_init(&reader, buf);

            grpc_byte_buffer* _2 = grpc_raw_byte_buffer_from_reader(&reader);
            writeln("byte buffer did not match what was expected?");

            { 
                writeln(cast(ubyte[])byte_buffer_to_string(_2));
            }

            writeln(grpc_byte_buffer_length(_2));
            writeln(buf._buf.data.raw.slice_buffer.length);

            grpc_byte_buffer_destroy(_2);
            grpc_byte_buffer_reader_destroy(&reader);
        }

        return dat;
    }

    ubyte[] read() {
        import std.stdio;
        ubyte[] ret;
        if(_readerInit == false) {
            auto buf = _buf.lock();

            if(buf._buf != null) {
                grpc_byte_buffer_reader_init(&reader, buf._buf);
                _readerInit = true;
            }
            else {
                return ret;
            }
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
        import grpc.core.utils;
        ubyte[] data = [0xFF]; 
        grpc_slice _dat = type_to_slice!(ubyte[])(data);
        grpc_byte_buffer* buf = grpc_raw_byte_buffer_create(&_dat, data.length);
        grpc_slice_unref(_dat);

        _buf = new Exclusive!ByteBufferWrapper(buf);

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
