module grpc.common.call;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.tag;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.logger;
import grpc.server;
import grpc.core.resource;
import grpc.common.calldetails : CallDetails;

struct RemoteCall {
@safe:
    private {
        void* allocFake;
        gpr_timespec deadline;
        SharedResource _call;
        CompletionQueue!"Next" _registeredCq;
        CompletionQueue!"Next" _globalCq;
        ByteBuffer _data;
        CallDetails _callDetails;
        MetadataArray _metadataArray;
    }

    @property inout(grpc_call)** handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _call.handle;
    }

    grpc_call_error startBatch(grpc_op[] _ops, ref Tag _tag) @trusted {
        grpc_call_error error = grpc_call_start_batch(*this.handle, _ops.ptr, _ops.length, &_tag, null);

        return error;
    }

    grpc_call_error requestCall(void* _method, ref Tag _tag, ref Server server) @trusted {

        grpc_call_error error;

        synchronized(_registeredCq) { 
            auto method_cq = _registeredCq.ptrNoMutex();
            DEBUG("Got method lock");

            auto global_cq = _globalCq.ptrNoMutex();
            DEBUG("Got global lock");

            auto __call = this.handle();
            DEBUG("Got grpc_call* lock: ", __call);

            auto data = _data.handle;
            DEBUG("Got byte buffer");

            auto metadata = _metadataArray.borrow();
            DEBUG("Got metadata lock");

            auto callDetails = _callDetails.handle;

            error = grpc_server_request_registered_call(server.handle,
                    _method, __call, &deadline, &metadata.metadata,
                    &data, method_cq, global_cq, &_tag);

        }

        DEBUG(*this.handle());

//        error = grpc_server_request_call(server.handle, &__call._call, &callDetails.details, &metadata.metadata, global_cq, global_cq, cast(void*)_tag);
        return error;
    }


    @property inout(ByteBuffer)* data() inout {
        return &_data;
    }

    @property CompletionQueue!"Next" cq() {
        return _registeredCq;
    }

    @property inout(CallDetails)* details() inout {
        return &_callDetails;
    }

    @property inout(MetadataArray)* metadata() inout {
        return &_metadataArray;
    }

    bool kick() @trusted 
    in {
        assert(*this.handle != null);
    }
    do {
        DEBUG("ptr for kick: ", cast(shared(void)*)&this);
        return kick(cast(shared(void)*)&this);
    }

    bool kick(shared(void)* ptr) @trusted 
    in {
        assert(*this.handle != null);
    }
    do {
        if(grpc_call_error error = grpc_call_start_batch(*this.handle, null, 0, cast(void*)ptr, null)) {
            return false;
        }
        return true;
    }

    bool kick(ref Tag _tag) @trusted 
    in {
        assert(*this.handle != null);
    }
    do {
        grpc_op[] ops;
        DEBUG(*this.handle);
        if(grpc_call_error error = grpc_call_start_batch(*this.handle, null, 0, &_tag, null)) {
            return false;
        }

        return true;
    }

    @disable this(this);

    static RemoteCall* opCall(ref CompletionQueue!"Next" globalCq, ref CompletionQueue!"Next" cq) @trusted {
        import core.stdc.string : memset;
        import core.memory;
        void* _ptr = GC.calloc(RemoteCall.sizeof);
        RemoteCall* c = cast(RemoteCall*)_ptr;
        c._data = ByteBuffer();
        c._globalCq = globalCq;
        c._registeredCq = cq;
        c._callDetails = CallDetails();
        c._metadataArray = new MetadataArray();

        GC.addRoot(cast(void*)&c);

        static Exception release(shared(void)* ptr) @trusted nothrow {
            gpr_free(cast(void*)ptr);
            return null;
        }

        if(grpc_call** ptr = cast(grpc_call**)gpr_malloc((grpc_call**).sizeof)) {
            memset(ptr, 0, (grpc_call**).sizeof);
            c._call = SharedResource(cast(shared)ptr, &release);
        }
        else {
            assert("could not alloc smart ptr");
        }

        return c;
    }

    ~this() @trusted {
    }
}


