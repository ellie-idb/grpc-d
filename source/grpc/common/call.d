module grpc.common.call;
import interop.headers;
import grpc.common.cq;
import fearless;
import grpc.core.utils;
import grpc.core.tag;
import grpc.common.metadata;
import grpc.common.byte_buffer;
import grpc.server : ServerPtr;

struct CallWrapper {
    alias _call this;
    grpc_call* _call;
}

struct CallDetailsWrapper {
    alias details this;
    grpc_call_details details;
}

class CallDetails {
    private {
        Exclusive!CallDetailsWrapper* _details;
    }

    auto borrow() {
        return _details.lock();
    }

    @property string method() {
        auto details = _details.lock();
        return slice_to_string(details.method); 
    }

    @property string host() {
        auto details = _details.lock();
        return slice_to_string(details.host);
    }

    @property uint flags() {
        auto details = _details.lock();
        uint flags = details.flags;
        return flags;
    }

    @property Duration deadline() {
        auto details = _details.lock();
        Duration d = timespectodur(details.deadline);
        return d;
    }

    this() {
        grpc_call_details __details;
        grpc_call_details_init(&__details);
        _details = new Exclusive!CallDetailsWrapper(__details);
    }

    ~this() {
        auto details = _details.lock();
        grpc_call_details_destroy(&details.details);
    }

    package this(ref grpc_call_details details) {
        _details = new Exclusive!CallDetailsWrapper(details);
    }
}

class RemoteCall {
    private {
        gpr_timespec deadline;
        Exclusive!CallWrapper* _call;
        CompletionQueue!"Pluck" _registeredCq;
        CompletionQueue!"Next" _globalCq;
        ByteBuffer _data;
        CallDetails _callDetails;
        MetadataArray _metadataArray;
    }

    auto borrow() {
        return _call.lock();
    }

    grpc_call_error requestGenericCall(ref Tag _tag, Exclusive!ServerPtr* server_) {
        import std.stdio;
        auto server_ptr = server_.lock();
        debug writeln("Got server lock");

        auto method_cq = _registeredCq.ptr();
        debug writeln("Got method lock");

        debug writeln("Attempting to lock global");
        auto global_cq = _globalCq.ptr();

        debug writeln("Got global lock");

        grpc_call** call;
        {
            auto __call = _call.lock();
            call = &__call._call;
        }
        debug writeln("Got grpc_call* lock");

        auto data = _data.borrow();
        debug writeln("Got byte buffer");

        auto callDetails = _callDetails.borrow();
        debug writeln("Got call data lock");

        auto metadata = _metadataArray.borrow();
        debug writeln("Got metadata lock");

        debug writeln(_tag.metadata);

        debug writeln("Registering generic call");
        return grpc_server_request_call(server_ptr, call, &callDetails.details, &metadata.metadata, global_cq, global_cq, cast(void*)_tag);
    }


    grpc_call_error requestCall(void* _method, ref Tag _tag, Exclusive!ServerPtr* server_) {
        import std.stdio;
        auto server_ptr = server_.lock();
        debug writeln("Got server lock");

        auto method_cq = _registeredCq.ptr();
        debug writeln("Got method lock");

        debug writeln("Attempting to lock global");
        auto global_cq = _globalCq.ptr();

        debug writeln("Got global lock");

        auto __call = _call.lock();
        debug writeln("Got grpc_call* lock");

        auto data = _data.borrow();
        debug writeln("Got byte buffer");

        auto callDetails = _callDetails.borrow();
        debug writeln("Got call data lock");

        auto metadata = _metadataArray.borrow();
        debug writeln("Got metadata lock");

        debug writeln(_tag.metadata);

        debug writeln("Registering..");

        grpc_call_error error = grpc_server_request_registered_call(server_ptr,
                cast(void*)_method, &__call._call, &deadline, &metadata.metadata,
                &data._buf, method_cq, global_cq, &_tag);


        return error;
    }

    @property ByteBuffer data() {
        return _data;
    }

    @property CompletionQueue!"Pluck" cq() {
        return _registeredCq;
    }

    @property CallDetails details() {
        return _callDetails;
    }

    @property MetadataArray metadata() {
        return _metadataArray;
    }

    this(CompletionQueue!"Next" globalCq, CompletionQueue!"Pluck" cq) {
        _data = new ByteBuffer(); 
        _globalCq = globalCq;
        _registeredCq = cq;

        _call = new Exclusive!CallWrapper(cast(grpc_call*)0);
        _callDetails = new CallDetails();
        _metadataArray = new MetadataArray();
    }

    ~this() {

    }
}


