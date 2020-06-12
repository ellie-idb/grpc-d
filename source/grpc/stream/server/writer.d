module grpc.stream.server.writer;
import interop.headers;
import grpc.core.tag;
import google.rpc.status;
import grpc.common.cq;
import grpc.common.batchcall;
import grpc.common.call;

class ServerWriter(T) {
    private {
        CompletionQueue!"Next"* _cq;
        Tag* _tag;
        bool _started;
    }

    bool start() {
        BatchCall _op = new BatchCall();

        _op.addOp(new SendInitialMetadataOp()); 

        _op.run(_cq, _tag);

        _started = true;

        return false;
    }

    bool write(T obj) {
        import std.array;
        import google.protobuf;
        
        if(!_started) {
            return false;
        }

        BatchCall _op = new BatchCall();
        ubyte[] _out = obj.toProtobuf.array;
        _op.addOp(new SendMessageOp(_out));

        _op.run(_cq, _tag);

        return true;
    }

    bool finish(Status _stat) {

        if(!_started) {
            return false;
        }

        bool ok = false;

        BatchCall _op = new BatchCall();

        _op.addOp(new SendStatusFromServerOp(cast(grpc_status_code)_stat.code, _stat.message));
        _op.run(_cq, _tag);

        return true;
    }

    this(CompletionQueue!"Next"* cq, Tag* tag) {
        _cq = cq;
        _tag = tag;
    }

    ~this() {

    }



}
