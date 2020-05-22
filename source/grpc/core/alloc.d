module grpc.core.alloc;

import core.stdc.config;
import core.stdc.stdarg: va_list;
static import core.simd;
static import std.conv;

struct Int128 { long lower; long upper; }
struct UInt128 { ulong lower; ulong upper; }

struct __locale_data { int dummy; }



alias _Bool = bool;
struct dpp {
    static struct Opaque(int N) {
        void[N] bytes;
    }

    static bool isEmpty(T)() {
        return T.tupleof.length == 0;
    }
    static struct Move(T) {
        T* ptr;
    }


    static auto move(T)(ref T value) {
        return Move!T(&value);
    }
    mixin template EnumD(string name, T, string prefix) if(is(T == enum)) {
        private static string _memberMixinStr(string member) {
            import std.conv: text;
            import std.array: replace;
            return text(` `, member.replace(prefix, ""), ` = `, T.stringof, `.`, member, `,`);
        }
        private static string _enumMixinStr() {
            import std.array: join;
            string[] ret;
            ret ~= "enum " ~ name ~ "{";
            static foreach(member; __traits(allMembers, T)) {
                ret ~= _memberMixinStr(member);
            }
            ret ~= "}";
            return ret.join("\n");
        }
        mixin(_enumMixinStr());
    }
}

extern(C)
{
    alias wchar_t = int;
    alias size_t = c_ulong;
    alias ptrdiff_t = c_long;
    struct max_align_t
    {
        long __clang_max_align_nonce1;
        real __clang_max_align_nonce2;
    }
    alias uintmax_t = c_ulong;
    alias intmax_t = c_long;
    alias uintptr_t = c_ulong;
    alias intptr_t = c_long;
    alias uint_fast64_t = c_ulong;
    alias uint_fast32_t = c_ulong;
    alias uint_fast16_t = c_ulong;
    alias uint_fast8_t = ubyte;
    alias int_fast64_t = c_long;
    alias int_fast32_t = c_long;
    alias int_fast16_t = c_long;
    alias int_fast8_t = byte;
    alias uint_least64_t = c_ulong;
    alias uint_least32_t = uint;
    alias uint_least16_t = ushort;
    alias uint_least8_t = ubyte;
    alias int_least64_t = c_long;
    alias int_least32_t = int;
    alias int_least16_t = short;
    alias int_least8_t = byte;
    gpr_allocation_functions gpr_get_allocation_functions() @nogc nothrow;
    void gpr_set_allocation_functions(gpr_allocation_functions) @nogc nothrow;
    void gpr_free_aligned(void*) @nogc nothrow;
    void* gpr_malloc_aligned(c_ulong, c_ulong) @nogc nothrow;
    void* gpr_realloc(void*, c_ulong) @nogc nothrow;
    void gpr_free(void*) @nogc nothrow;
    void* gpr_zalloc(c_ulong) @nogc nothrow;
    void* gpr_malloc(c_ulong) @nogc nothrow;
    struct gpr_allocation_functions
    {
        void* function(c_ulong) malloc_fn;
        void* function(c_ulong) zalloc_fn;
        void* function(void*, c_ulong) realloc_fn;
        void function(void*) free_fn;
    }
    alias __sig_atomic_t = int;
    alias __socklen_t = uint;
    alias __intptr_t = c_long;
    alias __caddr_t = char*;
    alias __loff_t = c_long;
    alias __syscall_ulong_t = c_ulong;
    alias __syscall_slong_t = c_long;
    alias __ssize_t = c_long;
    alias __fsword_t = c_long;
    alias __fsfilcnt64_t = c_ulong;
    alias __fsfilcnt_t = c_ulong;
    alias __fsblkcnt64_t = c_ulong;
    alias __fsblkcnt_t = c_ulong;
    alias __blkcnt64_t = c_long;
    alias __blkcnt_t = c_long;
    alias __blksize_t = c_long;
    alias __timer_t = void*;
    alias __clockid_t = int;
    alias __key_t = int;
    alias __daddr_t = int;
    alias __suseconds_t = c_long;
    alias __useconds_t = uint;
    alias __time_t = c_long;
    alias __id_t = uint;
    alias __rlim64_t = c_ulong;
    alias __rlim_t = c_ulong;
    alias __clock_t = c_long;
    struct __fsid_t
    {
        int[2] __val;
    }
    alias __pid_t = int;
    alias __off64_t = c_long;
    alias __off_t = c_long;
    alias __nlink_t = c_ulong;
    alias int8_t = byte;
    alias int16_t = short;
    alias int32_t = int;
    alias int64_t = c_long;
    alias uint8_t = ubyte;
    alias uint16_t = ushort;
    alias uint32_t = uint;
    alias uint64_t = ulong;
    alias __mode_t = uint;
    alias __ino64_t = c_ulong;
    alias __u_char = ubyte;
    alias __u_short = ushort;
    alias __u_int = uint;
    alias __u_long = c_ulong;
    alias __int8_t = byte;
    alias __uint8_t = ubyte;
    alias __int16_t = short;
    alias __uint16_t = ushort;
    alias __int32_t = int;
    alias __uint32_t = uint;
    alias __int64_t = c_long;
    alias __uint64_t = c_ulong;
    alias __int_least8_t = byte;
    alias __uint_least8_t = ubyte;
    alias __int_least16_t = short;
    alias __uint_least16_t = ushort;
    alias __int_least32_t = int;
    alias __uint_least32_t = uint;
    alias __int_least64_t = c_long;
    alias __uint_least64_t = c_ulong;
    alias __quad_t = c_long;
    alias __u_quad_t = c_ulong;
    alias __intmax_t = c_long;
    alias __uintmax_t = c_ulong;
    alias __ino_t = c_ulong;
    alias __gid_t = uint;
    alias __uid_t = uint;
    alias __dev_t = c_ulong;
    static if(!is(typeof(_BITS_TYPES_H))) {
        enum _BITS_TYPES_H = 1;
    }
    static if(!is(typeof(_BITS_TIME64_H))) {
        enum _BITS_TIME64_H = 1;
    }




    static if(!is(typeof(_BITS_STDINT_UINTN_H))) {
        enum _BITS_STDINT_UINTN_H = 1;
    }




    static if(!is(typeof(_BITS_STDINT_INTN_H))) {
        enum _BITS_STDINT_INTN_H = 1;
    }




    static if(!is(typeof(__GLIBC_USE_IEC_60559_TYPES_EXT))) {
        enum __GLIBC_USE_IEC_60559_TYPES_EXT = 1;
    }




    static if(!is(typeof(__GLIBC_USE_IEC_60559_FUNCS_EXT))) {
        enum __GLIBC_USE_IEC_60559_FUNCS_EXT = 1;
    }




    static if(!is(typeof(__GLIBC_USE_IEC_60559_BFP_EXT))) {
        enum __GLIBC_USE_IEC_60559_BFP_EXT = 1;
    }




    static if(!is(typeof(__GLIBC_USE_LIB_EXT2))) {
        enum __GLIBC_USE_LIB_EXT2 = 1;
    }






    static if(!is(typeof(_BITS_TYPESIZES_H))) {
        enum _BITS_TYPESIZES_H = 1;
    }
    static if(!is(typeof(__OFF_T_MATCHES_OFF64_T))) {
        enum __OFF_T_MATCHES_OFF64_T = 1;
    }




    static if(!is(typeof(__INO_T_MATCHES_INO64_T))) {
        enum __INO_T_MATCHES_INO64_T = 1;
    }




    static if(!is(typeof(__RLIM_T_MATCHES_RLIM64_T))) {
        enum __RLIM_T_MATCHES_RLIM64_T = 1;
    }




    static if(!is(typeof(__FD_SETSIZE))) {
        enum __FD_SETSIZE = 1024;
    }




    static if(!is(typeof(_BITS_WCHAR_H))) {
        enum _BITS_WCHAR_H = 1;
    }
    static if(!is(typeof(__WORDSIZE))) {
        enum __WORDSIZE = 64;
    }




    static if(!is(typeof(__WORDSIZE_TIME64_COMPAT32))) {
        enum __WORDSIZE_TIME64_COMPAT32 = 1;
    }




    static if(!is(typeof(__SYSCALL_WORDSIZE))) {
        enum __SYSCALL_WORDSIZE = 64;
    }




    static if(!is(typeof(_FEATURES_H))) {
        enum _FEATURES_H = 1;
    }
    static if(!is(typeof(_ISOC95_SOURCE))) {
        enum _ISOC95_SOURCE = 1;
    }




    static if(!is(typeof(_ISOC99_SOURCE))) {
        enum _ISOC99_SOURCE = 1;
    }




    static if(!is(typeof(_ISOC11_SOURCE))) {
        enum _ISOC11_SOURCE = 1;
    }




    static if(!is(typeof(_POSIX_SOURCE))) {
        enum _POSIX_SOURCE = 1;
    }




    static if(!is(typeof(_POSIX_C_SOURCE))) {
        enum _POSIX_C_SOURCE = 200809L;
    }




    static if(!is(typeof(_XOPEN_SOURCE))) {
        enum _XOPEN_SOURCE = 700;
    }




    static if(!is(typeof(_XOPEN_SOURCE_EXTENDED))) {
        enum _XOPEN_SOURCE_EXTENDED = 1;
    }




    static if(!is(typeof(_LARGEFILE64_SOURCE))) {
        enum _LARGEFILE64_SOURCE = 1;
    }




    static if(!is(typeof(_DEFAULT_SOURCE))) {
        enum _DEFAULT_SOURCE = 1;
    }




    static if(!is(typeof(_ATFILE_SOURCE))) {
        enum _ATFILE_SOURCE = 1;
    }




    static if(!is(typeof(__USE_ISOC11))) {
        enum __USE_ISOC11 = 1;
    }




    static if(!is(typeof(__USE_ISOC99))) {
        enum __USE_ISOC99 = 1;
    }




    static if(!is(typeof(__USE_ISOC95))) {
        enum __USE_ISOC95 = 1;
    }




    static if(!is(typeof(__USE_POSIX))) {
        enum __USE_POSIX = 1;
    }




    static if(!is(typeof(__USE_POSIX2))) {
        enum __USE_POSIX2 = 1;
    }




    static if(!is(typeof(__USE_POSIX199309))) {
        enum __USE_POSIX199309 = 1;
    }




    static if(!is(typeof(__USE_POSIX199506))) {
        enum __USE_POSIX199506 = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K))) {
        enum __USE_XOPEN2K = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K8))) {
        enum __USE_XOPEN2K8 = 1;
    }




    static if(!is(typeof(__USE_XOPEN))) {
        enum __USE_XOPEN = 1;
    }




    static if(!is(typeof(__USE_XOPEN_EXTENDED))) {
        enum __USE_XOPEN_EXTENDED = 1;
    }




    static if(!is(typeof(__USE_UNIX98))) {
        enum __USE_UNIX98 = 1;
    }




    static if(!is(typeof(_LARGEFILE_SOURCE))) {
        enum _LARGEFILE_SOURCE = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K8XSI))) {
        enum __USE_XOPEN2K8XSI = 1;
    }




    static if(!is(typeof(__USE_XOPEN2KXSI))) {
        enum __USE_XOPEN2KXSI = 1;
    }




    static if(!is(typeof(__USE_LARGEFILE))) {
        enum __USE_LARGEFILE = 1;
    }




    static if(!is(typeof(__USE_LARGEFILE64))) {
        enum __USE_LARGEFILE64 = 1;
    }




    static if(!is(typeof(__USE_MISC))) {
        enum __USE_MISC = 1;
    }




    static if(!is(typeof(__USE_ATFILE))) {
        enum __USE_ATFILE = 1;
    }




    static if(!is(typeof(__USE_GNU))) {
        enum __USE_GNU = 1;
    }




    static if(!is(typeof(__USE_FORTIFY_LEVEL))) {
        enum __USE_FORTIFY_LEVEL = 0;
    }




    static if(!is(typeof(__GLIBC_USE_DEPRECATED_GETS))) {
        enum __GLIBC_USE_DEPRECATED_GETS = 0;
    }




    static if(!is(typeof(__GLIBC_USE_DEPRECATED_SCANF))) {
        enum __GLIBC_USE_DEPRECATED_SCANF = 0;
    }




    static if(!is(typeof(__GNU_LIBRARY__))) {
        enum __GNU_LIBRARY__ = 6;
    }




    static if(!is(typeof(__GLIBC__))) {
        enum __GLIBC__ = 2;
    }




    static if(!is(typeof(__GLIBC_MINOR__))) {
        enum __GLIBC_MINOR__ = 29;
    }
    static if(!is(typeof(GRPC_USE_CPP_STD_LIB))) {
        enum GRPC_USE_CPP_STD_LIB = 1;
    }




    static if(!is(typeof(GPR_PLATFORM_STRING))) {
        enum GPR_PLATFORM_STRING = "linux";
    }
    static if(!is(typeof(GPR_CPU_LINUX))) {
        enum GPR_CPU_LINUX = 1;
    }




    static if(!is(typeof(GPR_GCC_ATOMIC))) {
        enum GPR_GCC_ATOMIC = 1;
    }




    static if(!is(typeof(GPR_GCC_TLS))) {
        enum GPR_GCC_TLS = 1;
    }




    static if(!is(typeof(GPR_LINUX))) {
        enum GPR_LINUX = 1;
    }






    static if(!is(typeof(GPR_SUPPORT_CHANNELS_FROM_FD))) {
        enum GPR_SUPPORT_CHANNELS_FROM_FD = 1;
    }




    static if(!is(typeof(GPR_LINUX_ENV))) {
        enum GPR_LINUX_ENV = 1;
    }




    static if(!is(typeof(GPR_POSIX_TMPFILE))) {
        enum GPR_POSIX_TMPFILE = 1;
    }




    static if(!is(typeof(GPR_POSIX_STRING))) {
        enum GPR_POSIX_STRING = 1;
    }




    static if(!is(typeof(GPR_POSIX_SUBPROCESS))) {
        enum GPR_POSIX_SUBPROCESS = 1;
    }




    static if(!is(typeof(GPR_POSIX_SYNC))) {
        enum GPR_POSIX_SYNC = 1;
    }




    static if(!is(typeof(GPR_POSIX_TIME))) {
        enum GPR_POSIX_TIME = 1;
    }




    static if(!is(typeof(GPR_HAS_PTHREAD_H))) {
        enum GPR_HAS_PTHREAD_H = 1;
    }




    static if(!is(typeof(GPR_GETPID_IN_UNISTD_H))) {
        enum GPR_GETPID_IN_UNISTD_H = 1;
    }




    static if(!is(typeof(GPR_ARCH_64))) {
        enum GPR_ARCH_64 = 1;
    }




    static if(!is(typeof(GPR_POSIX_CRASH_HANDLER))) {
        enum GPR_POSIX_CRASH_HANDLER = 1;
    }




    static if(!is(typeof(GPR_LINUX_PTHREAD_NAME))) {
        enum GPR_LINUX_PTHREAD_NAME = 1;
    }






    static if(!is(typeof(GPR_CYCLE_COUNTER_FALLBACK))) {
        enum GPR_CYCLE_COUNTER_FALLBACK = 1;
    }




    static if(!is(typeof(GPR_CACHELINE_SIZE_LOG))) {
        enum GPR_CACHELINE_SIZE_LOG = 6;
    }






    static if(!is(typeof(GPR_MAX_ALIGNMENT))) {
        enum GPR_MAX_ALIGNMENT = 16;
    }




    static if(!is(typeof(GRPC_ARES))) {
        enum GRPC_ARES = 1;
    }




    static if(!is(typeof(GRPC_IF_NAMETOINDEX))) {
        enum GRPC_IF_NAMETOINDEX = 1;
    }
    static if(!is(typeof(GPR_HAS_ATTRIBUTE_NOINLINE))) {
        enum GPR_HAS_ATTRIBUTE_NOINLINE = 1;
    }






    static if(!is(typeof(GPR_HAS_ATTRIBUTE_WEAK))) {
        enum GPR_HAS_ATTRIBUTE_WEAK = 1;
    }






    static if(!is(typeof(GRPC_ALLOW_EXCEPTIONS))) {
        enum GRPC_ALLOW_EXCEPTIONS = 0;
    }
    static if(!is(typeof(LINUX_VERSION_CODE))) {
        enum LINUX_VERSION_CODE = 327936;
    }






    static if(!is(typeof(_STDC_PREDEF_H))) {
        enum _STDC_PREDEF_H = 1;
    }




    static if(!is(typeof(_STDINT_H))) {
        enum _STDINT_H = 1;
    }
    static if(!is(typeof(INT8_WIDTH))) {
        enum INT8_WIDTH = 8;
    }




    static if(!is(typeof(UINT8_WIDTH))) {
        enum UINT8_WIDTH = 8;
    }




    static if(!is(typeof(INT16_WIDTH))) {
        enum INT16_WIDTH = 16;
    }




    static if(!is(typeof(UINT16_WIDTH))) {
        enum UINT16_WIDTH = 16;
    }




    static if(!is(typeof(INT32_WIDTH))) {
        enum INT32_WIDTH = 32;
    }




    static if(!is(typeof(UINT32_WIDTH))) {
        enum UINT32_WIDTH = 32;
    }




    static if(!is(typeof(INT64_WIDTH))) {
        enum INT64_WIDTH = 64;
    }




    static if(!is(typeof(UINT64_WIDTH))) {
        enum UINT64_WIDTH = 64;
    }




    static if(!is(typeof(INT_LEAST8_WIDTH))) {
        enum INT_LEAST8_WIDTH = 8;
    }




    static if(!is(typeof(UINT_LEAST8_WIDTH))) {
        enum UINT_LEAST8_WIDTH = 8;
    }




    static if(!is(typeof(INT_LEAST16_WIDTH))) {
        enum INT_LEAST16_WIDTH = 16;
    }




    static if(!is(typeof(UINT_LEAST16_WIDTH))) {
        enum UINT_LEAST16_WIDTH = 16;
    }




    static if(!is(typeof(INT_LEAST32_WIDTH))) {
        enum INT_LEAST32_WIDTH = 32;
    }




    static if(!is(typeof(UINT_LEAST32_WIDTH))) {
        enum UINT_LEAST32_WIDTH = 32;
    }




    static if(!is(typeof(INT_LEAST64_WIDTH))) {
        enum INT_LEAST64_WIDTH = 64;
    }




    static if(!is(typeof(UINT_LEAST64_WIDTH))) {
        enum UINT_LEAST64_WIDTH = 64;
    }




    static if(!is(typeof(INT_FAST8_WIDTH))) {
        enum INT_FAST8_WIDTH = 8;
    }




    static if(!is(typeof(UINT_FAST8_WIDTH))) {
        enum UINT_FAST8_WIDTH = 8;
    }
    static if(!is(typeof(INT_FAST64_WIDTH))) {
        enum INT_FAST64_WIDTH = 64;
    }




    static if(!is(typeof(UINT_FAST64_WIDTH))) {
        enum UINT_FAST64_WIDTH = 64;
    }
    static if(!is(typeof(INTMAX_WIDTH))) {
        enum INTMAX_WIDTH = 64;
    }




    static if(!is(typeof(UINTMAX_WIDTH))) {
        enum UINTMAX_WIDTH = 64;
    }






    static if(!is(typeof(SIG_ATOMIC_WIDTH))) {
        enum SIG_ATOMIC_WIDTH = 32;
    }






    static if(!is(typeof(WCHAR_WIDTH))) {
        enum WCHAR_WIDTH = 32;
    }




    static if(!is(typeof(WINT_WIDTH))) {
        enum WINT_WIDTH = 32;
    }




    static if(!is(typeof(_SYS_CDEFS_H))) {
        enum _SYS_CDEFS_H = 1;
    }
    static if(!is(typeof(__glibc_c99_flexarr_available))) {
        enum __glibc_c99_flexarr_available = 1;
    }
    static if(!is(typeof(__HAVE_GENERIC_SELECTION))) {
        enum __HAVE_GENERIC_SELECTION = 1;
    }
}
