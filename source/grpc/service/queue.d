module grpc.service.queue;
import core.sync.semaphore;


// class adopted from some answer on stackoverflow/d forums

class Queue(T) {
 
    private struct Node {
        T     payload;
        Node* next;
    }
 
    private Node* _first;
    private Node* _last = new Node(T.init,null);

    @property int count() {
        synchronized(countLock) { 
            return _count;
        }
    }

    private int   _count = 0;
    private Object countLock = new Object;
    private Object putLock = new Object;
    private Semaphore wait;
 
    this() {
        wait = new Semaphore();
        this._first = this._last;
    }
 
    /**
        Add to the Queue (to the end).
    */

    void put(ref T value) {
        synchronized(putLock) {
            Node* newLast = new Node(T.init,null);
            this._last.payload = value;
            this._last.next = newLast;
            this._last = newLast;
       
            synchronized(countLock) {
                _count++;
                wait.notify();
            }
        }
    }
   
 
    /**
        To be iterable with `foreach` loop.
    */

    void notify() {
        wait.wait();
    }

    bool empty() const {
        synchronized(countLock) { 
            return this._count == 0;
        }
    }
 
    ///ditto
    void popFront() {
        assert (!this.empty);
        synchronized(putLock) { 
            this._first = this._first.next;
        }
        synchronized(countLock) {
            _count--;
        }
    }
 
    ///ditto
    T front() const {
        assert (!this.empty);
        synchronized(putLock) { 
            return cast(T)(this._first.payload);
        }
    }
 
}
