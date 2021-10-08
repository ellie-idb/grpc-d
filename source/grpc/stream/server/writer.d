module grpc.stream.server.writer;
import interop.headers;
import grpc.logger;
import grpc.core.tag;
import google.rpc.status;
import grpc.common.cq;
import grpc.common.batchcall;
import grpc.common.call;
import core.atomic;
import automem;
import std.experimental.allocator : theAllocator, make, dispose, makeArray;

struct ServerWriter(T) {
    private {
        Tag* _tag;
        CompletionQueue!"Next" _cq;
        bool started = false;
        bool _closed;
    }

    @property bool closed() {
        return _closed;
    }

    bool start() {
        SendInitialMetadataOp op = theAllocator.make!SendInitialMetadataOp();
        BatchCall.runSingleOp(op, _cq, _tag);
        theAllocator.dispose(op);
        
        started = true;
        _closed = false;

        return true;
    }

    bool write(T obj) {
        import std.array;
        import google.protobuf;

        grpc_call_error err;

        if (closed) {
            return false;
        }
        
        if(!started) {
            return false;
        }
        ubyte[] _out = theAllocator.makeArray!ubyte(obj.toProtobuf.array);
        DEBUG!"running";
        SendMessageOp op = theAllocator.make!SendMessageOp(_out);
        err = BatchCall.runSingleOp(op, _cq, _tag);
        theAllocator.dispose(op);
        theAllocator.dispose(_out);

        return err == GRPC_CALL_OK;
    }

    bool finish(ref Status _stat) {
        if (closed) {
            return true;
        }

        DEBUG!"finish called";
        SendStatusFromServerOp op = theAllocator.make!SendStatusFromServerOp();
        BatchCall.runSingleOp(op, _cq, _tag);
        theAllocator.dispose(op);
        _closed = true;
        return true;
    }

    this(Tag* tag, CompletionQueue!"Next" cq) {
        _tag = tag;
        _cq = cq;
    }

    @disable this();
    @disable this(this);

    ~this() {
    }
}
