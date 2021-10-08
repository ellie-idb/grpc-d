module grpc.core.resource;
import core.lifetime;
import interop.headers;
import grpc.core.sync.mutex;
import core.atomic : atomicOp;

struct SharedResource
{
@safe @nogc:
    alias bool function(shared(void)*) nothrow Release;
    static immutable ReleaseException = new Exception("Failed to release resource");

    this(shared(void)* ptr, Release release) @trusted
    {
        assert(ptr);
        m_payload.refCount = 1;
        m_payload.handle = ptr;
        m_payload.release = release;
        mu = cast(shared)Mutex.create();
    }

    this(this) @trusted 
    {
        if (m_payload != shared(Payload).init) {
            incRefCount();
        }
    }

    ~this()
    {
        detach();
    }

    void opAssign(SharedResource rhs) @trusted
    {
        detach();
        m_payload = rhs.m_payload;
        rhs.m_payload = Payload.init;
    }

    bool detach() @trusted
    {
        if (m_payload != shared(Payload).init) {
            scope(exit) {
                m_payload = shared(Payload).init;
            }
            
            if (decRefCount() < 1 && m_payload.handle != null) {
                return m_payload.release(m_payload.handle);
            }
        }
        return false;
    }

    void forceRelease() @trusted
    {
        if (m_payload != shared(Payload).init) {
            scope(exit) {
                m_payload = shared(Payload).init;
            }

            decRefCount();
            if (m_payload.handle != null) {
                scope(exit) m_payload.handle = null;
                if (!m_payload.release(m_payload.handle)) {
                    throw ReleaseException;
                }
            }
        }
    }

    inout(void)* handle() inout @trusted nothrow shared
    {
        mu.lock;
        scope(exit) mu.unlock;

        if (m_payload != shared(Payload).init) {
            return cast(typeof(return)) m_payload.handle;
        } else {
            return null;
        }
    }

    inout(void)* handle() inout @trusted nothrow 
    {
        mu.lock;
        scope(exit) mu.unlock;

        if (m_payload != shared(Payload).init) {
            return cast(typeof(return)) m_payload.handle;
        } else {
            return null;
        }
    }

private:
    void incRefCount() @trusted nothrow
    {
        assert (m_payload != shared(Payload).init && m_payload.refCount > 0);
        atomicOp!"+="(m_payload.refCount, 1);
    }

    int decRefCount() @trusted nothrow
    {
        assert (m_payload != shared(Payload).init && m_payload.refCount > 0);
        return atomicOp!"-="(m_payload.refCount, 1);
    }

    struct Payload
    {
        int refCount;
        void* handle;
        Release release;
    }
    shared(Mutex) mu;
    shared(Payload) m_payload;

    invariant()
    {
        () @trusted {
            assert (m_payload == shared(Payload).init ||
                (m_payload.refCount > 0 && m_payload.release !is null), "failed invariant");
        } ();
    }
}
