module grpc.logger;
import grpc.service.queue;
import std.datetime; 
import core.thread;

enum Verbosity {
    Debug = "DEBUG",
    Info = "INFO",
    Warning = "WARNING",
    Error = "ERROR"
};

static __gshared Logger gLogger;

void INFO(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Info, message, file, line);
}

void WARNING(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Warning, message, file, line);
}

void DEBUG(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) {
    string message = "";
    foreach(arg; args) {
        import std.conv : to;
        message ~= to!string(arg); 
    }

    gLogger.log(Verbosity.Debug, message, file, line);
}

void ERROR(string file = __MODULE__, int line = __LINE__, A...)(lazy A args) {
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

        Queue!LogEvent q;

        LoggerThread _thread;
        
        class LoggerThread : Thread {
            this() {
                super(&run);
            }

        private:
            void run() {
                while(true) {
                    import std.stdio : writeln;
                    q.notify();
                    {
                        LogEvent l = q.front;
                        q.popFront;
                        if(l.v >= minVerbosity) {
                            import std.format;
                            string message = format!"%s [%s:%s] %s"(l.time.toISOExtString(), l.source, l.v, l.message);
                            writeln(message);
                        }
                    }
                }
            }
        }

    }

    Verbosity minVerbosity;
    
    void info(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Info, message, file, line);
    }

    void warning(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Warning, message, file, line);
    }

    void debug_(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Debug, message, file, line);
    }

    void error(string message, string file = __MODULE__, int line = __LINE__) {
        log(Verbosity.Error, message, file, line);
    }

    void log(Verbosity v, string message, string file = __MODULE__, int line = __LINE__) {
        LogEvent l;
        l.time = Clock.currTime();
        l.v = v;
        l.message = message;
        import std.conv : to;
        l.source = file ~ ":" ~ to!string(line); 

        q.put(l);
    }

    this(Verbosity _minVerbosity = Verbosity.Info, string info = "", string warning = "", string error = "", string debug_ = "") {
        minVerbosity = _minVerbosity;
        _infoPath = info;
        _warningPath = warning;
        _errorPath = error;
        _debugPath = debug_;

        q = new Queue!LogEvent();

        _thread = new LoggerThread();
        _thread.isDaemon = true;
        _thread.start();
    }

    shared static this() {
        gLogger = new Logger();
    }
}


