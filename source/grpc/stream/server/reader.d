module grpc.stream.server.reader;
import grpc.core.tag;
import grpc.core.grpc_preproc;
import grpc.common.cq; 
import grpc.common.call;
import grpc.service.queue;

class ServerReader(T) {
    private {
        RemoteCall _call;
        Tag _tag;
    }

    auto read(int count = 0, Duration d = 10.seconds) {
        import std.concurrency;
        import std.stdio;
        import grpc.common.byte_buffer;
        import google.protobuf;
        import grpc.common.batchcall;

        class Iterator(T) {
            private {
                Queue!T _queue;
                ByteBuffer _bf;

                size_t index;
                
                T readAndIncrement() {
                    T protobuf;
                    if(_bf.length != 0) {
                        ubyte[] data = _bf.readAll();
                        try {
                            protobuf = data.fromProtobuf!T();
                        } catch(Exception e) {
                            writeln("Deserialization fault: ", e.msg);
                        }
                        return protobuf;
                    }
                    return protobuf;
                }

                bool readNewMessage() {
                    BatchCall batch = new BatchCall(_call);
                    batch.addOp(new RecvMessageOp(_bf));
                    auto stat = batch.run(_tag, d);
                    if(stat != GRPC_CALL_OK) {
                        return false;
                    }

                    if(_bf.length != 0) {
                        _queue.put(readAndIncrement());
                        return true;
                    }

                    return false;

                }
            }

            bool empty() {
                return _queue.empty();
            }

            void popFront() {
                _queue.popFront();
                if(count == 0) {
                    readNewMessage();
                }
                //advance the queue
            }

            T front() {
                return _queue.front;
            }

            final int opApply(scope int delegate(T) loop) {
                int broken;
                for (; !empty; popFront())
                {
                    broken = loop(front);
                    if (broken) break;
                }
                return broken;
            }

            this() {
                _bf = _call.data();
                _queue = new Queue!T();
                T _p = readAndIncrement();

                _queue.put(_p);
            }
        }
/*
        auto r = new Generator!T({
            ByteBuffer bf = _call.data();
            if(count == 1) {
                T protobuf;
                if(bf.length != 0) {
                    ubyte[] data = bf.readAll();

                    protobuf = data.fromProtobuf!T();
                }

                yield(protobuf);
            }
            else {
                ubyte[] data;

                while(bf.length != 0) {
                    data = bf.readAll();
                    T protobuf;

                    if(data.length == 0) {
                        return;
                    }

                    try { 
                        protobuf = data.fromProtobuf!T();
                    } catch(Exception e) {
                        writeln("Deserialization fault: ", e.msg);
                        writeln(data);
                        writeln("Byte buffer length: ", bf.length);

                        return;
                    }

                    yield(protobuf);

                    BatchCall batch = new BatchCall(_call);
                    batch.addOp(new RecvMessageOp(bf));
                    auto stat = batch.run(_tag, d);
                    if(stat != GRPC_CALL_OK) {
                        writeln("READ ERROR: ", stat);
                        return;
                    }

                }
            }

        });
        */

        auto r = new Iterator!T();

        return r;
    }

    this(ref RemoteCall call, ref Tag tag) {
        import std.stdio;
        _call = call;
        _tag = tag;
    }

    ~this() {


    }
}
