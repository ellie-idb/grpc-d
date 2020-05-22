module grpc.stream.server.reader;
import grpc.logger;
import grpc.core.tag;
import interop.headers;
import grpc.common.cq; 
import grpc.common.call;

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
                        ERROR("Deserialization fault: ", e.msg);
                        ERROR(data);
                        ERROR("Byte buffer length: ", bf.length);

                        return;
                    }

                    yield(protobuf);

                    BatchCall batch = new BatchCall(_call);
                    batch.addOp(new RecvMessageOp(bf));
                    auto stat = batch.run(_tag, d);
                    if(stat != GRPC_CALL_OK) {
                        ERROR("READ ERROR: ", stat);
                        return;
                    }

                }
            }
            BatchCall batch = new BatchCall(_call);
            int cancelled = 0;
            batch.addOp(new RecvCloseOnServerOp(&cancelled));
            auto stat = batch.run(_tag, 1.msecs);
        });

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
