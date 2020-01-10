module grpc.common.calldetails;
import interop.headers;
import grpc.core.resource : SharedResource;
import core.time : Duration;
import grpc.core.utils : timespectodur, slice_to_string;


struct CallDetails {
@safe:
    private {
        SharedResource _details;
    }

    @property inout(grpc_call_details)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _details.handle;
    }

    @property string method() 
    in {
        assert(this.handle != null);
    }
    do {
        return slice_to_string(this.handle.method); 
    }

    @property string host() 
    in {
        assert(this.handle != null);
    } 
    do {
        return slice_to_string(this.handle.host);
    }

    @property uint flags() const pure 
    in {
        assert(this.handle != null);
    }
    do {
        uint flags = this.handle.flags;
        return flags;
    }

    @property Duration deadline() const nothrow
    in {
        assert(this.handle != null);
    }
    do {
        Duration d = timespectodur(this.handle.deadline);
        return d;
    }

    static CallDetails opCall() @trusted {
        grpc_call_details* __details = cast(grpc_call_details*)gpr_malloc(grpc_call_details.sizeof);
        import core.stdc.string : memset;
        memset(__details, 0, grpc_call_details.sizeof);
        grpc_call_details_init(__details);

        CallDetails d;
        static Exception release(shared(void)* ptr) @trusted nothrow
        {
            grpc_call_details_destroy(cast(grpc_call_details*)ptr);

            gpr_free(cast(void*)ptr);
            return null;
        }

        d._details = SharedResource(cast(shared)__details, &release);

        return d;
    }
        
    @disable this(this);

    ~this() {
    }
}
