module grpc.core.tag;
import interop.headers;

struct Tag {
@safe:
    private {
        static ubyte[32] hiddenData;
        void generateNonce() @nogc {
            for(int i = 0; i < 32; i++) {
                import std.random;
                hiddenData[i] = uniform!ubyte();
            }
        }
    }

    void* objectPtr;

    ubyte[16] metadata;

    Tag* dup() {
        Tag* ret = Tag();
        ret.metadata = metadata;
        ret.hiddenData = hiddenData;
        return ret;
    }

    Tag* opCall() inout @trusted @nogc {
        Tag* ptr = cast(Tag*)gpr_malloc(Tag.sizeof);
        import core.stdc.string : memset;
        memset(ptr, 0, Tag.sizeof);
        ptr.generateNonce();
        return ptr;
    }

    ~this() @trusted {
        gpr_free(&this);
    }


    @disable this(this);
}
