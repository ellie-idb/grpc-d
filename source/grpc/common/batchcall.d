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
import stdx.allocator : theAllocator, make, dispose;

interface RemoteOp {
    grpc_op_type type();
    grpc_op value();
    void free();
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
        ret.data.send_initial_metadata.metadata = array.data;
        ret.data.send_initial_metadata.count = array.count;

        return ret;
    }
    
    void free() {
        theAllocator.dispose(array);
    }

    this() {
        array = MetadataArray();
    }
    
    static SendInitialMetadataOp opCall() @trusted {
        SendInitialMetadataOp obj = theAllocator.make!SendInitialMetadataOp();
        return obj;
    }
    
    ~this() {
        free;
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
        ret.data.send_message.send_message = _buf.unsafeHandle;
        return ret;
    }

    this(ref ubyte[] message) {
        _buf = theAllocator.make!ByteBuffer(message);
    }
    
    void free() {
        theAllocator.dispose(_buf);
    }
    
    static SendMessageOp opCall(ref ubyte[] message) @trusted {
        SendMessageOp obj = theAllocator.make!SendMessageOp(message);
        return obj;
    }

    ~this() @trusted {
        free;
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
        ret.data.send_status_from_server.trailing_metadata_count =  _trailing_metadata.count;
        if (_trailing_metadata.count != 0) {
            ret.data.send_status_from_server.trailing_metadata = _trailing_metadata.data;
        }

        return ret;
    }
    
    void free() {
        grpc_slice_unref(_details);
        
        if (_trailing_metadata !is null) {
            theAllocator.dispose(_trailing_metadata);
            _trailing_metadata = null;
        }
    }
        
    this(grpc_status_code code, string details) {
        _trailing_metadata = MetadataArray();
        _details = string_to_slice(details.dup);
        _status = code;
    }
    
    static SendStatusFromServerOp opCall(grpc_status_code code, string details) @trusted {
        SendStatusFromServerOp obj = theAllocator.make!SendStatusFromServerOp(code, details);
        return obj;
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

    void free() {
        theAllocator.dispose(_metadata);
    }
    
    this() {
        _metadata = MetadataArray();
    }
    
    static RecvInitialMetadataOp opCall() @trusted {
        RecvInitialMetadataOp obj = theAllocator.make!RecvInitialMetadataOp();
        return obj;
    }
    
    ~this() {
        free;
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
        ret.data.recv_message.recv_message = _buf.handle;
        return ret;
    }
    
    void free() {
    }
    
    this(ref ByteBuffer buf) {
        _buf = &buf;
    }
    
    static RecvMessageOp opCall(ref ByteBuffer buf) @trusted {
        RecvMessageOp obj = theAllocator.make!RecvMessageOp(buf);
        return obj;
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
        int _cancelled = 0;
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
        ret.data.recv_close_on_server.cancelled = &_cancelled;

        return ret;
    }

    void free() {
    }
    
    this() {
    }
    
    ~this() {
        free;
    }
    
    static RecvCloseOnServerOp opCall() @trusted {
        RecvCloseOnServerOp obj = theAllocator.make!RecvCloseOnServerOp();
        return obj;
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
    // For tuning, you may assume that changing the duration MAY be optimal, however
    // if you reduce the duration down to 1 millisecond, if there is ever a collection cycle,
    // the library can't adequately catch the event (and may result in odd cancellations)
    
    grpc_call_error run(CompletionQueue!"Next" cq, Tag* _tag, Duration d = 1.seconds) { 
        assert(sanityCheck(), "failed sanity check");
        assert(_tag != null, "tag should never be null");
        Vector!(grpc_op) _ops;

        foreach(op; ops) {
            _ops ~= op.value();
        }

        DEBUG!"starting batch on tag (%x, ops: %d)"(_tag, _ops.length);
        auto status = grpc_call_start_batch(*_tag.ctx.call, _ops.ptr, _ops.length, _tag, null);  
        if(status == GRPC_CALL_OK) {
            import core.time;
            cq.next(d);
            DEBUG!"finished batch on tag: %x"(_tag);
        } else {
            ERROR!"STATUS: %s"(status);
        }
        
        _ops.free;
        reset;

        return status;
    }
    
    void reset() {
        for(int i = 0; i < ops.length; i++) {
            RemoteOp op = ops[i];
            Object obj = cast(Object)op;
            static foreach(sym; __traits(allMembers, mixin(__MODULE__))) {
                static if(sym[$ - 2 .. $] == "Op" && sym != "RemoteOp") {{
                    mixin("alias T = " ~ sym ~ ";");
                    if (obj !is null && typeid(obj) == typeid(T)) {
                        T realObj = cast(T)obj;
                        INFO!"Freeing %s"(sym);
                        goto end;
                    }
                }}
            }
end:
            theAllocator.dispose(op);
        }
        
        ops.length = 0;
    }

    this() {
    }
    
    static BatchCall opCall() @trusted {
        BatchCall obj = theAllocator.make!BatchCall();
        return obj;
    }

    ~this() {
        reset;
    }
}
