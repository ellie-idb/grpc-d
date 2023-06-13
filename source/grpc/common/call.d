module grpc.common.call;
import grpc.logger;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.resource;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.core.sync.mutex;
import core.memory : GC;
import core.lifetime;

struct CallContext {
@safe @nogc:
    shared(Mutex) mutex;
    grpc_call** call;
    CallDetails details;
    MetadataArray metadata;
    ByteBuffer data;
    MonoTime timestamp;

    static CallContext create() @trusted {
        auto call = cast(grpc_call**)gpr_zalloc((grpc_call**).sizeof); 
        return CallContext(cast(shared)Mutex.create(),
                           call,
                           CallDetails.create(),
                           MetadataArray.create(),
                           ByteBuffer.create());
    }

    @disable this(this);

    ~this() @trusted {
        destroy(data);
        gpr_free(cast(void*)call);
    }
}

struct CallDetails {
@safe @nogc:
    private {
        shared(Mutex) mutex;
        SharedResource _details;
    }

    inout(grpc_call_details)* handle() inout @trusted nothrow {
        return cast(typeof(return)) _details.handle;
    }

    @property string method() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
	string r = slice_to_string(handle.method); 
        return r;
    }

    @property string host() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
	string r = slice_to_string(handle.host);
        return r;
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

    static CallDetails create() @trusted {
        grpc_call_details* details;

        if ((details = cast(grpc_call_details*)gpr_zalloc((grpc_call_details).sizeof)) != null) {
            static bool release(shared(void)* ptr) @trusted nothrow {
                grpc_call_details_destroy(cast(grpc_call_details*)ptr);
                gpr_free(cast(void*)ptr);
                return true;
            }
            
            grpc_call_details_init(details);
            CallDetails obj = CallDetails(cast(shared)Mutex.create(), SharedResource(cast(shared)details, &release));
            return obj;
        } else {
            assert(0, "memory allocation failed");
        }

    }

    ~this() @trusted {
        destroy(_details);
    }


    @disable this(this);
}

// since we handle the memory for the CQ tags manually (and since there should only ever be very few tags)
// which actually exist, this should be never cleaned up by the garbage collector as it contains VERY important
// things

struct Tag {
@safe @nogc:
    void* method;
    string methodName;
    ubyte[16] metadata;
    CallContext ctx;

    static Tag* opCall() @trusted {
        Tag* obj = cast(Tag*)gpr_zalloc((Tag).sizeof);
        DEBUG!"new tag created at: %x size: %d"(obj, (Tag).sizeof);
        assert(obj != null, "memory allocation fail");
        obj.ctx = CallContext.create();
        return obj;
    }
    
    static void free(Tag* tag) @trusted {
        destroy(tag.ctx);
        gpr_free(tag);
    }

    ~this() {
        assert(0); // the tag should NEVER have it's destructor called, you MUST call free on it
    }


    @disable this(this);
}
