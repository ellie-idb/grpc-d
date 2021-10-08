module grpc.server.builder;
import interop.headers;
import grpc.server;
import core.lifetime;

class ServerBuilder {
    private {
        ushort _port;
        int _maxInboundMeta;
        int _maxInboundMessage;
        long _timeout;
        bool _useTLS;
        string _tlsChain;
        string _tlsKey;
        Server _server;
    }

    @property ushort port(ushort _new) {
        _port = _new;
        return _port;
    }

    @property ushort port() {
        return _port;
    }

    void register(T)() {
        _server.registerService!T();
    }

    Server build() {
        auto mem = gpr_zalloc(__traits(classInstanceSize, Server));
        Server srv = cast(Server)mem;
        if (mem != null) {
            grpc_channel_args args;
            args.num_args = 1;

            grpc_arg[] _a;
            grpc_arg arg;
            import std.string;
            arg.type = GRPC_ARG_INTEGER;
            arg.key = cast(char*)("grpc.server_handshake_timeout_ms".toStringz);
            arg.value.integer = 1000;
            _a ~= arg;

            args.args = _a.ptr; 
            emplace!Server(srv, args);

            srv.bind("0.0.0.0", 50051);
        }
        else {
            assert(0, "Allocation failed");
        }

        return srv;
    }


    this() {
    }

    ~this() {

    }
        
}
