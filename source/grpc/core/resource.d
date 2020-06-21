module grpc.core.resource;


shared struct SharedResource
{
@safe:
    alias Exception function(shared(void)*) nothrow Release;

    this(shared(void)* ptr, Release release) nothrow
        in { assert(ptr); } body
    {
        m_payload = new shared(Payload)(1, ptr, release);
    }

    this(this) nothrow
    {
        if (m_payload) {
            incRefCount();
        }
    }

    ~this() nothrow
    {
        nothrowDetach();
    }

    void opAssign(SharedResource rhs)
    {
        detach();
        m_payload = rhs.m_payload;
        rhs.m_payload = null;

    }

    void detach()
    {
        if (auto ex = nothrowDetach()) throw ex;
    }

    void forceRelease() @system
    {
        if (m_payload) {
            scope(exit) m_payload = null;
            decRefCount();
            if (m_payload.handle != null) {
                scope(exit) m_payload.handle = null;
                if (auto ex = m_payload.release(m_payload.handle)) {
                    throw ex;
                }
            }
        }
    }

    @property inout(shared(void))* handle() inout pure nothrow
    {
        if (m_payload) {
            return m_payload.handle;
        } else {
            return null;
        }
    }

private:
    void incRefCount() @trusted nothrow
    {
        assert (m_payload !is null && m_payload.refCount > 0);
        import core.atomic: atomicOp;
        atomicOp!"+="(m_payload.refCount, 1);
    }

    int decRefCount() @trusted nothrow
    {
        assert (m_payload !is null && m_payload.refCount > 0);
        import core.atomic: atomicOp;
        return atomicOp!"-="(m_payload.refCount, 1);
    }

    Exception nothrowDetach() @trusted nothrow
        out { assert (m_payload is null); }
        body
    {
        if (m_payload) {
            scope(exit) m_payload = null;
            if (decRefCount() < 1 && m_payload.handle != null) {
                return m_payload.release(m_payload.handle);
            }
        }
        return null;
    }

    struct Payload
    {
        int refCount;
        void* handle;
        Release release;
    }
    shared(Payload)* m_payload;

    invariant()
    {
        assert (m_payload is null ||
            (m_payload.refCount > 0 && m_payload.release !is null));
    }
}
