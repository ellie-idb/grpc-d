module grpc.common.metadata;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import fearless;

struct MetadataArrayWrapper {
    alias metadata this;
    grpc_metadata_array metadata;
} 

struct MetadataWrapper {
    alias metadata this;
    grpc_metadata metadata;
}

class Metadata {
    private { 
        Exclusive!MetadataWrapper* _metadata;
    }

    auto borrow() {
        return _metadata.lock();
    }

    @property string key() {
        auto metadata = _metadata.lock();
        return slice_to_string(metadata.key);
    }

    @property string value() {
        auto metadata = _metadata.lock();
        return slice_to_string(metadata.value);
    }

    @property uint flags() {
        auto metadata = _metadata.lock();
        uint flags = metadata.flags;
        return flags;
    }

    this(grpc_metadata meta) {
        _metadata = new Exclusive!MetadataWrapper(meta);
    }
}


class MetadataArray {
    private {
        Exclusive!MetadataArrayWrapper* _metadata;
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

    Metadata opIndex(size_t i1) {
        auto metadata = _metadata.lock();
        grpc_metadata[] mt = metadata.metadata.metadata[0..metadata.capacity]; 
        if(i1 > metadata.count) 
        {
            import core.exception;
            throw new RangeError();
        }

        Metadata meta = new Metadata(mt[i1]);

        return meta;
    }

    this() {
        grpc_metadata_array metadata;

        grpc_metadata_array_init(&metadata);

        _metadata = new Exclusive!MetadataArrayWrapper(metadata);
    }
}

