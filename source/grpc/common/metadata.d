module grpc.common.metadata;
import grpc.common.cq;
import grpc.core.utils;
import grpc.core.resource;
import fearless;
import grpc.logger;
import interop.headers;
import interop.functors;

struct MetadataArrayWrapper {
    alias metadata this;
    grpc_metadata_array metadata;
} 

class MetadataArray {
    private {
        bool resized;

        void resize(size_t newlen) 
        in {
            assert(newlen > capacity);
        } 
        do {
            grpc_metadata_array n;
            grpc_metadata_array_init(&n);

            n.capacity = newlen;
            n.metadata = cast(grpc_metadata*)gpr_malloc((grpc_metadata).sizeof * newlen);

            void* _md;

            { 
                auto metadata = _metadata.lock();

                // save the actual pointer so we can destroy it later
                _md = &metadata.metadata;

                // we cannot shrink, only grow

                n.count = metadata.count;

                import core.stdc.string;
                memset(n.metadata, 0, (grpc_metadata).sizeof * newlen);

                memcpy(n.metadata, metadata.metadata.metadata, (grpc_metadata).sizeof * capacity);

                DEBUG("copied");

                // override the Exclusive object with our new data
            }
            // destroy, all data should be copied out
            grpc_metadata_array_destroy(cast(grpc_metadata_array*)_md);

            _metadata = new Exclusive!MetadataArrayWrapper(n);

            resized = true;
        }

        Exclusive!MetadataArrayWrapper* _metadata;
        struct Metadata {
        @safe:
            private { 
                SharedResource _entry;
            }

            @property inout(grpc_metadata)* handle() inout @trusted pure nothrow {
                return cast(typeof(return)) _entry.handle;
            }

            @property string key() {
                return slice_to_string(this.handle.key);
            }

            @property string value() {
                return slice_to_string(this.handle.value);
            }

            @property uint flags() {
                uint flags = this.handle.flags;
                return flags;
            }

            static Metadata opCall(ref grpc_metadata meta) @trusted {
                static Exception release(shared(void)* ptr) @trusted nothrow {
                    return null;
                }

                Metadata _meta;
                _meta._entry = SharedResource(cast(shared)&meta, &release);

                return _meta;
            }
        }
    }

    auto borrow() {
        return _metadata.lock();
    }

    @property ulong capacity() {
        auto metadata = _metadata.lock();
        return metadata.capacity;
    }

    @property ulong count() {
        auto metadata = _metadata.lock();
        return metadata.count;
    }

    @property ulong length() {
        return count;
    }

    void add(string key, string value) {

        size_t cap, count, i;
        {
            auto metadata = _metadata.lock();
            count = metadata.count;
            i = count;

            cap = metadata.capacity;

            count++;

            DEBUG(metadata.count, " " , metadata.capacity);
        }

        if(count > cap) {
            resize(count);
        }

        DEBUG("copied, adding to the array");
        {
            auto metadata = _metadata.lock();
            metadata.count++;

            grpc_metadata[] mt = metadata.metadata.metadata[0..metadata.capacity];
            try { 
                mt[i].key = string_to_slice(key); 
                mt[i].value = string_to_slice(value);
            } catch(Exception e) {
                ERROR("caught exception: ", e.msg);
            }
        }

        DEBUG("done");
    }

    Metadata opIndex(size_t i1) {
        auto metadata = _metadata.lock();
        grpc_metadata[] mt = metadata.metadata.metadata[0..metadata.capacity]; 
        if(i1 > metadata.count) 
        {
            import core.exception;
            throw new RangeError();
        }

        Metadata meta = Metadata(mt[i1]);

        return meta;
    }

    this() {
        import core.memory;
        GC.setAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);

        grpc_metadata_array metadata;

        grpc_metadata_array_init(&metadata);

        _metadata = new Exclusive!MetadataArrayWrapper(metadata);
    }

    ~this() {
        grpc_metadata_array_destroy(&borrow.metadata);
    }
}

