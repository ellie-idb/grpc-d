module grpc.service;
import core.atomic;
import interop.headers;
import grpc.logger;
import core.thread;
import grpc.server : Server;
import grpc.common.call;
import google.rpc.status;
import grpc.core.tag;
import grpc.common.cq;
import grpc.core.utils;
import std.experimental.allocator : theAllocator, make, dispose;

// Every Service template class is guaranteed to at least implement these functions
interface ServiceHandlerInterface {
    bool register(Server server);
    void stop();
    void kickstart();
    ulong runners();
}

// Since we dynamically generate the function handler through UDAs,
// we need some way to get the type that it is expecting (be it, through a ServerReader/ServerWriter interface, or a POD type)
// These two templates resolve that, and get us the type.

mixin template Reader(T) {
    import std.traits : TemplateArgsOf, TemplateOf;
    static if(is(TemplateOf!T == void)) {
        alias input = T;
    }
    else {
        alias input = TemplateArgsOf!(T)[0];
    }

}

mixin template Writer(T) {
    import std.traits : TemplateArgsOf, TemplateOf;
    static if(is(TemplateOf!T == void)) {
        alias output = T;
    }
    else {
        alias output = TemplateArgsOf!(T)[0];
    }
}
class ServicerThread(T) : Thread {
    this() {
        super(&run);
    }
    
    ~this() {
    }
    
    /* Set by the main thread */
    shared bool threadReady;
    shared bool threadStart;
    ulong workerIndex;
    void*[string] registeredMethods;
    shared(Server) server;

private:
    /* Thread local things */
    shared(CompletionQueue!"Next") notificationCq;
    CompletionQueue!"Next" callCq;
    Tag*[] tags;
    T instance;
    shared bool _run;

    void handleTag(Tag* tag) {
        import std.traits : Parameters, BaseTypeTuple, getSymbolsByUDA, hasUDA;
        import core.time : MonoTime;

        alias parent = BaseTypeTuple!T[1];
        if (!tag) return;
        if (tag.metadata[0] != 0xDE) return;
        if (tag.metadata[2] != workerIndex) return;

        tag.ctx.mutex.lock;
        scope(exit) tag.ctx.mutex.unlock;
        tag.ctx.timestamp = MonoTime.currTime;

        sw: switch (tag.metadata[1]) {
            static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {{
                import grpc.stream.server.reader : ServerReader;
                import grpc.stream.server.writer : ServerWriter;
                mixin Reader!(Parameters!val[0]);
                mixin Writer!(Parameters!val[1]);
                alias SR = ServerReader!input;
                alias SW = ServerWriter!output;
                case i: {
                    enum ServerStream = hasUDA!(val, ServerStreaming);
                    enum ClientStream = hasUDA!(val, ClientStreaming);
                    SR reader = SR(tag, callCq);
                    SW writer = SW(tag, callCq);

                    Status stat;
                    input funcIn;
                    output funcOut;
                    try {
                        static if(!ServerStream && !ClientStream) {
                            // unary call
                            funcIn = reader.readOne();
                            stat = __traits(child, instance, val)(funcIn, funcOut);
                            writer.start();
                            writer.write(funcOut);
                        } else static if (ServerStream && ClientStream) {
                            // bidi call
                            stat = __traits(child, instance, val)(reader, writer);
                        } else static if (!ServerStream && ClientStream) {
                            // client streaming call
                            stat = __traits(child, instance, val)(reader, funcOut);
                            writer.start();
                            writer.write(funcOut);
                        } else static if (ServerStream && !ClientStream) {
                            // server streaming call
                            funcIn = reader.readOne();
                            writer.start();
                            stat = __traits(child, instance, val)(funcIn, writer);
                        }
                    } catch (Exception e) {
                        grpc_call_cancel(*tag.ctx.call, null);
                        stat.code = GRPC_STATUS_INTERNAL;
                        stat.message = e.msg;
                    }

                    writer.finish(stat);
                    reader.finish();

                    tag.ctx.metadata.cleanup;
                    if (tag.ctx.data.valid) {
                        tag.ctx.data.cleanup;
                    }

                    grpc_call_unref(*tag.ctx.call);
                    *tag.ctx.call = null;
                    break sw;
                }
            }}

            default:
                assert(0, "Received tag with function index out of bounds");
        }
    }

    void run() {
        import std.traits : getUDAs, getSymbolsByUDA, BaseTypeTuple;
        import std.experimental.allocator.mallocator: Mallocator;
        import std.experimental.allocator : theAllocator, allocatorObject;
        
        theAllocator = allocatorObject(Mallocator.instance);

        instance = theAllocator.make!T();
        notificationCq = cast(shared)theAllocator.make!(CompletionQueue!"Next")();
        callCq = theAllocator.make!(CompletionQueue!"Next")();

        DEBUG!"registering (thread: %d)"(workerIndex);
        server.registerQueue(notificationCq);
        DEBUG!"registered (thread: %d)"(workerIndex);

        // Block while the rest of the threads spool up, and wait for the server to signal
        // that it has started, and it is safe to request calls on our CQ
        atomicStore(threadReady, true);
        while (!atomicLoad(threadStart)) {
             Thread.sleep(1.msecs);
        }

        DEBUG!"beginning phase 2 (thread: %d)"(workerIndex);
        alias parent = BaseTypeTuple!T[1];
        static foreach(i, val; getSymbolsByUDA!(parent, RPC)) {{
            static if (i > ubyte.max) {
                static assert(0, "Too many RPC functions!");
            }

            enum remoteName = getUDAs!(val, RPC)[0].methodName;
            Tag* tag = Tag();
            tags ~= tag;
            // magic number
            tag.metadata[0] = 0xDE;
            tag.metadata[1] = cast(ubyte)i;
            tag.metadata[2] = cast(ubyte)workerIndex;
            tag.method = registeredMethods[remoteName];
            tag.methodName = remoteName;
            callCq.requestCall(tag.method, tag, server, notificationCq);
        }}

        /*
            PHASE 3:
            Here, we begin the main loop to service requests. This continues,
            until the queue is shutdown, or _run is set to false.
        */

        atomicStore(_run, true);
        while (atomicLoad(_run)) {
            auto item = notificationCq.next(10.seconds);
            notificationCq.lock();
            scope(exit) notificationCq.unlock();
            if (item.type == GRPC_OP_COMPLETE) {
                DEBUG!"hello from task %d"(workerIndex);
                DEBUG!"hit something";
            } else if (item.type == GRPC_QUEUE_SHUTDOWN) {
                DEBUG!"shutdown";
                _run = false;
                continue;
            } else if(item.type == GRPC_QUEUE_TIMEOUT) {
                DEBUG!"timeout";
                continue;
            }

            if (notificationCq.inShutdownPath) {
                DEBUG!"we are in shutdown path";
                _run = false;
                break;
            }

            DEBUG!"grabbing tag";
            Tag* tag = cast(Tag*)item.tag;
            DEBUG!"got tag: %x"(tag);

            // xxx: should never happen
            if (tag == null) {
                ERROR!"got null tag?";
                continue;
            }

            handleTag(tag);

            grpc_call_error error = callCq.requestCall(tag.method, tag, server, notificationCq);
            if (error != GRPC_CALL_OK) {
                ERROR!"could not request call %s"(error);
            }
        }

        theAllocator.dispose(callCq);
        theAllocator.dispose(notificationCq);
        theAllocator.dispose(instance);
    }
}
class Service(T) : ServiceHandlerInterface 
if (is(T == class)) {
    private {
        void*[string] registeredMethods;
        Server _server;
        ThreadGroup threads;
        ServicerThread!T[] _threads; // do not ever use
        immutable ulong workingThreads;
        immutable ulong _serviceId;
    }

    // function may be called by another thread other then the main() thread
    // make sure that doesnt muck up
    
    ulong runners() {
        ulong r = 0;
        foreach(thread; threads) {
            if (thread.isRunning()) r += 1;
        }
        
        return r;
    }

    void kickstart() {
        foreach(thread; _threads) {
            atomicStore(thread.threadStart, true);
        }
    }

    void stop() {
        // block while every thread terminates
        threads.joinAll();
    }

    // this function will always be called by main()

    bool register(Server server) {
        import std.traits : BaseTypeTuple;
        alias parent = BaseTypeTuple!T[1];

        /* Fork and spawn new threads for each worker */
        for (ulong i = 0; i < workingThreads; i++) {
            auto t = new ServicerThread!T();
            //t.handlers = _handlers;
            t.workerIndex = i;
            // We *should* block for this thread to stop execution at the end
            t.isDaemon = false;
            t.registeredMethods = registeredMethods;
            t.server = cast(shared)server;
            t.start();

            threads.add(t);
            _threads ~= t;
        }

        // avoid race condition while we wait for all threads to fully spool

        loop: while (true) {
            foreach(thread; _threads) {
                if (!atomicLoad(thread.threadReady)) {
                    Thread.sleep(1.msecs);
                    continue loop;
                }
            }
            break;
        }

        return true;
    }

    this(ulong serviceId, void*[string] methodTable) {
        debug import std.stdio;
        debug writefln("passed method table: %s", methodTable);
        registeredMethods = methodTable.dup;
        _serviceId = serviceId;
        threads = new ThreadGroup();

        // TODO: make this user-specifiable
        workingThreads = 1;
    }
        
}
    
