module grpc.common.cq;
import interop.headers;
import std.typecons;
import grpc.core.tag;
import fearless;
public import core.time;
public import grpc.core.utils;
import grpc.logger;

//queue ok/ok type
alias NextStatus = Tuple!(bool, bool);


// TODO: add mutexes 

import core.thread;
import std.parallelism;

grpc_event getNext(Exclusive!CompletionQueuePtr* cq, gpr_timespec _dead) {
    grpc_event t_;

    grpc_completion_queue* ptr;
    { 
        auto _ptr = cq.lock();
        ptr = _ptr.cq;
    }

    t_ = grpc_completion_queue_next(ptr, _dead, null);
    return t_;
}

grpc_event getTagNext(bool* started, Exclusive!CompletionQueuePtr* cq, void* tag, gpr_timespec _dead) {
    *started = true;

    grpc_completion_queue* ptr;
    { 
        auto _ptr = cq.lock();
        ptr = _ptr.cq;
    }

    grpc_event t = grpc_completion_queue_pluck(ptr, tag, _dead, null);
    return t;
}

import std.traits;

struct CompletionQueuePtr {
    grpc_completion_queue *cq;
    alias cq this;
}

class CompletionQueue(string T) 
    if(T == "Next" || T == "Pluck" || T == "Callback") 
{
    private { 
        TaskPool asyncAwait;
        Exclusive!CompletionQueuePtr* _cq;

        grpc_completion_queue* __cq;

        mixin template ptrNoLock() {
            grpc_completion_queue* cq = (){ return _cq.lock().cq; }();
        }


    }

    bool locked() {
        return _cq.isLocked;
    }

    auto ptr(string file = __FILE__) {
        import std.stdio;
        return _cq.lock();
    }

    grpc_completion_queue* ptrNoMutex() {
        return __cq;
    }



    static if(T == "Pluck") {
        auto next(ref Tag tag, Duration time) {
            auto evt = async!(() {
                gpr_timespec t = durtotimespec(time);
                auto cq = _cq.lock();
                _evt = grpc_completion_queue_pluck(cq, &tag, t, null); 

            });

            return evt;
        }

        auto asyncNext(ref Tag tag, Duration time) {
            gpr_timespec deadline = durtotimespec(time);

            bool started = false;

            auto task = task!getTagNext(&started, _cq, &tag, deadline); 
            asyncAwait.put(task);

            while(!started) {

            }
            return task;
        }

    }
    static if(T == "Next" || T == "Callback") {
        auto next(Duration time) {
            gpr_timespec deadline = durtotimespec(time);
            auto evt = task!getNext(_cq, deadline); 
            evt.executeInNewThread();

            return evt;
        }
    }

    this() {
        CompletionQueuePtr _c_cq;
        static if(T == "Pluck") {
            _c_cq.cq = grpc_completion_queue_create_for_pluck(null);
        }

        static if(T == "Next") {
            _c_cq.cq = grpc_completion_queue_create_for_next(null);
        }

        static if(T == "Callback") {
            static extern(C) void shutdown(grpc_experimental_completion_queue_functor* next, int status) {

            }
            _c_cq.cq = grpc_completion_queue_create_for_callback(cast(grpc_experimental_completion_queue_functor*)&shutdown, null);
        }

        assert(_c_cq.cq);

        __cq = _c_cq.cq;

        _cq = new Exclusive!CompletionQueuePtr(_c_cq.cq);

    }

    void shutdown() {
        mixin ptrNoLock;
        grpc_completion_queue_shutdown(cq);
//        grpc_event evt = next(dur!"msecs"(100));


        while(true) {
            Tag tag;
            static if(T == "Pluck") {
                auto a = next(tag, dur!"msecs"(100));
                grpc_event _evt = a.spinForce();
                if(_evt.type == GRPC_QUEUE_TIMEOUT) {
                    break;
                }

            } else static if (T == "Next") {
                auto a = next(dur!"msecs"(100));
                grpc_event _evt = a.spinForce();
                if(_evt.type == GRPC_QUEUE_TIMEOUT) {
                    break;
                }
            }
            import std.stdio;
        }
    }

    this(grpc_completion_queue* _ptr) {

        import core.memory;
        GC.setAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);

        _cq = new Exclusive!CompletionQueuePtr(_ptr);
    }

    ~this() {
        grpc_completion_queue_destroy(__cq);
    }
}

