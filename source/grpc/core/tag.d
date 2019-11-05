module grpc.core.tag;

@nogc class Tag {
    package {
        ubyte[32] hiddenData;
    }

    ubyte[16] metadata;

    Tag dup() {
        Tag ret = new Tag();
        ret.hiddenData = hiddenData;
        ret.metadata = metadata;
        return ret;
    }

    this() {
        for(int i = 0; i < 32; i++) {
            import std.random;
            hiddenData[i] = uniform!ubyte();
        }
    }

    override bool opEquals(Object o) {
        if(typeid(this) == typeid(o)) {
            Tag _o = cast(Tag)o;
            if(_o.hiddenData == hiddenData) {
                return true;
            }
        }

        return false;

    }
}
