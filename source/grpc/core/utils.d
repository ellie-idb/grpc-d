module grpc.core.utils;
import grpc.core.alloc;
import grpc.core.grpc_preproc;

string slice_to_string(grpc_slice slice) {
    import std.string : fromStringz;

    return slice_to_type!string(slice);
}

T slice_to_type(T)(grpc_slice slice) 
if(__traits(isPOD, T) && __traits(compiles, cast(T)[0x01, 0x02])) {
    import std.string : fromStringz;
    const(char*) slice_c = grpc_slice_to_c_string(slice);

    ubyte[] data = cast(ubyte[])slice_c[0..slice.data.inlined.length].dup;

    T o = cast(T)data;

    gpr_free(cast(void*)slice_c);

    return o;
}

string byte_buffer_to_string(grpc_byte_buffer* bytebuf) {
        import std.stdio;
        grpc_byte_buffer_reader reader;
        grpc_byte_buffer_reader_init(&reader, bytebuf);
        grpc_slice slices = grpc_byte_buffer_reader_readall(&reader);

        string _s = slice_to_string(slices);

        grpc_byte_buffer_reader_destroy(&reader);

        grpc_slice_unref(slices);


        return _s;
}

/* ensure that you unref after this.. don't want to keep a slice around too long */

grpc_slice string_to_slice(string _string) {
    grpc_slice slice;
    import std.string : toStringz;
    slice = grpc_slice_ref(grpc_slice_from_copied_buffer(_string.toStringz, _string.length));
    return slice;
}

grpc_slice type_to_slice(T)(T type) {
    grpc_slice slice;
    slice = grpc_slice_ref(grpc_slice_from_copied_buffer(cast(const(char*))type, type.length));
    return slice;
}
    

