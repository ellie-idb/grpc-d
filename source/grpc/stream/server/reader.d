module grpc.stream.server.reader;
import grpc.core.tag;
import grpc.core.grpc_preproc;
import grpc.common.cq; 

class ServerReader(T) {
    private {
        CompletionQueue!"Pluck" _cq;
        grpc_call* _call;
        Tag _tag;
        grpc_byte_buffer* _bytebuffer;
    }

    bool read(ref T obj) {
        return true;
    }

    this(CompletionQueue!"Pluck" cq, grpc_call* call, ref Tag tag, grpc_byte_buffer* bytebuffer) {
        

    }

    ~this() {


    }
}
