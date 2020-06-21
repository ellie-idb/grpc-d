module grpc.stream.server.writer;
import interop.headers;
import grpc.logger;
import grpc.core.tag;
import google.rpc.status;
import grpc.common.cq;
import grpc.common.batchcall;
import grpc.common.call;
import core.atomic;

class ServerWriter(T) {
    private {
        BatchCall _op;
        CompletionQueue!"Next" _cq;
        shared(bool) _started;
    }

    bool start(Tag* tag) {
        _op.reset;
        _op.addOp(new SendInitialMetadataOp()); 
        _op.run(_cq, tag);

        atomicStore(_started, true);

        return true;
    }

    bool write(Tag* tag, T obj) {
        import std.array;
        import google.protobuf;
        
        if(!atomicLoad(_started)) {
            return false;
        }

        _op.reset;
        ubyte[] _out = obj.toProtobuf.array;
        _op.addOp(new SendMessageOp(_out));
        DEBUG!"running";
        _op.run(_cq, tag);

        return true;
    }

    bool finish(Tag* tag, Status _stat) {
        if(!atomicLoad(_started)) {
            return false;
        }

        bool ok = false;

        BatchCall op = new BatchCall();
        DEBUG!"reset, running";
        op.addOp(new SendStatusFromServerOp(cast(grpc_status_code)_stat.code, _stat.message));
        op.run(_cq, tag);

        return true;
    }

    this(CompletionQueue!"Next" cq) {
        _op = new BatchCall();
        _cq = cq;
    }

    ~this() {
    }



}
