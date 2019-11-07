module grpc.common.cq;
import grpc.core.grpc_preproc;
import std.typecons;
import grpc.core.tag;
import fearless;
import grpc.core;
public import core.time;

//queue ok/ok type
alias NextStatus = Tuple!(bool, bool);


// TODO: add mutexes 
gpr_timespec durtotimespec(Duration time) {
    gpr_timespec t;
    t.clock_type = GPR_CLOCK_MONOTONIC; 
    MonoTime curr = MonoTime.currTime;
    auto _time = curr + time;
    import std.stdio;

    auto nsecs = ticksToNSecs(_time.ticks).nsecs;

    nsecs.split!("seconds", "nsecs")(t.tv_sec, t.tv_nsec);
    
    return t;
}

Duration timespectodur(gpr_timespec time) {
    return time.tv_sec.seconds + time.tv_nsec.nsecs;
}

import core.thread;
import std.parallelism;

grpc_event getNext(bool* started, Exclusive!CompletionQueuePtr* cq, gpr_timespec _dead) {
    grpc_event t_;
    auto ptr = cq.lock();
    *started = true;
    t_ = grpc_completion_queue_next(ptr.cq, _dead, null);
    return t_;
}
grpc_event getTagNext(bool* started, Exclusive!CompletionQueuePtr* cq, void* tag, gpr_timespec _dead) {
    *started = true;
    auto ptr = cq.lock();
    grpc_event t = grpc_completion_queue_pluck(ptr.cq, tag, _dead, null);
    return t;
}

import std.traits;

struct CompletionQueuePtr {
    grpc_completion_queue *cq;
    alias cq this;
}

class CompletionQueue(string T) 
    if(T == "Next" || T == "Pluck") 
{
    private { 
        TaskPool asyncAwait;
        Exclusive!CompletionQueuePtr* _cq;
    }

    auto ptr() {
        synchronized { 
            return _cq.lock();
        }
    }

    static if(T == "Pluck") {
        grpc_event next(ref Tag tag, Duration time) {
            gpr_timespec t = durtotimespec(time);
            grpc_event _evt;

            auto ptr = ptr();

            _evt = grpc_completion_queue_pluck(ptr.cq, &tag, t, null); 

            return _evt;
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
    static if(T == "Next") {
        grpc_event next(Duration time) {
            gpr_timespec t = durtotimespec(time);
            grpc_event _evt;

            /*
            void awaitNext(ref grpc_event t, gpr_timespec deadline) {
                while(true) {
                    assert(cq != null, "cq was null");
                    import std.stdio;
                    t = grpc_completion_queue_next(cq, deadline, null);
                    Fiber.yield();
                }
            }
            */
            auto ptr = ptr();
            _evt = grpc_completion_queue_next(ptr.cq, t, null);

            /*
            Fiber fiber = new Fiber(() => awaitNext(_evt, t)); 
            fiber.call();
            */
            
            return _evt;
        }

        auto asyncNext(Duration time) {
            gpr_timespec deadline = durtotimespec(time);
            bool started;

            auto task = task!getNext(&started, _cq, deadline); 
            asyncAwait.put(task);
            while(!started) {
            }

            return task;
        }
    }

    this() {
        CompletionQueuePtr _c_cq;
        static if(T == "Pluck") {
            _c_cq.cq = grpc_completion_queue_create_for_pluck(null);
            asyncAwait = new TaskPool(6);
        }

        static if(T == "Next") {
            _c_cq.cq = grpc_completion_queue_create_for_next(null);
            asyncAwait = new TaskPool(1);
        }

        _cq = new Exclusive!CompletionQueuePtr(_c_cq.cq);

        asyncAwait.isDaemon = true;

    }

    void shutdown() {
        auto ptr = _cq.lock();
        grpc_completion_queue_shutdown(ptr.cq);
//        grpc_event evt = next(dur!"msecs"(100));

        destroy(ptr);

        grpc_event evt;
        while((evt.type == GRPC_QUEUE_TIMEOUT)) {
            Tag tag;
            static if(T == "Pluck") {
                evt = next(tag, dur!"msecs"(100));
            } else {
                evt = next(dur!"msecs"(100));
            }
            import std.stdio;
            writeln(evt.type != GRPC_QUEUE_TIMEOUT);
        }
    }


    this(grpc_completion_queue* _ptr) {
        mixin assertNotReady;

        _cq = new Exclusive!CompletionQueuePtr(_ptr);
    }

    ~this() {
        auto ptr = _cq.lock();
        grpc_completion_queue_destroy(cast(grpc_completion_queue*)(ptr.cq));
    }
}

