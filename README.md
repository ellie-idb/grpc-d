gRPC-D
======
## Purpose
This library is intended to provide better RPC support for the D Language (and provide interop with major systems).
## Design Goals
* Utilize the metaprogramming facilities in the language to avoid massive hurdles that other languages have had to jump over 
(see C++, where the programming model is incredibly strange and foreign)
* Perform massive amounts of computation and generation at compile-time to avoid adding extra runtime complexity
* Heavily multithread service requests (to avoid the problem that Rust developers are currently facing)
* Do all of this, while still being easy to use.
## Progress
Currently, the library is very much still in a prototype phase, and is not close to being usable in day-to-day scenarios.
