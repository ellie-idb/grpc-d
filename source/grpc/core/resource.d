module grpc.core.resource;
public import stdx.allocator : theAllocator, make, dispose;

shared struct SharedResource
{
    alias Exception function(shared(void)*) nothrow Release;

    this(shared(void)* ptr, Release release) @trusted nothrow
        in { assert(ptr); } body
    {
        Payload* pay;
        try {
            pay = theAllocator.make!Payload();
        } catch(Exception e) {
            // something must've gone HORRIBLY wrong for this to fail
            assert(0, "should never occur");
        }
        
        pay.refCount = 1;
        pay.handle = cast(void*)ptr;
        pay.release = release;
        
        m_payload = cast(shared(Payload*))pay;
        
    }

    this(this) nothrow
    {
        if (m_payload) {
            incRefCount();
        }
    }

    ~this()
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
            scope(exit) { 
                theAllocator.dispose(cast(Payload*)m_payload);
                m_payload = null;
            }
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
            if (decRefCount() < 1 && m_payload.handle != null) {
                Exception e = m_payload.release(m_payload.handle);
                try {
                    theAllocator.dispose(cast(Payload*)m_payload);
                } catch(Exception e) {
                    assert(0, "should never occur");
                }
                
                m_payload = null;
                return e;
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
