module grpc.service.queue;
import core.sync.semaphore;
import interop.headers;
debug import std.stdio;
import core.atomic;
import grpc.core.utils;

// class adopted from some answer on stackoverflow/d forums

class Queue(T) {
    private struct Node {
        T     payload;
        Node* next;
    }
 
    private Node* _first;
    private Node* _last = new Node(T.init,null);

    @property int count() {
        gpr_mu_lock(&mutex);
        scope(exit) gpr_mu_unlock(&mutex);
        return _count;
    }

    private shared int   _count = 0;
    private gpr_cv cv;
    private gpr_mu mutex;
 
    void lock() {
        gpr_mu_lock(&mutex);
    }
    
    void unlock() {
        gpr_mu_unlock(&mutex);
    }
 
    this() {
        gpr_cv_init(&cv);
        gpr_mu_init(&mutex);
        
        this._first = this._last;
    }

    ~this() {
        gpr_cv_destroy(&cv);
        gpr_mu_destroy(&mutex);
    }
 
    /**
        Add to the Queue (to the end).
    */
    
    void signal() {
        gpr_cv_signal(&cv);
    }
    
    void notifyAll() {
        gpr_cv_broadcast(&cv);
    }

    void put(T value) {
        gpr_mu_lock(&mutex);
        { 
            Node* newLast = new Node(null,null);
            this._last.payload = value;
            this._last.next = newLast;
            this._last = newLast;
            atomicOp!"+="(_count, 1);
        }
        gpr_mu_unlock(&mutex);
        gpr_cv_signal(&cv);
    }
   
 
    /**
        To be iterable with `foreach` loop.
    */

    void notify(gpr_timespec timeout = durtotimespec(10.seconds)) {
        gpr_mu_lock(&mutex);
        if (_count == 0) {
            gpr_cv_wait(&cv, &mutex, timeout);
        } else if (_count <= 0) {
            assert(0, "count should never be this");
            //debug writeln("count SHOULD NOT BE BELOW 0, ", _count);
        } else {
            //debug writeln("skipping wait, count: ", _count);
        }
    }

    
    /* ASSUMES YOU ARE LOCKED */
    bool empty() {
        return this._count == 0;
    }
 
    ///ditto
    T popFront() in {
        assert (!this.empty);
    } do {
        gpr_mu_lock(&mutex);
        scope(exit) gpr_mu_unlock(&mutex);
        T obj;
        if (this._first != null) {
            obj = cast(T)(this._first.payload);

            this._first = this._first.next;
        }
        atomicOp!"-="(_count, 1);
        return obj;
    }
    
    void pop() in {
        assert (!this.empty);
    } do {
        if (this._first != null) {
            this._first = this._first.next;
        }
        atomicOp!"-="(_count, 1);
    }
 
    ///ditto
    T front() in { 
        assert (!this.empty);
    } do {
        return cast(T)(this._first.payload);
    }
 
}
