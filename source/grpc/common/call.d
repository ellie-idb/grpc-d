module grpc.common.call;
import grpc.logger;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.resource;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.core.mutex;
import core.memory : GC;

struct CallContext {
@safe:
    shared GPRMutex mutex;
    grpc_call** call;
    CallDetails details;
    MetadataArray metadata;
    ByteBuffer data;

    static CallContext opCall() @trusted {
        CallContext obj;
        obj.mutex = GPRMutex();
        obj.details = CallDetails();
        obj.metadata = MetadataArray();
        obj.data = ByteBuffer();
        obj.call = cast(grpc_call**)gpr_zalloc((grpc_call**).sizeof); 

        return obj;
    }

    ~this() @trusted {
        gpr_free(cast(void*)call);
        destroy(details);
        destroy(metadata);
        destroy(data);
        theAllocator.dispose(data);
        theAllocator.dispose(mutex);
    }

    @disable this(this);
}

struct CallDetails {
@safe:
    private {
        shared GPRMutex mutex;
        SharedResource _details;
    }

    @property inout(grpc_call_details)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _details.handle;
    }

    @property string method() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
        return slice_to_string(handle.method); 
    }

    @property string host() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
        return slice_to_string(handle.host);
    }

    @property uint flags() {
        mutex.lock;
        scope(exit) mutex.unlock;
        uint flags = handle.flags;
        return flags;
    }

    @property Duration deadline() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
        Duration d = timespectodur(handle.deadline);
        return d;
    }

    static CallDetails opCall() @trusted {
        CallDetails obj;
        obj.mutex = GPRMutex();
        grpc_call_details* details;

        if ((details = cast(grpc_call_details*)gpr_zalloc((grpc_call_details).sizeof)) != null) {
            static Exception release(shared(void)* ptr) @trusted nothrow {
                grpc_call_details_destroy(cast(grpc_call_details*)ptr);
                gpr_free(cast(void*)ptr);
                return null;
            }
            
            grpc_call_details_init(details);
            obj._details = SharedResource(cast(shared)details, &release);
        } else {
            throw new Exception("memory allocation failed");
        }

        return obj;
    }

    ~this() @trusted {
        theAllocator.dispose(mutex);
        destroy(_details);
    }

    @disable this(this);
}

// since we handle the memory for the CQ tags manually (and since there should only ever be very few tags)
// which actually exist, this should be never cleaned up by the garbage collector as it contains VERY important
// things

@nogc struct Tag {
@safe:
    void* method;
    string methodName;
    ubyte[16] metadata;
    CallContext ctx;

    static Tag* opCall() @trusted {
        Tag* obj = cast(Tag*)gpr_zalloc((Tag).sizeof);
        DEBUG!"new tag created at: %x size: %d"(obj, (Tag).sizeof);
        assert(obj != null, "memory allocation fail");
        doNotMoveObject(obj, (Tag).sizeof);
        obj.ctx = CallContext();
        return obj;
    }
    
    static void free(Tag* tag) @trusted {
        okToMoveObject(tag);
        gpr_free(tag);
    }

    ~this() {
        assert(0); // the tag should NEVER have it's destructor called, you MUST call free on it
    }


    @disable this(this);
}
