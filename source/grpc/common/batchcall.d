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
import std.experimental.allocator : theAllocator, make, dispose;

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
    
    void free() {
        theAllocator.dispose(array);
        array = null;
    }

    this() {
        array = theAllocator.make!MetadataArray();
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
        _buf = null;
    }

    ~this() {
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
        ret.data.send_status_from_server.trailing_metadata_count = _trailing_metadata.count;
        ret.data.send_status_from_server.trailing_metadata = _trailing_metadata.handle.metadata;
        
        return ret;
    }
    
    void free() {
        theAllocator.dispose(this._trailing_metadata);
        grpc_slice_unref(_details);
    }
        
    this(grpc_status_code code, string details) {
        _details = string_to_slice(details);
        _status = code;
        _trailing_metadata = theAllocator.make!MetadataArray();
    }
    
    this() {
        _details = grpc_empty_slice();
        _status = cast(grpc_status_code)0;
        _trailing_metadata = theAllocator.make!MetadataArray();
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
        _metadata = theAllocator.make!MetadataArray();
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
        int* _cancelled;
    }

    int cancelled() {
        return *_cancelled;
    }

    grpc_op_type type() {
        return GRPC_OP_RECV_CLOSE_ON_SERVER;
    }

    grpc_op value() {
        grpc_op ret;
        ret.op = type();
        ret.data.recv_close_on_server.cancelled = _cancelled;

        return ret;
    }

    void free() {
        theAllocator.dispose(_cancelled);
    }
    
    this() {
        _cancelled = theAllocator.make!int(0);
    }
    
    ~this() {  
        free;
    }
}

class BatchCall {
    private {
        Vector!(RemoteOp) ops;
    }

    void addOp(RemoteOp _op) {
        import std.algorithm.mutation;
        ops ~= _op;
    }
    
    static grpc_call_error runSingleOp(RemoteOp _op, CompletionQueue!"Next" cq, Tag* _tag, Duration d = 1.seconds) {
        assert(*_tag.ctx.call, "call should never be null");
    
        grpc_op[1] op;
        op[0] = _op.value();
        DEBUG!"starting batch on tag (%x, ops: %d)"(_tag, 1);
        auto status = grpc_call_start_batch(*_tag.ctx.call, op.ptr, 1, _tag, null);  
        if(status == GRPC_CALL_OK) {
            import core.time;
            cq.next(d);
            DEBUG!"finished batch on tag: %x"(_tag);
        } else {
            ERROR!"STATUS: %s"(status);
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
        //assert(sanityCheck(), "failed sanity check");
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
        
        reset;

        return status;
    }
    
    void reset() {
        DEBUG!"Resetting operations (length: %d)"(ops.length);
        for(int i = 0; i < ops.length; i++) {
            if (ops[i] is null) continue;
            
            Object obj = cast(Object)ops[i];
            auto type = typeid(obj);
            static foreach(sym; __traits(allMembers, mixin(__MODULE__))) {{
                static if(sym[$ - 2 .. $] == "Op" && sym != "RemoteOp") {
                    pragma(msg, sym);
                    mixin("alias T = " ~ sym ~ ";");
                    if (obj !is null && type == typeid(T)) {
                        T realObj = cast(T)obj;
                        realObj.free;
                        DEBUG!"Freeing %s (%x) (index %d/%d)"(sym, cast(void*)realObj, i, ops.length);
                        theAllocator.dispose(realObj);
                        DEBUG!"OK!";
                        obj = null;
                    }
                }
            }}
        }
        
        ops.free;
    }

    this() {
        ops = Vector!(RemoteOp)();
    }

    ~this() {
    }
}
