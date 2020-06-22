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
import stdx.allocator : theAllocator, make, dispose;

class ServerWriter(T) {
    private {
        BatchCall _op;
        CompletionQueue!"Next" _cq;
        bool started = false;
    }

    bool start(Tag* tag) {
        _op.addOp(SendInitialMetadataOp()); 
        _op.run(_cq, tag);

        started = true;

        return true;
    }

    bool write(Tag* tag, T obj) {
        import std.array;
        import google.protobuf;
        
        if(!started) {
            return false;
        }
        
        ubyte[] _out = obj.toProtobuf.array;
        _op.addOp(SendMessageOp(_out));
        DEBUG!"running";
        _op.run(_cq, tag);
        
        return true;
    }

    bool finish(Tag* tag, ref Status _stat) {
        if(!started) {
            return false;
        }

        DEBUG!"reset, running";
        _op.addOp(SendStatusFromServerOp(cast(grpc_status_code)_stat.code, _stat.message));
        _op.run(_cq, tag);

        return true;
    }

    this(CompletionQueue!"Next" cq) {
        _op = BatchCall();
        _cq = cq;
    }

    ~this() {
        theAllocator.dispose(_op);
    }
    
    static ServerWriter!T opCall(CompletionQueue!"Next" cq) {
        ServerWriter!T obj = theAllocator.make!(ServerWriter!T)(cq);
        return obj;
    }
}
