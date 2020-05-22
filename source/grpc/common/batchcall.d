module grpc.common.batchcall;
import interop.headers;
import grpc.common.call;
import grpc.core.utils;
import grpc.common.metadata;
import grpc.common.byte_buffer;

interface RemoteOp {
    grpc_op_type type();
    grpc_op value();
}

class SendInitialMetadataOp : RemoteOp {
    private {
        grpc_metadata[] collectedMetadata;
        MetadataArray _data;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_INITIAL_METADATA;
    }

    grpc_op value() {
        static grpc_op ret;

        if(_data !is null) {
            for(int i = 0; i < _data.count; i++) {
                auto _meta = _data[i];
                grpc_metadata meta = *_meta.handle;
                collectedMetadata ~= meta;
            }
        }

        ret.op = type();
        ret.data.send_initial_metadata.metadata = collectedMetadata.ptr;
        ret.data.send_initial_metadata.count = collectedMetadata.length;

        return ret;
    }

    this(ref MetadataArray data) {
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
        MetadataArray _trailing_metadata;
        grpc_metadata[] _collectedMetadata;
        grpc_status_code _status;
        grpc_slice _details;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_STATUS_FROM_SERVER;
    }

    grpc_op value() {
        static grpc_op ret;

        if(_trailing_metadata !is null) { 
            for(int i = 0; i < _trailing_metadata.count; i++) {
                auto _meta = _trailing_metadata[i];

                grpc_metadata meta = *_meta.handle();
                _collectedMetadata ~= meta;
            }
            ret.data.send_status_from_server.trailing_metadata_count = _trailing_metadata.count;
            ret.data.send_status_from_server.trailing_metadata = _collectedMetadata.ptr; 

        }

        ret.op = type();
        ret.data.send_status_from_server.status_details = &_details;
        ret.data.send_status_from_server.status = _status;
        return ret;
    }

    this(MetadataArray trailing_metadata, grpc_status_code code, string details) {
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
        ByteBuffer* _buf;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_MESSAGE;
    }

    grpc_op value() {
        static grpc_op ret;
        auto buf = _buf.handle;
        ret.op = type();
        ret.data.recv_message.recv_message = &buf; 

        return ret;
    }

    this(ref ByteBuffer buf) {
        _buf = &buf;
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
        RemoteCall* _call;

        __gshared RemoteOp[] ops;

        bool sanityCheck() {
            int[int] count;
            try {
                foreach(op; ops) {
                    count[op.type()]++;
                    if(count[op.type()] > 1) {
                        return false;
                    }
                }
            } catch(Exception e) {
                return false;
            }
            return true;
        }
    }

    void addOp(RemoteOp _op) {
        ops ~= _op;
    }
    
    import grpc.core.tag;

    import core.time;
    grpc_call_error run(ref Tag _tag, Duration d = 1.msecs) {
        import std.stdio;

        writeln("sanity check: ", sanityCheck());
        assert(sanityCheck(), "failed sanity check");

        writeln("borrowing call");

        auto call = _call.handle;

        writeln("done");

        grpc_op[] _ops;

        writeln(ops.length);

        foreach(op; ops) {
            if(op is null) {
                writeln("op was null?");
                break;
            }
            _ops ~= op.value();
        }

        writeln("starting batched call");



        auto status = grpc_call_start_batch(*call, _ops.ptr, _ops.length, &_tag, null);  
        if(status == GRPC_CALL_OK) {
            import core.time;
            
            writeln("proceeding the cq so we don't fuck up");
            _call.cq.next(d);
        }

        writeln("and we done");

        return status;

    }

    void reset() {
        ops = ops.init;
    }

    this(RemoteCall* call) {
        _call = call;
    }

}
