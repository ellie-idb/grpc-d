module grpc.logger;
import interop.headers;
import grpc.service.queue;
import std.datetime; 
import core.thread;

enum Verbosity {
    Debug = 0,
    Info = 1,
    Error = 2
};

static __gshared Logger gLogger;

void INFO(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) @trusted {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Info, message, file, line);
}

void DEBUG(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) @trusted {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Debug, message, file, line);
}

void ERROR(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) @trusted  {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Error, message, file, line);
}

class Logger {
    private {
        struct LogEvent {
            SysTime time;
            Verbosity v;
            string message;
            string source;
        }

        string _infoPath;
        string _warningPath;
        string _errorPath;
        string _debugPath;

        Verbosity __minVerbosity;

    }

    @property Verbosity minVerbosity() {
        return __minVerbosity;
    }

    @property Verbosity minVerbosity(Verbosity _min) {
        gpr_log_verbosity_init();
        gpr_set_log_verbosity(cast(gpr_log_severity)_min);
        __minVerbosity = _min;

        return _min;
    }


    
    void info(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Info, message, file, line);
    }

    void debug_(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Debug, message, file, line);
    }

    void error(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Error, message, file, line);
    }

    void log(Verbosity v, string message, string file = __MODULE__, int line = __LINE__) {
        import std.string : toStringz;
        const(char)* msg = message.toStringz;
        gpr_log_message(file.toStringz, line, cast(gpr_log_severity)v, msg); 
    }

    this(Verbosity _minVerbosity = Verbosity.Info, string info = "", string warning = "", string error = "", string debug_ = "") {
        minVerbosity = _minVerbosity;
        _infoPath = info;
        _warningPath = warning;
        _errorPath = error;
        _debugPath = debug_;
    }

    shared static this() {
        gLogger = new Logger();
        import core.exception;
        core.exception.assertHandler = &assertHandler;
    }
}

void assertHandler(string file, ulong line, string message) nothrow {
    try { 
        ERROR("ASSERT: ", message, " at ", file, ":", line);
    } catch(Exception e) {

    }
}

