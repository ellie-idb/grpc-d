module grpc.core.sync.semaphore;
import interop.headers;
import grpc.core.sync.mutex;
import grpc.core.utils;
import grpc.core.resource;

class Semaphore {
@safe @nogc:
    private {
        SharedResource _sema;
    }

    inout(gpr_cv)* handle() inout @trusted nothrow {
        return cast(typeof(return)) _sema.handle;
    }

    void wait(Mutex mu, Duration t) @trusted {
        assert(handle);
        gpr_cv_wait(handle, &mu.mu, t.durtotimespec);
    }

    void signal() @trusted {
        assert(handle);
        gpr_cv_signal(handle);
    }

    void broadcast() @trusted {
        gpr_cv_broadcast(handle);
    }

    this() @trusted {
        gpr_cv* sema;
        if ((sema = cast(gpr_cv*)gpr_zalloc((gpr_cv).sizeof)) != null) {
            static bool release(shared(void)* ptr) @nogc @trusted nothrow {
                gpr_cv_destroy(cast(gpr_cv*)ptr);
                gpr_free(cast(void*)ptr);
                return true;
            }

            gpr_cv_init(sema);
            _sema = SharedResource(cast(shared)sema, &release);
        } else {
            assert(0, "Allocation failed");
        }
    }

    ~this() {
        _sema.forceRelease();
    }
}