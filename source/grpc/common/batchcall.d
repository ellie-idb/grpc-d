module grpc.common.batchcall;
import std.exception;
import interop.headers;
import automem;
import grpc.common.call;
import grpc.core.utils;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.logger;
import std.exception : enforce;
import core.lifetime;

interface RemoteOp {
    grpc_op_type type();
    grpc_op value();
}

class SendInitialMetadataOp : RemoteOp {
    private {
        MetadataArray array;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_INITIAL_METADATA;
    }

    grpc_op value() {
        grpc_op ret;

        ret.op = type();
        ret.data.send_initial_metadata.metadata = array.handle.metadata;
        ret.data.send_initial_metadata.count = array.count;

        return ret;
    }
    
    this() {
        array = MetadataArray.create();
    }
}

class SendMessageOp : RemoteOp {
    private {
        ByteBuffer _buf;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_MESSAGE;
    }

    grpc_op value() {
        grpc_op ret;
        enforce(_buf.valid, "expected byte buffer to be valid");
        ret.op = type();
        ret.data.send_message.send_message = _buf.handle;
        return ret;
    }

    this(ref ubyte[] message) {
        _buf = ByteBuffer.create(message);
    }
}

class SendStatusFromServerOp : RemoteOp {
    private {
        MetadataArray _trailing_metadata;
        grpc_status_code _status;
        grpc_slice _details;
    }

    grpc_op_type type() {
        return GRPC_OP_SEND_STATUS_FROM_SERVER;
    }

    grpc_op value() {
        grpc_op ret;
        ret.op = type();
        ret.data.send_status_from_server.status_details = &_details;
        ret.data.send_status_from_server.status = _status;
        ret.data.send_status_from_server.trailing_metadata_count = _trailing_metadata.count;
        ret.data.send_status_from_server.trailing_metadata = _trailing_metadata.handle.metadata;
        
        return ret;
    }
    
    void free() {
        grpc_slice_unref(_details);
    }
        
    this(grpc_status_code code, string details) {
        _details = string_to_slice(details);
        _status = code;
        _trailing_metadata = MetadataArray.create();
    }
    
    this() {
        _details = grpc_empty_slice();
        _status = cast(grpc_status_code)0;
        _trailing_metadata = MetadataArray.create();
    }

    ~this() {
        free;
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
        grpc_op ret;
        ret.op = type();
        ret.data.recv_initial_metadata.recv_initial_metadata = _metadata.handle;

        return ret;
    }

    this() {
        _metadata = MetadataArray.create();
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
        grpc_op ret;
        ret.op = type();
        ret.data.recv_message.recv_message = _buf.safeHandle;
        return ret;
    }
    
    void free() {
    }
    
    this(ByteBuffer* buf) {
        _buf = buf;
    }
    
    ~this() {
        free;
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
        shared(int) _cancelled;
    }

    int cancelled() {
        return _cancelled;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_CLOSE_ON_SERVER;
    }

    grpc_op value() {
        grpc_op ret;
        ret.op = type();
        ret.data.recv_close_on_server.cancelled = cast(int*)&_cancelled;

        return ret;
    }

    this() {
    }
}

class BatchCall {
    private {
        // At one time, there should *realistically* be no more then 128 queued operations?
        enum MAX_REMOTE_OPS = 128;
        RemoteOp[MAX_REMOTE_OPS] ops;
        size_t opCount;
    }

    void addOp(RemoteOp _op) {
        import std.algorithm.mutation;
        assert(opCount < MAX_REMOTE_OPS, "Too many operations submitted");
        ops[opCount++] = _op;
    }

    static grpc_call_error kick(CompletionQueue!"Next" cq, Tag* _tag, Duration d = 1.seconds) {
        assert(*_tag.ctx.call, "call should never be null");
        DEBUG!"kicking cq with tag (%x)"(_tag);
        auto status = grpc_call_start_batch(*_tag.ctx.call, null, 0, _tag, null);
        if (status == GRPC_CALL_OK) {
            import core.time;
            cq.next(d);
        }
        return status;
    }
    
    static grpc_call_error runSingleOp(RemoteOp _op, CompletionQueue!"Next" cq, Tag* _tag, Duration d = 1.seconds) {
        assert(*_tag.ctx.call, "call should never be null");
    
        if (callOverDeadline(_tag)) {
            DEBUG!"call exceeded deadline (initial check)";
            return GRPC_CALL_ERROR;
        }

        grpc_op[1] op;
        op[0] = _op.value();
        DEBUG!"starting batch on tag (%x, ops: %d)"(_tag, 1);
        grpc_call_error status = grpc_call_start_batch(*_tag.ctx.call, op.ptr, 1, _tag, null);  
        grpc_event evt = cq.next(d); 
        while (evt.type != GRPC_OP_COMPLETE) {
            if (callOverDeadline(_tag)) {
                DEBUG!"call exceeded deadline, cancel batch";
                grpc_call_cancel(*_tag.ctx.call, null);
                break;
            }

            if (evt.type == GRPC_QUEUE_SHUTDOWN) {
                break;
            }

            if (status == GRPC_CALL_OK) {
                DEBUG!"waiting for op to complete";
            } else if (status == GRPC_CALL_ERROR_TOO_MANY_OPERATIONS) {
                grpc_call_cancel(*_tag.ctx.call, null);
                break;
            } else {
                ERROR!"STATUS: %s"(status);
                break;
            }
            evt = cq.next(d);
            DEBUG!"finished batch on tag: %x"(_tag);
       }

        destroy(op);
        return status;
    }
        
    import grpc.core.tag;
    import core.time;
    import grpc.common.cq;

    /* requires the caller to have a lock on the CallContext */
    // For tuning, you may assume that changing the duration MAY be optimal, however
    // if you reduce the duration down to 1 millisecond, if there is ever a collection cycle,
    // the library can't adequately catch the event (and may result in odd cancellations)

    grpc_call_error run(CompletionQueue!"Next" cq, Tag* _tag, Duration d = 1.seconds) { 
        assert(_tag != null, "tag should never be null");

        if (callOverDeadline(_tag)) {
            DEBUG!"call over deadline, refusing to process";
            return GRPC_CALL_ERROR;
        }

        grpc_op[MAX_REMOTE_OPS] _ops;
        size_t convOpCount = 0;

        for(int i = 0; i < opCount; i++) {
            assert(convOpCount < MAX_REMOTE_OPS, "Too many operations submitted");
            _ops[convOpCount++] = ops[i].value();
        }

        DEBUG!"starting batch on tag (%x, ops: %d)"(_tag, convOpCount);
        grpc_call_error status = grpc_call_start_batch(*_tag.ctx.call, _ops.ptr, convOpCount, _tag, null);  
        grpc_event evt = cq.next(d); 
        while (evt.type != GRPC_OP_COMPLETE) {
            import core.time;
            if (callOverDeadline(_tag)) {
                DEBUG!"call over deadline";
                grpc_call_cancel(*_tag.ctx.call, null);
                break;
            }

            if (evt.type == GRPC_QUEUE_SHUTDOWN) {
                break;
            }

            if (status == GRPC_CALL_ERROR_TOO_MANY_OPERATIONS) {
                grpc_call_cancel(*_tag.ctx.call, null);
                break;
            } else if (status != GRPC_CALL_OK) {
                ERROR!"STATUS: %s"(status);
                break;
            }
            evt = cq.next(d);
            DEBUG!"finished batch on tag: %x"(_tag);
       }
        
        reset;

        return status;
    }
    
    void reset() {
        DEBUG!"Resetting operations (length: %d)"(ops.length);
        for(int i = 0; i < opCount; i++) {
            if (ops[i] is null) continue;
            
            Object obj = cast(Object)ops[i];
            auto type = typeid(obj);
            // Workaround compiler bug where classinfo fails to retrieve the actual type 
            // of an object (and the subsequent size of it)
            static foreach(sym; __traits(allMembers, mixin(__MODULE__))) {{
                static if(sym[$ - 2 .. $] == "Op" && sym != "RemoteOp") {
                    // pragma(msg, sym);
                    mixin("alias T = " ~ sym ~ ";");
                    if (obj !is null && type == typeid(T)) {
                        T realObj = cast(T)obj;
                        static if (__traits(compiles, realObj.free)) {
                            realObj.free;
                        }
                        DEBUG!"Freeing %s (%x) (index %d/%d)"(sym, cast(void*)realObj, i, ops.length);
                        destroy(realObj);
                        DEBUG!"OK!";
                        obj = null;
                        ops[i] = null;
                    }
                }
            }}
        }
    }
}
