module grpc.core.mutex;
import core.sync.rwmutex;
import core.sync.semaphore;
import std.typecons;
import std.algorithm.mutation;
import core.atomic;

/*
class WrappedMutex(T) {
    private { 
        shared size_t numWaitingReaders, numWaitingWriters;
        shared T resource;
        ReadWriteMutex mutex;
    }

    @property size_t readers() {
        return numWaitingReaders;
    }

    @property size_t writers() {
        return numWaitingWriters;
    }

    @property bool empty() {
        if(resource == resource.init) {
            return true;
        }
        return false;
    }

    auto obtainWrite() {
        synchronized (mutex.writer) {
            atomicOp!"+="(numWaitingWriters, 1);
            mutex.writer.lock();
        }

        atomicOp!"-="(numWaitingWriters, 1);
        
        class MutexWriteLock {
            Unique!T _resource;

            this(Unique!T _res) {
                _resource = _res.release();
            }

            ~this() {
                assert(!_resource.isEmpty, "Unique ptr should NOT be null");
                mutex.writer.unlock();
            }
        }

        auto hmm = cast(T)atomicLoad!(MemoryOrder.seq, T)(resource);
        return new MutexWriteLock(Unique!T(&hmm));
    }

    auto obtainRead() {
        synchronized (mutex.reader) {
            atomicOp!"+="(numWaitingReaders, 1);
            mutex.reader.lock();
        }

        atomicOp!"-="(numWaitingReaders, 1);

        class MutexReadLock {
            Unique!T _resource;

            this(Unique!T _res) {
                _resource = _res.release();
            }

            ~this() {
                assert(!_resource.isEmpty, "Unique ptr should NOT be null");
                mutex.reader.unlock();
            }
        }

        auto hmm = cast(T)atomicLoad!(MemoryOrder.seq, T)(resource);
        return new MutexReadLock(Unique!T(&hmm));
    }

    this(T obj) {
        atomicStore(resource, obj);
    }

    ~this() {

    }
        
}

        
*/
