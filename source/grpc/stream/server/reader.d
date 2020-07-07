module grpc.stream.server.reader;
import grpc.logger;
import grpc.core.tag;
import interop.headers;
import grpc.common.cq; 
import grpc.common.call;
import grpc.core.utils;
import grpc.common.batchcall;
import automem;
import std.experimental.allocator : theAllocator, make, makeArray, dispose;

class ServerReader(T) {
    private {
        bool _closed;
        Tag* _tag;
        CompletionQueue!"Next" _cq;
    }

    import grpc.common.byte_buffer;
    import google.protobuf;

    @property bool closed() {
        return _closed;
    }

    auto readOne(Duration d = 1.seconds) {
        assert(_tag != null, "tag shouldn't be null");

        T protobuf = T.init;

        if (!_tag.ctx.data.valid) {
            RecvMessageOp op = theAllocator.make!(RecvMessageOp)(_tag.ctx.data);
            BatchCall.runSingleOp(op, _cq, _tag, d);
            theAllocator.dispose(op);
        }

        ulong len = _tag.ctx.data.length;
        DEBUG!"bf.length: %d"(len);
        if(len != 0) {
            auto data = _tag.ctx.data.readAll();
            if (data.length != 0) { 
                void* ubytePtr = data.ptr;
                DEBUG!"POINTER: %x (or %x?)"(cast(void*)data, data.ptr);
                protobuf = fromProtobuf!(T, ubyte[])(data);

                theAllocator.dispose(cast(ubyte*)ubytePtr);
            }

            _tag.ctx.data.cleanup();
        }
        return protobuf;
    }

    /*
    auto read(int count = 0)(Duration d = 10.seconds) {
        import std.concurrency;
        import std.stdio;

        auto r = new Generator!T({
            auto ctx = &_tag.ctx;
            ByteBuffer* bf = &ctx.data;
            static if(count == 1) {
                DEBUG!"unary call, so read off of the context bytebuffer (ptr: %x)"(bf);
                T protobuf;
                
                DEBUG!"checking if bf is valid";
                
                assert(bf.valid, "byte buffer should always be valid");
                
                DEBUG!"bf.length: %d"(bf.length);
                if(bf.length != 0 && bf.valid) {
                    ubyte[] data = bf.readAll();
                    DEBUG!"attempting to deserde";
                    protobuf = data.fromProtobuf!T();
                }

                yield(protobuf);
                DEBUG!"we're done here";
            }
            else {
                BatchCall batch = new BatchCall();
                ubyte[] data;

                while(bf.length != 0) {
                    data = bf.readAll();
                    T protobuf;

                    if(data.length == 0) {
                        return;
                    }

                    try { 
                        protobuf = data.fromProtobuf!T();
                    } catch(Exception e) {
                        ERROR!"Deserialization fault: %s"(e.msg);
                        ERROR!"%s"(data);
                        ERROR!"Byte buffer length: %d"(bf.length);

                        return;
                    }

                    yield(protobuf);

                    batch.addOp(theAllocator.make!RecvMessageOp(bf));
                    auto stat = batch.run(_cq, _tag, d);
                    if(stat != GRPC_CALL_OK) {
                        ERROR!"READ ERROR: %s"(stat);
                        return;
                    }

                }
                
            }
        });

        return r;
    }
    */

    void finish() {
        DEBUG!"finishing";
        RecvCloseOnServerOp op = theAllocator.make!RecvCloseOnServerOp();
        BatchCall.runSingleOp(op, _cq, _tag);
        theAllocator.dispose(op);
        _closed = true;
    }

    this(Tag* tag, CompletionQueue!"Next" cq) {
        _tag = tag;
        import std.stdio;
        _cq = cq;
    }

    ~this() {
    }
}
