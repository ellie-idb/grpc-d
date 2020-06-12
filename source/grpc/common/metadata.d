module grpc.common.metadata;
import interop.headers;
import grpc.common.cq;
import grpc.core.utils;
import fearless;

@nogc: 
struct MetadataArrayWrapper {
    alias metadata this;
    grpc_metadata_array metadata;
} 

struct MetadataWrapper {
    alias metadata this;
    grpc_metadata metadata;
}

class MetadataArray {
    private {
        gpr_mu mutex;
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

