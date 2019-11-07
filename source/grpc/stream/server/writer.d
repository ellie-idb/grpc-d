module grpc.stream.server.writer;
import grpc.core.grpc_preproc;
import grpc.core.tag;
import google.rpc.status;
import grpc.common.cq;

class ServerWriter(T) {
    private {
        CompletionQueue!"Pluck" _cq;
        grpc_call* _call;
        Tag _tag;
    }

    bool start() {
        grpc_op[1] _initialOp;
        _initialOp[0].op = GRPC_OP_SEND_INITIAL_METADATA;
        auto status = grpc_call_start_batch(_call, _initialOp.ptr, 1, &_tag, null);

        if(status == GRPC_CALL_OK) {
            _cq.next(_tag, 1.msecs);
            return true;
        }

        return false;
    }

    bool write(T obj) {
        import std.array;
        import google.protobuf;
        bool ok = false;
        ubyte[] _out = obj.toProtobuf.array;
        grpc_slice msg = grpc_slice_ref(grpc_slice_from_copied_buffer(cast(const(char*))_out, _out.length));
        grpc_byte_buffer* bytebuf = grpc_raw_byte_buffer_create(&msg, 1);

        grpc_op[1] _sendOp;
        _sendOp[0].op = GRPC_OP_SEND_MESSAGE;
        _sendOp[0].data.send_message.send_message = bytebuf;
        auto status = grpc_call_start_batch(_call, _sendOp.ptr, 1, &_tag, null);
        if(status == GRPC_CALL_OK) {
            _cq.next(_tag, 1.msecs);
            ok = true;
        }

        grpc_slice_unref(msg);

        return ok;
    }

    bool finish(Status _stat) {
        bool ok = false;

        grpc_op[1] _finalOp;

        _finalOp[0].op = GRPC_OP_SEND_STATUS_FROM_SERVER;
        grpc_slice statusDetails;
        if(_stat.code != 0) {
            _finalOp[0].data.send_status_from_server.status = cast(grpc_status_code)_stat.code;
            if(_stat.message != "") {
                import std.string : toStringz;
                statusDetails = grpc_slice_ref(grpc_slice_from_copied_buffer(_stat.message.toStringz, _stat.message.length));
                _finalOp[0].data.send_status_from_server.status_details = &statusDetails;
            }
        }
        else {
            _finalOp[0].data.send_status_from_server.status = GRPC_STATUS_OK;
        }

        auto status = grpc_call_start_batch(_call, _finalOp.ptr, 1, &_tag, null);
        if(status == GRPC_CALL_OK) {
            _cq.next(_tag, 1.msecs);
            ok = true;
        }

        grpc_slice_unref(statusDetails);
 
        return true;
    }

    this(CompletionQueue!"Pluck" cq, grpc_call* call, ref Tag tag) {
        _cq = cq;
        _call = call;
        _tag = tag;

    }

    ~this() {

    }



}
