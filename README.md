gRPC-D-Core
======
## Purpose
This library is intended to provide better RPC support for the D Language (and provide interop with major systems), while being lightweight with little overhead.

## Design Goals
* Utilize the metaprogramming facilities in the language to avoid massive hurdles that other languages have had to jump over 
(see C++, where the programming model is incredibly strange and foreign)
* Perform massive amounts of computation and generation at compile-time to avoid adding extra runtime complexity
* Heavily multithread service requests (to avoid the problem that Rust developers are currently facing)
* Make ease of use of the library a priority, not an after-thought.
* Reach performance that is near native C++ performance, but significantly easier to use.
* Avoid invoking the garbage collector as much as possible

## Progress
**IMPORTANT**: As of current, the library is server-only. This will change in the future, and client functionality IS planned.
Pre-alpha (until more extensive validation takes place)

## Known quirks
* Compiling .proto files must be done with the custom compiler plugin [here](https://github.com/hatf0/grpc-d-compiler), rather then using the compiler plugin from `protobuf-d`
    * This is due to the compiler generating custom attributes that are not normally emitted (and handling the ServiceDescriptors) 
* The library will spawn multiple workers (and, thus, multiple instances of a handler class)
    * This is normally not an issue with simple classes, however, if your class loads data from disk, this should be a consideration.
    * The worker value (for each call) will be tunable in future releases
## Example applications
* [grpc-demo](https://github.com/hatf0/grpc-demo):
    This program fully complies to the HelloWorld example contained within the gRPC source,
    and demonstrates the simplex performance of this library.
* [grpc-route-guide](https://github.com/hatf0/grpcd-route-guide):
    This program fully complies to the RouteGuide example contained within the gRPC source,
    and demonstrates how easy streaming is to take advantage of.

## Planned features
- [ ] Document library (and code in it's entirety)
- [ ] Unit test functionality
- [ ] Optimize, optimize, optimize
- [ ] Implement the client interface
- [ ] Improve exception handling (currently it can lead to a segfault in rare occasions)
- [ ] channelz/reflection support 
- [X] Implement the server interface
- [ ] Enable compression/encrypted communication
- [ ] Allow for full server/client configuration (tuning via grpc_{channel,server}_args)

