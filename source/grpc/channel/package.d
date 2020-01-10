module grpc.channel;
import interop.headers;
import grpc.common.cq;

class Channel {
	private {
		grpc_channel* channel;
	}

    @property grpc_channel* ptr() {
        return channel;
    }

    @property string target() {
        char* target_ = grpc_channel_get_target(channel);
        if(target != null) {
            import std.string;
            return target_.fromStringz.idup;
        }
        else {
            return "";
        }
    }

    void getInfo(ref grpc_channel_info info) {
        assert(&info != null, "ptr was null");

        grpc_channel_get_info(channel, &info);
    }

    void notifyOnStateChange(grpc_connectivity_state pre, Duration timeout) {
        assert(0, "Unimplemented");
    }

	bool waitForStateChange(grpc_connectivity_state pre, Duration timeout) {
        auto time = MonoTime.currTime(); 
        while(state() == pre) {
            if(MonoTime.currTime - time > timeout) {
                return false;
            }
            import core.thread;
            Thread.sleep(1.msecs);
        }
		return true;
	}

    grpc_connectivity_state state(int try_to_connect = 0) {
        return grpc_channel_check_connectivity_state(channel, try_to_connect);
    }

    bool waitForConnect(Duration timeout) {
        auto time = MonoTime.currTime();
        import std.stdio;

        state(1);
        while(state() != GRPC_CHANNEL_READY) {
            if((MonoTime.currTime - time) > timeout) {
                return false;
            }

            import core.thread;
            Thread.sleep(1.msecs);
        }

        writeln(state());
        return true;
    }

	this(string target) {
        import std.string;
        channel = grpc_insecure_channel_create(target.toStringz, null, null);
        assert(channel != null, "channel was null");
	}

    import std.variant;

    this(string target, Variant[] channelArgs) {
        assert(0, "Unimplemented");
    }

    ~this() {
        grpc_channel_destroy(channel);
    }

}

