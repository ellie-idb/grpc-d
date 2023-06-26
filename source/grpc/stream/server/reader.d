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

alias Reader = ServerReader;

struct ServerReader(T) {
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
            DEBUG!"ctx data is invalid, asking for a new message";
            RecvMessageOp op = theAllocator.make!(RecvMessageOp)(&_tag.ctx.data);
            BatchCall.runSingleOp(op, _cq, _tag, d);
            theAllocator.dispose(op);
        }

        ulong len = _tag.ctx.data.length;
        DEBUG!"bf.length: %d"(len);
        if(len != 0) {
            auto data = _tag.ctx.data.readAll();
            if (data.length != 0) { 
                ubyte[] dat = data;
                DEBUG!"%s"(dat);
                protobuf = dat.fromProtobuf!(T);
            }

            _tag.ctx.data.cleanup();
        }
        return protobuf;
    }

    void finish() {
        DEBUG!"finishing";
        RecvCloseOnServerOp op = theAllocator.make!RecvCloseOnServerOp();
        BatchCall.runSingleOp(op, _cq, _tag);
        theAllocator.dispose(op);
        _closed = true;
    }

    this(Tag* tag, CompletionQueue!"Next" cq) {
        _tag = tag;
        _cq = cq;
    }

    @disable this();
    @disable this(this);
}
