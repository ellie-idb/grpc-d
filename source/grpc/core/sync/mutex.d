module grpc.core.sync.mutex;
import interop.headers;
import grpc.core.resource;
import grpc.core.utils;

struct Mutex {
@safe @nogc:
    package {
        gpr_mu mu; 
    }

    void lock() @trusted nothrow shared const {
        gpr_mu_lock(cast(gpr_mu*)&mu);
    }

    void unlock() @trusted nothrow shared const {
        gpr_mu_unlock(cast(gpr_mu*)&mu);
    }

    bool tryLock() @trusted nothrow shared const {
        return gpr_mu_trylock(cast(gpr_mu*)&mu) != 0;
    }

    static Mutex create() @trusted {
        Mutex m = void;
        gpr_mu_init(&m.mu);
        return cast(typeof(return))m;
    }

    @disable this(this);
    @disable this();

    ~this() @trusted {
        if (mu != cast(typeof(mu))gpr_mu.init) {
            gpr_mu_destroy(cast(gpr_mu*)&mu);
        }
    }

}
