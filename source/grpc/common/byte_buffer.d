module grpc.common.byte_buffer;
import interop.headers;
import grpc.logger;
import grpc.core.resource;
import grpc.core.utils;
import fearless;
import core.stdc.string : memset;

struct ByteBuffer {
@safe:
    private {
        SharedResource _buf;
        grpc_byte_buffer_reader reader;
        bool _readerInit;
    }

    @property inout(grpc_byte_buffer)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _buf.handle;
    }
    
    @property bool compressed() {
        return this.handle.type == GRPC_BB_RAW;
    }

    @property ulong length() @trusted {
        return grpc_byte_buffer_length(this.handle);
    }

    ubyte[] readAll() @trusted {
        import grpc.core.utils;
        ubyte[] dat;

        dat = cast(ubyte[])byte_buffer_to_string(this.handle);
        import std.stdio;

        if(dat.length != length()) {

            grpc_byte_buffer_reader reader;
            grpc_byte_buffer_reader_init(&reader, this.handle);

            grpc_byte_buffer* _2 = grpc_raw_byte_buffer_from_reader(&reader);
            writeln("byte buffer did not match what was expected?");

            { 
                writeln(cast(ubyte[])byte_buffer_to_string(_2));
            }

            writeln(grpc_byte_buffer_length(_2));
            writeln(this.handle.data.raw.slice_buffer.length);

            grpc_byte_buffer_destroy(_2);
            grpc_byte_buffer_reader_destroy(&reader);
        }

        return dat;
    }

    ubyte[] read() @trusted {
        import std.stdio;
        ubyte[] ret;
        if(_readerInit == false) {
            if(this.handle != null) {
                grpc_byte_buffer_reader_init(&reader, this.handle);
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
            grpc_slice_unref(slice);
        }
        else {
            grpc_byte_buffer_reader_destroy(&reader);
            reader = reader.init;
        }

        return ret;
    }


    ByteBuffer dup() @trusted {
        auto buf2 = grpc_byte_buffer_copy(this.handle);

        static Exception release(shared(void)* ptr) @trusted nothrow {
            grpc_byte_buffer_destroy(cast(grpc_byte_buffer*)ptr);
            return null;
        }

        ByteBuffer ret;
        ret._buf = SharedResource(cast(shared)buf2, &release);
        return ret;
    }

    static ByteBuffer opCall() @trusted {
        ByteBuffer buf; 
        if(grpc_byte_buffer* c_buf = cast(grpc_byte_buffer*)gpr_malloc(grpc_byte_buffer.sizeof)) {
            memset(c_buf, 0, grpc_byte_buffer.sizeof);

            static Exception release(shared(void)* ptr) @trusted nothrow {
                gpr_free(cast(void*)ptr);
                return null;
            }

            buf._buf = SharedResource(cast(shared)c_buf, &release);

            return buf;
        }
        else {
            throw new Exception("Could not create a new byte buffer");
        }
    }
    
    @disable this(this);

    ~this() {
    }

}
