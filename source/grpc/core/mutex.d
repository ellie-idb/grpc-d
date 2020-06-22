module grpc.core.mutex;
import interop.headers;
import grpc.core.resource;
import grpc.core.utils;
import core.memory : GC;
import stdx.allocator : theAllocator, make, dispose;

class GPRMutex {
    shared {
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
    }

    static shared(GPRMutex) opCall() @trusted {
        GPRMutex o = theAllocator.make!GPRMutex();
        return cast(shared(GPRMutex))o;
    }

    this() {
        gpr_mu* mutex;
        if ((mutex = cast(gpr_mu*)gpr_zalloc((gpr_mu).sizeof)) != null) {
            static Exception release(shared(void)* ptr) @trusted nothrow {
                gpr_mu_destroy(cast(gpr_mu*)ptr);
                gpr_free(cast(void*)ptr);
                return null;
            }

            gpr_mu_init(mutex);
            _mutex = SharedResource(cast(shared)mutex, &release);
        } else {
            throw new Exception("failed to allocate memory");
        }
    }
    
    ~this() {
        _mutex.forceRelease();
        destroy(_mutex);
    }

}
