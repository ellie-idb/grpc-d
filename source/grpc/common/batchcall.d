module grpc.common.batchcall;
import interop.headers;
import grpc.common.call;
import grpc.core.utils;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.logger;

interface RemoteOp {
    grpc_op_type type();
    grpc_op value();
}

class SendInitialMetadataOp : RemoteOp {
    private {
        grpc_metadata[] collectedMetadata;
        Metadata[] _data;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_INITIAL_METADATA;
    }

    grpc_op value() {
        static grpc_op ret;

        foreach(_meta; _data) {
            grpc_metadata meta = _meta.borrow();
            collectedMetadata ~= meta;
        }

        ret.op = type();
        ret.data.send_initial_metadata.metadata = collectedMetadata.ptr;
        ret.data.send_initial_metadata.count = collectedMetadata.length;

        return ret;
    }

    this(Metadata[] data) {
        _data = data;
    }

    this() {

    }

}

class SendMessageOp : RemoteOp {
    private {
        grpc_byte_buffer* _buf;
        ubyte[] message;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_MESSAGE;
    }

    grpc_op value() {
        static grpc_op ret;
        ret.op = type();
        ret.data.send_message.send_message = _buf;
        return ret;
    }

    this(ubyte[] message) {
        grpc_slice msg = type_to_slice!(ubyte[])(message); 
        _buf = grpc_raw_byte_buffer_create(&msg, 1); 
        grpc_slice_unref(msg);
    }

    ~this() {
        grpc_byte_buffer_destroy(_buf);
    }
}

class SendStatusFromServerOp : RemoteOp {
    private {
        Metadata[] _trailing_metadata;
        grpc_metadata[] _collectedMetadata;
        grpc_status_code _status;
        grpc_slice _details;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_STATUS_FROM_SERVER;
    }

    grpc_op value() {
        foreach(_meta; _trailing_metadata) {
            grpc_metadata meta = _meta.borrow();
            _collectedMetadata ~= meta;
        }
        static grpc_op ret;
        ret.op = type();
        ret.data.send_status_from_server.status_details = &_details;
        ret.data.send_status_from_server.status = _status;
        ret.data.send_status_from_server.trailing_metadata_count = _trailing_metadata.length;
        ret.data.send_status_from_server.trailing_metadata = _collectedMetadata.ptr; 
        return ret;
    }

    this(Metadata[] trailing_metadata, grpc_status_code code, string details) {
        _details = string_to_slice(details);
        _trailing_metadata = trailing_metadata;
        _status = code;
    }

    this(grpc_status_code code, string details) {
        _details = string_to_slice(details);
        _status = code;
    }

    ~this() {
        grpc_slice_unref(_details);
    }
}

class RecvInitialMetadataOp : RemoteOp {
    private {
        MetadataArray _metadata;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_INITIAL_METADATA;
    }

    grpc_op value() {
        static grpc_op ret;
        ret.op = type();

        grpc_metadata_array metadata = _metadata.borrow();
        ret.data.recv_initial_metadata.recv_initial_metadata = &metadata; 

        return ret;
    }

    this(MetadataArray metadata) {
        _metadata = metadata;
    }

}

class RecvMessageOp : RemoteOp {
    private {
        ByteBuffer _buf;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_MESSAGE;
    }

    grpc_op value() {
        static grpc_op ret;
        auto buf = _buf.borrow();
        ret.op = type();
        ret.data.recv_message.recv_message = &buf._buf; 

        return ret;
    }

    this(ByteBuffer buf) {
        _buf = buf;
    }
}
/*

class RecvStatusOnClientOp : RemoteOp {
    private {

    }

    grpc_op_type type() {
        return GRPC_OP_RECV_STATUS_ON_CLIENT;
    }

}
*/

class RecvCloseOnServerOp : RemoteOp {
    private {
        int* _cancelled;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_CLOSE_ON_SERVER;
    }

    grpc_op value() {
        static grpc_op ret;
        ret.op = type();
        ret.data.recv_close_on_server.cancelled = _cancelled;

        return ret;
    }

    this(int* cancelled) {
        _cancelled = cancelled;
    }
}

class BatchCall {
    private {
        RemoteOp[] ops;

        bool sanityCheck() {
            int[int] count;
            foreach(op; ops) {
                count[op.type()]++;
                if(count[op.type()] > 1) {
                    return false;
                }
            }
            return true;
        }
    }

    void addOp(RemoteOp _op) {
        ops ~= _op;
    }
    
    import grpc.core.tag;
    import core.time;
    import grpc.common.cq;

    /* requires the caller to have a lock on the CallContext */
    grpc_call_error run(CompletionQueue!"Next"* cq, Tag* _tag, Duration d = 1.msecs) {
        assert(sanityCheck(), "failed sanity check");
        assert(_tag != null, "tag should never be null");
        CallContext* ctx = &_tag.ctx;
        grpc_op[] _ops;

        foreach(op; ops) {
            _ops ~= op.value();
        }

        DEBUG!"starting batch on tag: %x"(_tag);
        auto status = grpc_call_start_batch(*ctx.call, _ops.ptr, _ops.length, _tag, null);  
        if(status == GRPC_CALL_OK) {
            import core.time;
            cq.next(d);
        } else {
            ERROR!"STATUS: %s"(status);
        }

        return status;

    }

    void reset() {
        ops = ops.init;
    }

    this() {
    }

}
