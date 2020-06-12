module grpc.server.builder;
import interop.headers;
import grpc.server;

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

    Server* build() {
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
        _server = Server(args);

        _server.bind("0.0.0.0", 50051);

        return &_server;
    }


    this() {
    }

    ~this() {

    }
        
}
