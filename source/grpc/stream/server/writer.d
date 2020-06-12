module grpc.stream.server.writer;
import interop.headers;
import grpc.logger;
import grpc.core.tag;
import google.rpc.status;
import grpc.common.cq;
import grpc.common.batchcall;
import grpc.common.call;

class ServerWriter(T) {
    private {
        BatchCall _op;
        CompletionQueue!"Next"* _cq;
        Tag* _tag;
        bool _started;
    }

    bool start() {
        _op.reset();

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

        _op.reset();
        ubyte[] _out = obj.toProtobuf.array;
        DEBUG!"constructing";
        _op.addOp(new SendMessageOp(_out));

        DEBUG!"running";
        _op.run(_cq, _tag);

        return true;
    }

    bool finish(Status _stat) {
        if(!_started) {
            return false;
        }

        bool ok = false;

        _op.reset();
        DEBUG!"reset, running";
        _op.addOp(new SendStatusFromServerOp(cast(grpc_status_code)_stat.code, _stat.message));
        _op.run(_cq, _tag);

        return true;
    }

    this(CompletionQueue!"Next"* cq, Tag* tag) {
        _cq = cq;
        _tag = tag;
        _op = new BatchCall();
    }

    ~this() {

    }



}
