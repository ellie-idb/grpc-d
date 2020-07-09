module grpc.core.utils;
import interop.headers;
import interop.functors;
import grpc.logger;
import std.experimental.allocator : theAllocator, makeArray, dispose;
public import core.time;

string slice_to_string(grpc_slice slice) {
    return slice_to_type!string(slice);
}

auto ref slice_to_type(T)(grpc_slice slice) 
if(__traits(isPOD, T) && __traits(compiles, cast(T)[0x01, 0x02])) {
    if (GRPC_SLICE_LENGTH(slice) != 0) {
        ubyte[] data = theAllocator.makeArray!ubyte(GRPC_SLICE_START_PTR(slice)[0..GRPC_SLICE_LENGTH(slice)]);
        DEBUG!"MAKE SURE TO FREE THIS ARRAY: %x"(data.ptr);
        DEBUG!"data size: %d"(data.length);
        return cast(T)data;
    }
    return null;
}

string byte_buffer_to_string(grpc_byte_buffer* bytebuf) {
        return byte_buffer_to_type!string(bytebuf);
}

auto ref byte_buffer_to_type(T)(grpc_byte_buffer* bytebuf) {
        grpc_byte_buffer_reader reader;
        grpc_byte_buffer_reader_init(&reader, bytebuf);
        grpc_slice slices = grpc_byte_buffer_reader_readall(&reader);
        grpc_byte_buffer_reader_destroy(&reader);
        auto val = slice_to_type!T(slices);
        grpc_slice_unref(slices);
        return val;
}

/* ensure that you unref after this.. don't want to keep a slice around too long */

grpc_slice string_to_slice(string _string) {
    import std.string : toStringz;
    grpc_slice slice = grpc_slice_from_copied_string(_string.toStringz);
    return slice;
}

grpc_slice type_to_slice(T)(T type) {
    grpc_slice slice = grpc_slice_from_copied_buffer(cast(const(char*))type.ptr, type.length);
    return slice;
}
    
gpr_timespec durtotimespec(Duration time) {
    gpr_timespec t = gpr_time_from_nanos(time.split!"nsecs"().nsecs, GPR_TIMESPAN);
    return t;
}

Duration timespectodur(gpr_timespec time) {
    return gpr_time_to_millis(gpr_time_sub(time, gpr_now(time.clock_type))).msecs; 
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
    GC.removeRange(ptr);
}

import grpc.core.tag : Tag;
bool callOverDeadline(Tag* _tag) {
    if (_tag.ctx.details.deadline == -1.seconds) {
        DEBUG!"call has NO deadline";
        return false;
    } else {
        DEBUG!"%s vs %s"(MonoTime.currTime - _tag.ctx.timestamp, _tag.ctx.details.deadline);
    }

    if (MonoTime.currTime - _tag.ctx.timestamp > _tag.ctx.details.deadline) {
        DEBUG!"reached deadline, cannot go further";
        return true;
    }
    return false;
}

