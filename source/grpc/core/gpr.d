module grpc.core.gpr;
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

extern(C++) {
    void grpc_prefork() @nogc nothrow;
    void grpc_postfork_parent() @nogc nothrow;
    void grpc_postfork_child() @nogc nothrow;
    void grpc_fork_handlers_auto_register() @nogc nothrow;
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
    alias fsfilcnt64_t = c_ulong;
    alias fsblkcnt64_t = c_ulong;
    alias blkcnt64_t = c_long;
    alias fsfilcnt_t = c_ulong;
    alias fsblkcnt_t = c_ulong;
    alias blkcnt_t = c_long;
    alias blksize_t = c_long;
    alias register_t = c_long;
    alias u_int64_t = c_ulong;
    alias u_int32_t = uint;
    alias u_int16_t = ushort;
    alias u_int8_t = ubyte;
    alias suseconds_t = c_long;
    alias useconds_t = uint;
    alias key_t = int;
    alias caddr_t = char*;
    alias daddr_t = int;
    alias ssize_t = c_long;
    alias id_t = uint;
    alias pid_t = int;
    alias off64_t = c_long;
    alias off_t = c_long;
    alias uid_t = uint;
    alias nlink_t = c_ulong;
    alias mode_t = uint;
    alias gid_t = uint;
    alias dev_t = c_ulong;
    alias ino64_t = c_ulong;
    alias ino_t = c_ulong;
    alias loff_t = c_long;
    alias fsid_t = __fsid_t;
    alias u_quad_t = c_ulong;
    alias quad_t = c_long;
    alias u_long = c_ulong;
    alias u_int = uint;
    alias u_short = ushort;
    alias u_char = ubyte;
    int pselect(int, fd_set*, fd_set*, fd_set*, const(timespec)*, const(__sigset_t)*) @nogc nothrow;
    int select(int, fd_set*, fd_set*, fd_set*, timeval*) @nogc nothrow;
    alias fd_mask = c_long;
    struct fd_set
    {
        c_long[16] fds_bits;
    }
    alias __fd_mask = c_long;
    int getloadavg(double*, int) @nogc nothrow;
    int getpt() @nogc nothrow;
    int ptsname_r(int, char*, c_ulong) @nogc nothrow;
    char* ptsname(int) @nogc nothrow;
    int unlockpt(int) @nogc nothrow;
    int grantpt(int) @nogc nothrow;
    int posix_openpt(int) @nogc nothrow;
    int getsubopt(char**, char**, char**) @nogc nothrow;
    int rpmatch(const(char)*) @nogc nothrow;
    c_ulong wcstombs(char*, const(int)*, c_ulong) @nogc nothrow;
    c_ulong mbstowcs(int*, const(char)*, c_ulong) @nogc nothrow;
    int wctomb(char*, int) @nogc nothrow;
    int mbtowc(int*, const(char)*, c_ulong) @nogc nothrow;
    int mblen(const(char)*, c_ulong) @nogc nothrow;
    int qfcvt_r(real, int, int*, int*, char*, c_ulong) @nogc nothrow;
    int qecvt_r(real, int, int*, int*, char*, c_ulong) @nogc nothrow;
    int fcvt_r(double, int, int*, int*, char*, c_ulong) @nogc nothrow;
    int ecvt_r(double, int, int*, int*, char*, c_ulong) @nogc nothrow;
    char* qgcvt(real, int, char*) @nogc nothrow;
    char* qfcvt(real, int, int*, int*) @nogc nothrow;
    char* qecvt(real, int, int*, int*) @nogc nothrow;
    char* gcvt(double, int, char*) @nogc nothrow;
    char* fcvt(double, int, int*, int*) @nogc nothrow;
    char* ecvt(double, int, int*, int*) @nogc nothrow;
    lldiv_t lldiv(long, long) @nogc nothrow;
    ldiv_t ldiv(c_long, c_long) @nogc nothrow;
    div_t div(int, int) @nogc nothrow;
    long llabs(long) @nogc nothrow;
    c_long labs(c_long) @nogc nothrow;
    int abs(int) @nogc nothrow;
    void qsort_r(void*, c_ulong, c_ulong, int function(const(void)*, const(void)*, void*), void*) @nogc nothrow;
    void qsort(void*, c_ulong, c_ulong, int function(const(void)*, const(void)*)) @nogc nothrow;
    void* bsearch(const(void)*, const(void)*, c_ulong, c_ulong, int function(const(void)*, const(void)*)) @nogc nothrow;
    alias __compar_d_fn_t = int function(const(void)*, const(void)*, void*);
    alias comparison_fn_t = int function(const(void)*, const(void)*);
    alias __compar_fn_t = int function(const(void)*, const(void)*);
    char* realpath(const(char)*, char*) @nogc nothrow;
    char* canonicalize_file_name(const(char)*) @nogc nothrow;
    int system(const(char)*) @nogc nothrow;
    int mkostemps64(char*, int, int) @nogc nothrow;
    pragma(mangle, "alloca") void* alloca_(c_ulong) @nogc nothrow;
    int mkostemps(char*, int, int) @nogc nothrow;
    static ushort __bswap_16(ushort) @nogc nothrow;
    static uint __bswap_32(uint) @nogc nothrow;
    static c_ulong __bswap_64(c_ulong) @nogc nothrow;
    int mkostemp64(char*, int) @nogc nothrow;
    int mkostemp(char*, int) @nogc nothrow;
    char* mkdtemp(char*) @nogc nothrow;
    int mkstemps64(char*, int) @nogc nothrow;
    int mkstemps(char*, int) @nogc nothrow;
    int mkstemp64(char*) @nogc nothrow;
    alias _Float32 = float;
    int mkstemp(char*) @nogc nothrow;
    alias _Float64 = double;
    char* mktemp(char*) @nogc nothrow;
    alias _Float32x = double;
    alias _Float64x = real;
    int clearenv() @nogc nothrow;
    int unsetenv(const(char)*) @nogc nothrow;
    int setenv(const(char)*, const(char)*, int) @nogc nothrow;
    int putenv(char*) @nogc nothrow;
    char* secure_getenv(const(char)*) @nogc nothrow;
    char* getenv(const(char)*) @nogc nothrow;
    void _Exit(int) @nogc nothrow;
    void quick_exit(int) @nogc nothrow;
    void exit(int) @nogc nothrow;
    int on_exit(void function(int, void*), void*) @nogc nothrow;
    struct __pthread_rwlock_arch_t
    {
        uint __readers;
        uint __writers;
        uint __wrphase_futex;
        uint __writers_futex;
        uint __pad3;
        uint __pad4;
        int __cur_writer;
        int __shared;
        byte __rwelision;
        ubyte[7] __pad1;
        c_ulong __pad2;
        uint __flags;
    }
    int at_quick_exit(void function()) @nogc nothrow;
    alias pthread_t = c_ulong;
    union pthread_mutexattr_t
    {
        char[4] __size;
        int __align;
    }
    union pthread_condattr_t
    {
        char[4] __size;
        int __align;
    }
    alias pthread_key_t = uint;
    alias pthread_once_t = int;
    union pthread_attr_t
    {
        char[56] __size;
        c_long __align;
    }
    union pthread_mutex_t
    {
        __pthread_mutex_s __data;
        char[40] __size;
        c_long __align;
    }
    union pthread_cond_t
    {
        __pthread_cond_s __data;
        char[48] __size;
        long __align;
    }
    union pthread_rwlock_t
    {
        __pthread_rwlock_arch_t __data;
        char[56] __size;
        c_long __align;
    }
    union pthread_rwlockattr_t
    {
        char[8] __size;
        c_long __align;
    }
    alias pthread_spinlock_t = int;
    union pthread_barrier_t
    {
        char[32] __size;
        c_long __align;
    }
    union pthread_barrierattr_t
    {
        char[4] __size;
        int __align;
    }
    int atexit(void function()) @nogc nothrow;
    void abort() @nogc nothrow;
    alias int8_t = byte;
    alias int16_t = short;
    alias int32_t = int;
    alias int64_t = c_long;
    alias uint8_t = ubyte;
    alias uint16_t = ushort;
    alias uint32_t = uint;
    alias uint64_t = ulong;
    alias __pthread_list_t = __pthread_internal_list;
    struct __pthread_internal_list
    {
        __pthread_internal_list* __prev;
        __pthread_internal_list* __next;
    }
    void* aligned_alloc(c_ulong, c_ulong) @nogc nothrow;
    struct __pthread_mutex_s
    {
        int __lock;
        uint __count;
        int __owner;
        uint __nusers;
        int __kind;
        short __spins;
        short __elision;
        __pthread_internal_list __list;
    }
    struct __pthread_cond_s
    {
        static union _Anonymous_0
        {
            ulong __wseq;
            static struct _Anonymous_1
            {
                uint __low;
                uint __high;
            }
            _Anonymous_1 __wseq32;
        }
        _Anonymous_0 _anonymous_2;
        auto __wseq() @property @nogc pure nothrow { return _anonymous_2.__wseq; }
        void __wseq(_T_)(auto ref _T_ val) @property @nogc pure nothrow { _anonymous_2.__wseq = val; }
        auto __wseq32() @property @nogc pure nothrow { return _anonymous_2.__wseq32; }
        void __wseq32(_T_)(auto ref _T_ val) @property @nogc pure nothrow { _anonymous_2.__wseq32 = val; }
        static union _Anonymous_3
        {
            ulong __g1_start;
            static struct _Anonymous_4
            {
                uint __low;
                uint __high;
            }
            _Anonymous_4 __g1_start32;
        }
        _Anonymous_3 _anonymous_5;
        auto __g1_start() @property @nogc pure nothrow { return _anonymous_5.__g1_start; }
        void __g1_start(_T_)(auto ref _T_ val) @property @nogc pure nothrow { _anonymous_5.__g1_start = val; }
        auto __g1_start32() @property @nogc pure nothrow { return _anonymous_5.__g1_start32; }
        void __g1_start32(_T_)(auto ref _T_ val) @property @nogc pure nothrow { _anonymous_5.__g1_start32 = val; }
        uint[2] __g_refs;
        uint[2] __g_size;
        uint __g1_orig_size;
        uint __wrefs;
        uint[2] __g_signals;
    }
    int posix_memalign(void**, c_ulong, c_ulong) @nogc nothrow;
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
    void* valloc(c_ulong) @nogc nothrow;
    void free(void*) @nogc nothrow;
    alias __dev_t = c_ulong;
    alias __uid_t = uint;
    alias __gid_t = uint;
    alias __ino_t = c_ulong;
    alias __ino64_t = c_ulong;
    alias __mode_t = uint;
    alias __nlink_t = c_ulong;
    alias __off_t = c_long;
    alias __off64_t = c_long;
    alias __pid_t = int;
    struct __fsid_t
    {
        int[2] __val;
    }
    alias __clock_t = c_long;
    alias __rlim_t = c_ulong;
    alias __rlim64_t = c_ulong;
    alias __id_t = uint;
    alias __time_t = c_long;
    alias __useconds_t = uint;
    alias __suseconds_t = c_long;
    alias __daddr_t = int;
    alias __key_t = int;
    alias __clockid_t = int;
    alias __timer_t = void*;
    alias __blksize_t = c_long;
    alias __blkcnt_t = c_long;
    alias __blkcnt64_t = c_long;
    alias __fsblkcnt_t = c_ulong;
    alias __fsblkcnt64_t = c_ulong;
    alias __fsfilcnt_t = c_ulong;
    alias __fsfilcnt64_t = c_ulong;
    alias __fsword_t = c_long;
    alias __ssize_t = c_long;
    alias __syscall_slong_t = c_long;
    alias __syscall_ulong_t = c_ulong;
    alias __loff_t = c_long;
    alias __caddr_t = char*;
    alias __intptr_t = c_long;
    alias __socklen_t = uint;
    alias __sig_atomic_t = int;
    struct __locale_struct
    {
        __locale_data*[13] __locales;
        const(ushort)* __ctype_b;
        const(int)* __ctype_tolower;
        const(int)* __ctype_toupper;
        const(char)*[13] __names;
    }
    alias __locale_t = __locale_struct*;
    void* reallocarray(void*, c_ulong, c_ulong) @nogc nothrow;
    struct __sigset_t
    {
        c_ulong[16] __val;
    }
    alias clock_t = c_long;
    alias clockid_t = int;
    alias locale_t = __locale_struct*;
    void* realloc(void*, c_ulong) @nogc nothrow;
    alias sigset_t = __sigset_t;
    struct timespec
    {
        c_long tv_sec;
        c_long tv_nsec;
    }
    struct timeval
    {
        c_long tv_sec;
        c_long tv_usec;
    }
    alias time_t = c_long;
    alias timer_t = void*;
    void* calloc(c_ulong, c_ulong) @nogc nothrow;
    void* malloc(c_ulong) @nogc nothrow;
    int lcong48_r(ushort*, drand48_data*) @nogc nothrow;
    int seed48_r(ushort*, drand48_data*) @nogc nothrow;
    int srand48_r(c_long, drand48_data*) @nogc nothrow;
    int jrand48_r(ushort*, drand48_data*, c_long*) @nogc nothrow;
    int mrand48_r(drand48_data*, c_long*) @nogc nothrow;
    int nrand48_r(ushort*, drand48_data*, c_long*) @nogc nothrow;
    int lrand48_r(drand48_data*, c_long*) @nogc nothrow;
    int erand48_r(ushort*, drand48_data*, double*) @nogc nothrow;
    int drand48_r(drand48_data*, double*) @nogc nothrow;
    struct drand48_data
    {
        ushort[3] __x;
        ushort[3] __old_x;
        ushort __c;
        ushort __init;
        ulong __a;
    }
    void lcong48(ushort*) @nogc nothrow;
    static ushort __uint16_identity(ushort) @nogc nothrow;
    static uint __uint32_identity(uint) @nogc nothrow;
    static c_ulong __uint64_identity(c_ulong) @nogc nothrow;
    ushort* seed48(ushort*) @nogc nothrow;
    void srand48(c_long) @nogc nothrow;
    c_long jrand48(ushort*) @nogc nothrow;
    c_long mrand48() @nogc nothrow;
    c_long nrand48(ushort*) @nogc nothrow;
    c_long lrand48() @nogc nothrow;
    double erand48(ushort*) @nogc nothrow;
    double drand48() @nogc nothrow;
    int rand_r(uint*) @nogc nothrow;
    void srand(uint) @nogc nothrow;
    int rand() @nogc nothrow;
    int setstate_r(char*, random_data*) @nogc nothrow;
    int initstate_r(uint, char*, c_ulong, random_data*) @nogc nothrow;
    int srandom_r(uint, random_data*) @nogc nothrow;
    int random_r(random_data*, int*) @nogc nothrow;
    struct random_data
    {
        int* fptr;
        int* rptr;
        int* state;
        int rand_type;
        int rand_deg;
        int rand_sep;
        int* end_ptr;
    }
    char* setstate(char*) @nogc nothrow;
    char* initstate(uint, char*, c_ulong) @nogc nothrow;
    void srandom(uint) @nogc nothrow;
    c_long random() @nogc nothrow;
    c_long a64l(const(char)*) @nogc nothrow;
    char* l64a(c_long) @nogc nothrow;
    real strtof64x_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    double strtof32x_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    double strtof64_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    float strtof32_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    real strtold_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    float strtof_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    double strtod_l(const(char)*, char**, __locale_struct*) @nogc nothrow;
    ulong strtoull_l(const(char)*, char**, int, __locale_struct*) @nogc nothrow;
    long strtoll_l(const(char)*, char**, int, __locale_struct*) @nogc nothrow;
    c_ulong strtoul_l(const(char)*, char**, int, __locale_struct*) @nogc nothrow;
    c_long strtol_l(const(char)*, char**, int, __locale_struct*) @nogc nothrow;
    int strfromf64x(char*, c_ulong, const(char)*, real) @nogc nothrow;
    int strfromf32x(char*, c_ulong, const(char)*, double) @nogc nothrow;
    int strfromf64(char*, c_ulong, const(char)*, double) @nogc nothrow;
    alias gpr_clock_type = _Anonymous_6;
    enum _Anonymous_6
    {
        GPR_CLOCK_MONOTONIC = 0,
        GPR_CLOCK_REALTIME = 1,
        GPR_CLOCK_PRECISE = 2,
        GPR_TIMESPAN = 3,
    }
    enum GPR_CLOCK_MONOTONIC = _Anonymous_6.GPR_CLOCK_MONOTONIC;
    enum GPR_CLOCK_REALTIME = _Anonymous_6.GPR_CLOCK_REALTIME;
    enum GPR_CLOCK_PRECISE = _Anonymous_6.GPR_CLOCK_PRECISE;
    enum GPR_TIMESPAN = _Anonymous_6.GPR_TIMESPAN;
    struct gpr_timespec
    {
        c_long tv_sec;
        int tv_nsec;
        gpr_clock_type clock_type;
    }
    enum gpr_log_severity
    {
        GPR_LOG_SEVERITY_DEBUG = 0,
        GPR_LOG_SEVERITY_INFO = 1,
        GPR_LOG_SEVERITY_ERROR = 2,
    }
    enum GPR_LOG_SEVERITY_DEBUG = gpr_log_severity.GPR_LOG_SEVERITY_DEBUG;
    enum GPR_LOG_SEVERITY_INFO = gpr_log_severity.GPR_LOG_SEVERITY_INFO;
    enum GPR_LOG_SEVERITY_ERROR = gpr_log_severity.GPR_LOG_SEVERITY_ERROR;
    const(char)* gpr_log_severity_string(gpr_log_severity) @nogc nothrow;
    int strfromf32(char*, c_ulong, const(char)*, float) @nogc nothrow;
    void gpr_log(const(char)*, int, gpr_log_severity, const(char)*, ...) @nogc nothrow;
    int gpr_should_log(gpr_log_severity) @nogc nothrow;
    void gpr_log_message(const(char)*, int, gpr_log_severity, const(char)*) @nogc nothrow;
    void gpr_set_log_verbosity(gpr_log_severity) @nogc nothrow;
    void gpr_log_verbosity_init() @nogc nothrow;
    struct gpr_log_func_args
    {
        const(char)* file;
        int line;
        gpr_log_severity severity;
        const(char)* message;
    }
    alias gpr_log_func = void function(gpr_log_func_args*);
    void gpr_set_log_function(void function(gpr_log_func_args*)) @nogc nothrow;
    int strfroml(char*, c_ulong, const(char)*, real) @nogc nothrow;
    int strfromf(char*, c_ulong, const(char)*, float) @nogc nothrow;
    int strfromd(char*, c_ulong, const(char)*, double) @nogc nothrow;
    ulong strtoull(const(char)*, char**, int) @nogc nothrow;
    long strtoll(const(char)*, char**, int) @nogc nothrow;
    ulong strtouq(const(char)*, char**, int) @nogc nothrow;
    long strtoq(const(char)*, char**, int) @nogc nothrow;
    c_ulong strtoul(const(char)*, char**, int) @nogc nothrow;
    c_long strtol(const(char)*, char**, int) @nogc nothrow;
    real strtof64x(const(char)*, char**) @nogc nothrow;
    double strtof32x(const(char)*, char**) @nogc nothrow;
    double strtof64(const(char)*, char**) @nogc nothrow;
    alias grpc_status_code = _Anonymous_7;
    enum _Anonymous_7
    {
        GRPC_STATUS_OK = 0,
        GRPC_STATUS_CANCELLED = 1,
        GRPC_STATUS_UNKNOWN = 2,
        GRPC_STATUS_INVALID_ARGUMENT = 3,
        GRPC_STATUS_DEADLINE_EXCEEDED = 4,
        GRPC_STATUS_NOT_FOUND = 5,
        GRPC_STATUS_ALREADY_EXISTS = 6,
        GRPC_STATUS_PERMISSION_DENIED = 7,
        GRPC_STATUS_UNAUTHENTICATED = 16,
        GRPC_STATUS_RESOURCE_EXHAUSTED = 8,
        GRPC_STATUS_FAILED_PRECONDITION = 9,
        GRPC_STATUS_ABORTED = 10,
        GRPC_STATUS_OUT_OF_RANGE = 11,
        GRPC_STATUS_UNIMPLEMENTED = 12,
        GRPC_STATUS_INTERNAL = 13,
        GRPC_STATUS_UNAVAILABLE = 14,
        GRPC_STATUS_DATA_LOSS = 15,
        GRPC_STATUS__DO_NOT_USE = -1,
    }
    enum GRPC_STATUS_OK = _Anonymous_7.GRPC_STATUS_OK;
    enum GRPC_STATUS_CANCELLED = _Anonymous_7.GRPC_STATUS_CANCELLED;
    enum GRPC_STATUS_UNKNOWN = _Anonymous_7.GRPC_STATUS_UNKNOWN;
    enum GRPC_STATUS_INVALID_ARGUMENT = _Anonymous_7.GRPC_STATUS_INVALID_ARGUMENT;
    enum GRPC_STATUS_DEADLINE_EXCEEDED = _Anonymous_7.GRPC_STATUS_DEADLINE_EXCEEDED;
    enum GRPC_STATUS_NOT_FOUND = _Anonymous_7.GRPC_STATUS_NOT_FOUND;
    enum GRPC_STATUS_ALREADY_EXISTS = _Anonymous_7.GRPC_STATUS_ALREADY_EXISTS;
    enum GRPC_STATUS_PERMISSION_DENIED = _Anonymous_7.GRPC_STATUS_PERMISSION_DENIED;
    enum GRPC_STATUS_UNAUTHENTICATED = _Anonymous_7.GRPC_STATUS_UNAUTHENTICATED;
    enum GRPC_STATUS_RESOURCE_EXHAUSTED = _Anonymous_7.GRPC_STATUS_RESOURCE_EXHAUSTED;
    enum GRPC_STATUS_FAILED_PRECONDITION = _Anonymous_7.GRPC_STATUS_FAILED_PRECONDITION;
    enum GRPC_STATUS_ABORTED = _Anonymous_7.GRPC_STATUS_ABORTED;
    enum GRPC_STATUS_OUT_OF_RANGE = _Anonymous_7.GRPC_STATUS_OUT_OF_RANGE;
    enum GRPC_STATUS_UNIMPLEMENTED = _Anonymous_7.GRPC_STATUS_UNIMPLEMENTED;
    enum GRPC_STATUS_INTERNAL = _Anonymous_7.GRPC_STATUS_INTERNAL;
    enum GRPC_STATUS_UNAVAILABLE = _Anonymous_7.GRPC_STATUS_UNAVAILABLE;
    enum GRPC_STATUS_DATA_LOSS = _Anonymous_7.GRPC_STATUS_DATA_LOSS;
    enum GRPC_STATUS__DO_NOT_USE = _Anonymous_7.GRPC_STATUS__DO_NOT_USE;
    float strtof32(const(char)*, char**) @nogc nothrow;
    alias int_least8_t = byte;
    alias int_least16_t = short;
    alias int_least32_t = int;
    alias int_least64_t = c_long;
    alias uint_least8_t = ubyte;
    alias uint_least16_t = ushort;
    alias uint_least32_t = uint;
    alias uint_least64_t = c_ulong;
    alias int_fast8_t = byte;
    alias int_fast16_t = c_long;
    alias int_fast32_t = c_long;
    alias int_fast64_t = c_long;
    alias uint_fast8_t = ubyte;
    alias uint_fast16_t = c_ulong;
    alias uint_fast32_t = c_ulong;
    alias uint_fast64_t = c_ulong;
    alias intptr_t = c_long;
    real strtold(const(char)*, char**) @nogc nothrow;
    alias uintptr_t = c_ulong;
    alias intmax_t = c_long;
    alias uintmax_t = c_ulong;
    float strtof(const(char)*, char**) @nogc nothrow;
    double strtod(const(char)*, char**) @nogc nothrow;
    long atoll(const(char)*) @nogc nothrow;
    c_long atol(const(char)*) @nogc nothrow;
    int atoi(const(char)*) @nogc nothrow;
    double atof(const(char)*) @nogc nothrow;
    c_ulong __ctype_get_mb_cur_max() @nogc nothrow;
    struct lldiv_t
    {
        long quot;
        long rem;
    }
    struct ldiv_t
    {
        c_long quot;
        c_long rem;
    }
    struct div_t
    {
        int quot;
        int rem;
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
    static if(!is(typeof(_STDLIB_H))) {
        enum _STDLIB_H = 1;
    }
    static if(!is(typeof(__ldiv_t_defined))) {
        enum __ldiv_t_defined = 1;
    }
    static if(!is(typeof(__lldiv_t_defined))) {
        enum __lldiv_t_defined = 1;
    }




    static if(!is(typeof(RAND_MAX))) {
        enum RAND_MAX = 2147483647;
    }




    static if(!is(typeof(EXIT_FAILURE))) {
        enum EXIT_FAILURE = 1;
    }




    static if(!is(typeof(EXIT_SUCCESS))) {
        enum EXIT_SUCCESS = 0;
    }
    static if(!is(typeof(_STDINT_H))) {
        enum _STDINT_H = 1;
    }




    static if(!is(typeof(_STDC_PREDEF_H))) {
        enum _STDC_PREDEF_H = 1;
    }






    static if(!is(typeof(LINUX_VERSION_CODE))) {
        enum LINUX_VERSION_CODE = 328449;
    }
    static if(!is(typeof(GRPC_ALLOW_EXCEPTIONS))) {
        enum GRPC_ALLOW_EXCEPTIONS = 0;
    }






    static if(!is(typeof(GPR_HAS_ATTRIBUTE_WEAK))) {
        enum GPR_HAS_ATTRIBUTE_WEAK = 1;
    }






    static if(!is(typeof(GPR_HAS_ATTRIBUTE_NOINLINE))) {
        enum GPR_HAS_ATTRIBUTE_NOINLINE = 1;
    }
    static if(!is(typeof(GRPC_IF_NAMETOINDEX))) {
        enum GRPC_IF_NAMETOINDEX = 1;
    }




    static if(!is(typeof(GRPC_ARES))) {
        enum GRPC_ARES = 1;
    }




    static if(!is(typeof(GPR_MAX_ALIGNMENT))) {
        enum GPR_MAX_ALIGNMENT = 16;
    }






    static if(!is(typeof(GPR_CACHELINE_SIZE_LOG))) {
        enum GPR_CACHELINE_SIZE_LOG = 6;
    }




    static if(!is(typeof(GPR_CYCLE_COUNTER_FALLBACK))) {
        enum GPR_CYCLE_COUNTER_FALLBACK = 1;
    }






    static if(!is(typeof(GPR_LINUX_PTHREAD_NAME))) {
        enum GPR_LINUX_PTHREAD_NAME = 1;
    }




    static if(!is(typeof(GPR_POSIX_CRASH_HANDLER))) {
        enum GPR_POSIX_CRASH_HANDLER = 1;
    }




    static if(!is(typeof(GPR_ARCH_64))) {
        enum GPR_ARCH_64 = 1;
    }




    static if(!is(typeof(GPR_GETPID_IN_UNISTD_H))) {
        enum GPR_GETPID_IN_UNISTD_H = 1;
    }




    static if(!is(typeof(GPR_HAS_PTHREAD_H))) {
        enum GPR_HAS_PTHREAD_H = 1;
    }




    static if(!is(typeof(GPR_POSIX_TIME))) {
        enum GPR_POSIX_TIME = 1;
    }




    static if(!is(typeof(GPR_POSIX_SYNC))) {
        enum GPR_POSIX_SYNC = 1;
    }




    static if(!is(typeof(GPR_POSIX_SUBPROCESS))) {
        enum GPR_POSIX_SUBPROCESS = 1;
    }




    static if(!is(typeof(GPR_POSIX_STRING))) {
        enum GPR_POSIX_STRING = 1;
    }




    static if(!is(typeof(GPR_POSIX_TMPFILE))) {
        enum GPR_POSIX_TMPFILE = 1;
    }




    static if(!is(typeof(GPR_LINUX_ENV))) {
        enum GPR_LINUX_ENV = 1;
    }




    static if(!is(typeof(GPR_SUPPORT_CHANNELS_FROM_FD))) {
        enum GPR_SUPPORT_CHANNELS_FROM_FD = 1;
    }






    static if(!is(typeof(GPR_LINUX))) {
        enum GPR_LINUX = 1;
    }




    static if(!is(typeof(GPR_GCC_TLS))) {
        enum GPR_GCC_TLS = 1;
    }




    static if(!is(typeof(GPR_GCC_ATOMIC))) {
        enum GPR_GCC_ATOMIC = 1;
    }




    static if(!is(typeof(GPR_CPU_LINUX))) {
        enum GPR_CPU_LINUX = 1;
    }
    static if(!is(typeof(GPR_PLATFORM_STRING))) {
        enum GPR_PLATFORM_STRING = "linux";
    }




    static if(!is(typeof(GRPC_USE_CPP_STD_LIB))) {
        enum GRPC_USE_CPP_STD_LIB = 1;
    }
    static if(!is(typeof(__GLIBC_MINOR__))) {
        enum __GLIBC_MINOR__ = 30;
    }




    static if(!is(typeof(__GLIBC__))) {
        enum __GLIBC__ = 2;
    }




    static if(!is(typeof(__GNU_LIBRARY__))) {
        enum __GNU_LIBRARY__ = 6;
    }




    static if(!is(typeof(__GLIBC_USE_DEPRECATED_SCANF))) {
        enum __GLIBC_USE_DEPRECATED_SCANF = 0;
    }




    static if(!is(typeof(__GLIBC_USE_DEPRECATED_GETS))) {
        enum __GLIBC_USE_DEPRECATED_GETS = 0;
    }




    static if(!is(typeof(__USE_FORTIFY_LEVEL))) {
        enum __USE_FORTIFY_LEVEL = 0;
    }




    static if(!is(typeof(__USE_GNU))) {
        enum __USE_GNU = 1;
    }




    static if(!is(typeof(__USE_ATFILE))) {
        enum __USE_ATFILE = 1;
    }




    static if(!is(typeof(__USE_MISC))) {
        enum __USE_MISC = 1;
    }




    static if(!is(typeof(__USE_LARGEFILE64))) {
        enum __USE_LARGEFILE64 = 1;
    }




    static if(!is(typeof(__USE_LARGEFILE))) {
        enum __USE_LARGEFILE = 1;
    }




    static if(!is(typeof(__USE_ISOC99))) {
        enum __USE_ISOC99 = 1;
    }




    static if(!is(typeof(__USE_ISOC95))) {
        enum __USE_ISOC95 = 1;
    }




    static if(!is(typeof(__USE_XOPEN2KXSI))) {
        enum __USE_XOPEN2KXSI = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K))) {
        enum __USE_XOPEN2K = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K8XSI))) {
        enum __USE_XOPEN2K8XSI = 1;
    }




    static if(!is(typeof(__USE_XOPEN2K8))) {
        enum __USE_XOPEN2K8 = 1;
    }




    static if(!is(typeof(_LARGEFILE_SOURCE))) {
        enum _LARGEFILE_SOURCE = 1;
    }




    static if(!is(typeof(__USE_UNIX98))) {
        enum __USE_UNIX98 = 1;
    }




    static if(!is(typeof(__USE_XOPEN_EXTENDED))) {
        enum __USE_XOPEN_EXTENDED = 1;
    }




    static if(!is(typeof(__USE_XOPEN))) {
        enum __USE_XOPEN = 1;
    }




    static if(!is(typeof(_ATFILE_SOURCE))) {
        enum _ATFILE_SOURCE = 1;
    }




    static if(!is(typeof(__USE_POSIX199506))) {
        enum __USE_POSIX199506 = 1;
    }




    static if(!is(typeof(__USE_POSIX199309))) {
        enum __USE_POSIX199309 = 1;
    }




    static if(!is(typeof(__USE_POSIX2))) {
        enum __USE_POSIX2 = 1;
    }




    static if(!is(typeof(__USE_POSIX))) {
        enum __USE_POSIX = 1;
    }




    static if(!is(typeof(_POSIX_C_SOURCE))) {
        enum _POSIX_C_SOURCE = 200809L;
    }




    static if(!is(typeof(_POSIX_SOURCE))) {
        enum _POSIX_SOURCE = 1;
    }




    static if(!is(typeof(__USE_ISOC11))) {
        enum __USE_ISOC11 = 1;
    }




    static if(!is(typeof(_LARGEFILE64_SOURCE))) {
        enum _LARGEFILE64_SOURCE = 1;
    }




    static if(!is(typeof(_XOPEN_SOURCE_EXTENDED))) {
        enum _XOPEN_SOURCE_EXTENDED = 1;
    }




    static if(!is(typeof(_XOPEN_SOURCE))) {
        enum _XOPEN_SOURCE = 700;
    }




    static if(!is(typeof(_ISOC11_SOURCE))) {
        enum _ISOC11_SOURCE = 1;
    }




    static if(!is(typeof(_ISOC99_SOURCE))) {
        enum _ISOC99_SOURCE = 1;
    }




    static if(!is(typeof(_ISOC95_SOURCE))) {
        enum _ISOC95_SOURCE = 1;
    }
    static if(!is(typeof(_FEATURES_H))) {
        enum _FEATURES_H = 1;
    }
    static if(!is(typeof(__PDP_ENDIAN))) {
        enum __PDP_ENDIAN = 3412;
    }




    static if(!is(typeof(__BIG_ENDIAN))) {
        enum __BIG_ENDIAN = 4321;
    }




    static if(!is(typeof(__LITTLE_ENDIAN))) {
        enum __LITTLE_ENDIAN = 1234;
    }




    static if(!is(typeof(_ENDIAN_H))) {
        enum _ENDIAN_H = 1;
    }




    static if(!is(typeof(__SYSCALL_WORDSIZE))) {
        enum __SYSCALL_WORDSIZE = 64;
    }




    static if(!is(typeof(__WORDSIZE_TIME64_COMPAT32))) {
        enum __WORDSIZE_TIME64_COMPAT32 = 1;
    }




    static if(!is(typeof(__WORDSIZE))) {
        enum __WORDSIZE = 64;
    }
    static if(!is(typeof(_BITS_WCHAR_H))) {
        enum _BITS_WCHAR_H = 1;
    }




    static if(!is(typeof(__WCOREFLAG))) {
        enum __WCOREFLAG = 0x80;
    }




    static if(!is(typeof(__W_CONTINUED))) {
        enum __W_CONTINUED = 0xffff;
    }
    static if(!is(typeof(__WCLONE))) {
        enum __WCLONE = 0x80000000;
    }




    static if(!is(typeof(__WALL))) {
        enum __WALL = 0x40000000;
    }




    static if(!is(typeof(__WNOTHREAD))) {
        enum __WNOTHREAD = 0x20000000;
    }




    static if(!is(typeof(WNOWAIT))) {
        enum WNOWAIT = 0x01000000;
    }




    static if(!is(typeof(WCONTINUED))) {
        enum WCONTINUED = 8;
    }




    static if(!is(typeof(WEXITED))) {
        enum WEXITED = 4;
    }




    static if(!is(typeof(WSTOPPED))) {
        enum WSTOPPED = 2;
    }




    static if(!is(typeof(WUNTRACED))) {
        enum WUNTRACED = 2;
    }




    static if(!is(typeof(WNOHANG))) {
        enum WNOHANG = 1;
    }




    static if(!is(typeof(_BITS_UINTN_IDENTITY_H))) {
        enum _BITS_UINTN_IDENTITY_H = 1;
    }




    static if(!is(typeof(__FD_SETSIZE))) {
        enum __FD_SETSIZE = 1024;
    }




    static if(!is(typeof(__RLIM_T_MATCHES_RLIM64_T))) {
        enum __RLIM_T_MATCHES_RLIM64_T = 1;
    }




    static if(!is(typeof(__INO_T_MATCHES_INO64_T))) {
        enum __INO_T_MATCHES_INO64_T = 1;
    }




    static if(!is(typeof(__OFF_T_MATCHES_OFF64_T))) {
        enum __OFF_T_MATCHES_OFF64_T = 1;
    }
    static if(!is(typeof(_BITS_TYPESIZES_H))) {
        enum _BITS_TYPESIZES_H = 1;
    }




    static if(!is(typeof(__timer_t_defined))) {
        enum __timer_t_defined = 1;
    }




    static if(!is(typeof(__time_t_defined))) {
        enum __time_t_defined = 1;
    }




    static if(!is(typeof(__timeval_defined))) {
        enum __timeval_defined = 1;
    }




    static if(!is(typeof(_STRUCT_TIMESPEC))) {
        enum _STRUCT_TIMESPEC = 1;
    }




    static if(!is(typeof(__sigset_t_defined))) {
        enum __sigset_t_defined = 1;
    }




    static if(!is(typeof(_BITS_TYPES_LOCALE_T_H))) {
        enum _BITS_TYPES_LOCALE_T_H = 1;
    }




    static if(!is(typeof(__clockid_t_defined))) {
        enum __clockid_t_defined = 1;
    }




    static if(!is(typeof(__clock_t_defined))) {
        enum __clock_t_defined = 1;
    }
    static if(!is(typeof(_BITS_TYPES___LOCALE_T_H))) {
        enum _BITS_TYPES___LOCALE_T_H = 1;
    }
    static if(!is(typeof(_BITS_TYPES_H))) {
        enum _BITS_TYPES_H = 1;
    }
    static if(!is(typeof(_BITS_TIME64_H))) {
        enum _BITS_TIME64_H = 1;
    }




    static if(!is(typeof(__PTHREAD_MUTEX_HAVE_PREV))) {
        enum __PTHREAD_MUTEX_HAVE_PREV = 1;
    }
    static if(!is(typeof(_THREAD_SHARED_TYPES_H))) {
        enum _THREAD_SHARED_TYPES_H = 1;
    }




    static if(!is(typeof(_BITS_STDINT_UINTN_H))) {
        enum _BITS_STDINT_UINTN_H = 1;
    }




    static if(!is(typeof(_BITS_STDINT_INTN_H))) {
        enum _BITS_STDINT_INTN_H = 1;
    }
    static if(!is(typeof(__FD_ZERO_STOS))) {
        enum __FD_ZERO_STOS = "stosq";
    }




    static if(!is(typeof(__have_pthread_attr_t))) {
        enum __have_pthread_attr_t = 1;
    }




    static if(!is(typeof(_BITS_PTHREADTYPES_COMMON_H))) {
        enum _BITS_PTHREADTYPES_COMMON_H = 1;
    }




    static if(!is(typeof(__PTHREAD_RWLOCK_INT_FLAGS_SHARED))) {
        enum __PTHREAD_RWLOCK_INT_FLAGS_SHARED = 1;
    }
    static if(!is(typeof(__PTHREAD_MUTEX_USE_UNION))) {
        enum __PTHREAD_MUTEX_USE_UNION = 0;
    }




    static if(!is(typeof(__PTHREAD_MUTEX_NUSERS_AFTER_KIND))) {
        enum __PTHREAD_MUTEX_NUSERS_AFTER_KIND = 0;
    }




    static if(!is(typeof(__PTHREAD_MUTEX_LOCK_ELISION))) {
        enum __PTHREAD_MUTEX_LOCK_ELISION = 1;
    }
    static if(!is(typeof(__SIZEOF_PTHREAD_BARRIERATTR_T))) {
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_RWLOCKATTR_T))) {
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_CONDATTR_T))) {
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_COND_T))) {
        enum __SIZEOF_PTHREAD_COND_T = 48;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_MUTEXATTR_T))) {
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_BARRIER_T))) {
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_RWLOCK_T))) {
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_MUTEX_T))) {
        enum __SIZEOF_PTHREAD_MUTEX_T = 40;
    }




    static if(!is(typeof(__SIZEOF_PTHREAD_ATTR_T))) {
        enum __SIZEOF_PTHREAD_ATTR_T = 56;
    }




    static if(!is(typeof(_BITS_PTHREADTYPES_ARCH_H))) {
        enum _BITS_PTHREADTYPES_ARCH_H = 1;
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




    static if(!is(typeof(__HAVE_FLOAT64X_LONG_DOUBLE))) {
        enum __HAVE_FLOAT64X_LONG_DOUBLE = 1;
    }




    static if(!is(typeof(__HAVE_FLOAT64X))) {
        enum __HAVE_FLOAT64X = 1;
    }




    static if(!is(typeof(__HAVE_DISTINCT_FLOAT128))) {
        enum __HAVE_DISTINCT_FLOAT128 = 0;
    }




    static if(!is(typeof(__HAVE_FLOAT128))) {
        enum __HAVE_FLOAT128 = 0;
    }
    static if(!is(typeof(__HAVE_FLOATN_NOT_TYPEDEF))) {
        enum __HAVE_FLOATN_NOT_TYPEDEF = 0;
    }
    static if(!is(typeof(__HAVE_DISTINCT_FLOAT64X))) {
        enum __HAVE_DISTINCT_FLOAT64X = 0;
    }




    static if(!is(typeof(__HAVE_DISTINCT_FLOAT32X))) {
        enum __HAVE_DISTINCT_FLOAT32X = 0;
    }




    static if(!is(typeof(__HAVE_DISTINCT_FLOAT64))) {
        enum __HAVE_DISTINCT_FLOAT64 = 0;
    }




    static if(!is(typeof(__HAVE_DISTINCT_FLOAT32))) {
        enum __HAVE_DISTINCT_FLOAT32 = 0;
    }






    static if(!is(typeof(__HAVE_FLOAT128X))) {
        enum __HAVE_FLOAT128X = 0;
    }




    static if(!is(typeof(__HAVE_FLOAT32X))) {
        enum __HAVE_FLOAT32X = 1;
    }




    static if(!is(typeof(__HAVE_FLOAT64))) {
        enum __HAVE_FLOAT64 = 1;
    }




    static if(!is(typeof(__HAVE_FLOAT32))) {
        enum __HAVE_FLOAT32 = 1;
    }




    static if(!is(typeof(__HAVE_FLOAT16))) {
        enum __HAVE_FLOAT16 = 0;
    }
    static if(!is(typeof(_BITS_BYTESWAP_H))) {
        enum _BITS_BYTESWAP_H = 1;
    }






    static if(!is(typeof(_ALLOCA_H))) {
        enum _ALLOCA_H = 1;
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




    static if(!is(typeof(_SYS_SELECT_H))) {
        enum _SYS_SELECT_H = 1;
    }
    static if(!is(typeof(_SYS_TYPES_H))) {
        enum _SYS_TYPES_H = 1;
    }
    static if(!is(typeof(__BIT_TYPES_DEFINED__))) {
        enum __BIT_TYPES_DEFINED__ = 1;
    }
    static if(!is(typeof(__GNUC_VA_LIST))) {
        enum __GNUC_VA_LIST = 1;
    }
}
