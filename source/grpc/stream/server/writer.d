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

class ServerWriter(T) {
    private {
        CompletionQueue!"Next" _cq;
        bool started = false;
    }

    bool start(Tag* tag) {
        SendInitialMetadataOp op = theAllocator.make!SendInitialMetadataOp();
        BatchCall.runSingleOp(op, _cq, tag);
        theAllocator.dispose(op);
        
        started = true;

        return true;
    }

    bool write(Tag* tag, T obj) {
        import std.array;
        import google.protobuf;
        
        if(!started) {
            return false;
        }
        ubyte[] _out = theAllocator.makeArray!ubyte(obj.toProtobuf.array);
        DEBUG!"running";
        SendMessageOp op = theAllocator.make!SendMessageOp(_out);
        BatchCall.runSingleOp(op, _cq, tag);
        theAllocator.dispose(op);
        theAllocator.dispose(_out);

        destroy(_out);
        return true;
    }

    bool finish(Tag* tag, ref Status _stat) {
        DEBUG!"finish called";
        SendStatusFromServerOp op = theAllocator.make!SendStatusFromServerOp();
        BatchCall.runSingleOp(op, _cq, tag);
        theAllocator.dispose(op);
        return true;
    }

    this(CompletionQueue!"Next" cq) {
        _cq = cq;
    }

    ~this() {
    }
}
