module grpc.core.batchcall;
import grpc.core.grpc_preproc;

class BatchCall {
    private {
        grpc_op[] calls;

        bool sanityCheck() {
            int[int] count;
            foreach(call; calls) {
                count[call.op]++;
                if(count[call.op] > 1) {
                    return false;
                }
            }
            return true;
        }
    }

    grpc_call_error run() {
        if(sanityCheck()) {
            return GRPC_CALL_OK;
        }
        else {
            return GRPC_CALL_ERROR;
        }
    }

    void reset() {
        calls = calls.init;
    }

    this() {

    }

}
