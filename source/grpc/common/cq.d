module grpc.common.cq;
import grpc.logger;
import interop.headers;
import std.typecons;
import grpc.core.tag;
import grpc.core;
import grpc.core.mutex;
import grpc.core.resource;
import grpc.core.utils;

//queue ok/ok type
alias NextStatus = Tuple!(bool, bool);


// TODO: add mutexes 

import core.thread;
import std.parallelism;

import std.traits;

struct CompletionQueue(string T) 
    if(T == "Next") 
{
@safe:
    private { 
        GPRMutex mutex;
        SharedResource _cq;
    }

    @property inout(grpc_completion_queue)* handle() inout @trusted pure nothrow {
        return cast(typeof(return)) _cq.handle;
    }

    /* Preserved for compatibility */
    auto ptr(string file = __FILE__) @trusted {
        return handle;
    }

    static if(T == "Pluck") {
        // TODO: add Pluck/Callback types
    }
    static if(T == "Next") {
        grpc_event next(Duration time) @trusted {
            gpr_timespec t = durtotimespec(time);
            grpc_event _evt;

            _evt = grpc_completion_queue_next(handle, t, null);

            return _evt;
        }
    }

    import grpc.server;
    grpc_call_error requestCall(void* method, Tag* tag, Server* _server) @trusted {
        DEBUG!"hmm"();
        auto ctx = &tag.ctx;
        assert(ctx != null, "context null");

        DEBUG!"locking context mutex"();
        ctx.mutex.lock;
        mutex.lock;
        scope(exit) {
            ctx.mutex.unlock;
            mutex.unlock;
            DEBUG!"unlocked context mutex"();
        }
        
        auto server_ptr = _server.handle();
        _server.lock;
        scope(exit) _server.unlock;
        DEBUG!"Got server lock"();

        auto global_cq = _server.masterQueue.ptr(); 
        DEBUG!"Got global cq lock"();

        auto method_cq = handle();
        DEBUG!"Locked self"();

        auto details = ctx.details.handle();
        DEBUG!"Got CallDetails"();

        auto metadata = ctx.metadata.handle();
        DEBUG!"Got metadata lock"();

        auto data = ctx.data.handle();
        DEBUG!"Locked byte buffer"();

        DEBUG!"call: %x"(ctx.call);

        grpc_call_error error = grpc_server_request_registered_call(server_ptr,
                method, ctx.call, &details.deadline, metadata,
                data, method_cq, global_cq, tag);

        DEBUG!"successfully reregistered"();

        return error;

    }


    static CompletionQueue!T opCall() @trusted {
        CompletionQueue!T obj;

        grpc_completion_queue* cq = null;

        static if (T == "Next") {
            cq = grpc_completion_queue_create_for_next(null);
        } else {
        }

        if (cq == null) {
            throw new Exception("CQ creation error");
        }

        static Exception release(shared(void)* ptr) @trusted nothrow {
            grpc_completion_queue_shutdown(cast(grpc_completion_queue*)ptr);
            grpc_completion_queue_destroy(cast(grpc_completion_queue*)ptr);

            return null;
        }

        obj._cq = SharedResource(cast(shared)cq, &release);
        obj.mutex = GPRMutex();

        return obj;
    }

    @disable this(this);

    void shutdown() @trusted {
        mutex.lock;
        scope(exit) mutex.unlock;
        grpc_completion_queue_shutdown(handle);
        INFO!"shutting down CQ";
    }

}

