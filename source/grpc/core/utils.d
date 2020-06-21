module grpc.core.utils;
import interop.headers;
public import core.time;

string slice_to_string(grpc_slice slice) {
    import std.string : fromStringz;
    return slice_to_type!string(slice);
}

T slice_to_type(T)(grpc_slice slice) 
if(__traits(isPOD, T) && __traits(compiles, cast(T)[0x01, 0x02])) {
    import std.string : fromStringz;
    const(char*) slice_c = grpc_slice_to_c_string(slice);

    ubyte[] data = cast(ubyte[])slice_c[0..slice.data.inlined.length].dup;
    data.length = slice.data.inlined.length;

    T o = cast(T)data;

    gpr_free(cast(void*)slice_c);

    return o;
}

string byte_buffer_to_string(grpc_byte_buffer* bytebuf) {
        return byte_buffer_to_type!string(bytebuf);
}

T byte_buffer_to_type(T)(grpc_byte_buffer* bytebuf) {
        grpc_byte_buffer_reader reader;
        grpc_byte_buffer_reader_init(&reader, bytebuf);
        grpc_slice slices = grpc_byte_buffer_reader_readall(&reader);
        T _s = slice_to_type!T(slices);
        grpc_slice_unref(slices);
        grpc_byte_buffer_reader_destroy(&reader);
        return _s;
}

/* ensure that you unref after this.. don't want to keep a slice around too long */

grpc_slice string_to_slice(string _string) {
    grpc_slice slice;
    import std.string : toStringz;
    slice = grpc_slice_from_copied_buffer(_string.toStringz, _string.length);
    return slice;
}

grpc_slice type_to_slice(T)(T type) {
    grpc_slice slice;
    slice = grpc_slice_from_copied_buffer(cast(const(char*))type.ptr, type.length);
    return slice;
}
    
gpr_timespec durtotimespec(Duration time) nothrow {
    gpr_timespec t;
    t.clock_type = GPR_CLOCK_MONOTONIC; 
    MonoTime curr = MonoTime.currTime;
    auto _time = curr + time;
    import std.stdio;

    auto nsecs = ticksToNSecs(_time.ticks).nsecs;

    nsecs.split!("seconds", "nsecs")(t.tv_sec, t.tv_nsec);
    
    return t;
}

Duration timespectodur(gpr_timespec time) nothrow {
    return time.tv_sec.seconds + time.tv_nsec.nsecs;
}

import core.memory : GC;
void doNotMoveObject(void* ptr, size_t len) @trusted nothrow {
    GC.addRange(ptr, len);
    GC.setAttr(cast(void*)ptr, GC.BlkAttr.NO_MOVE);
    GC.addRoot(ptr);
}

void okToMoveObject(void* ptr) @trusted nothrow {
    GC.removeRoot(ptr);
    GC.clrAttr(cast(void*)ptr, GC.BlkAttr.NO_MOVE);
//    GC.removeRange(ptr);
}
