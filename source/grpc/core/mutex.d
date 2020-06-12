module grpc.core.mutex;
import interop.headers;
import grpc.core.resource;
import grpc.core.utils;
import core.memory : GC;

struct GPRMutex {
@safe:
    private {
        SharedResource _mutex;
    }

    @property inout(gpr_mu)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _mutex.handle;
    }

    void lock() @trusted {
        gpr_mu_lock(handle);
    }

    void unlock() @trusted {
        gpr_mu_unlock(handle);
    }

    bool tryLock() @trusted {
        return gpr_mu_trylock(handle) != 0;
    }

    static GPRMutex opCall() @trusted {
        GPRMutex obj;
        gpr_mu* mutex;
        if ((mutex = cast(gpr_mu*)gpr_zalloc((gpr_mu).sizeof)) != null) {
            doNotMoveObject(mutex, (gpr_mu).sizeof);
            static Exception release(shared(void)* ptr) @trusted nothrow {
                gpr_mu_destroy(cast(gpr_mu*)ptr);
                gpr_free(cast(void*)ptr);
                okToMoveObject(cast(void*)ptr);
                assert(0);
//                return null;
            }

            gpr_mu_init(mutex);
            obj._mutex = SharedResource(cast(shared)mutex, &release);
        } else {
            throw new Exception("failed to allocate memory");
        }

        return obj;
    }

    @disable this(this);

}
