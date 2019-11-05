module grpc.core.grpc_preproc;


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
    int getdate_r(const(char)*, tm*) @nogc nothrow;
    tm* getdate(const(char)*) @nogc nothrow;
    extern __gshared int getdate_err;
    int timespec_get(timespec*, int) @nogc nothrow;
    int timer_getoverrun(void*) @nogc nothrow;
    int timer_gettime(void*, itimerspec*) @nogc nothrow;
    int timer_settime(void*, int, const(itimerspec)*, itimerspec*) @nogc nothrow;
    int timer_delete(void*) @nogc nothrow;
    int timer_create(int, sigevent*, void**) @nogc nothrow;
    int clock_getcpuclockid(int, int*) @nogc nothrow;
    int clock_nanosleep(int, int, const(timespec)*, timespec*) @nogc nothrow;
    int clock_settime(int, const(timespec)*) @nogc nothrow;
    int clock_gettime(int, timespec*) @nogc nothrow;
    int clock_getres(int, timespec*) @nogc nothrow;
    int nanosleep(const(timespec)*, timespec*) @nogc nothrow;
    int dysize(int) @nogc nothrow;
    c_long timelocal(tm*) @nogc nothrow;
    c_long timegm(tm*) @nogc nothrow;
    int stime(const(c_long)*) @nogc nothrow;
    extern __gshared c_long timezone;
    extern __gshared int daylight;
    void tzset() @nogc nothrow;
    extern __gshared char*[2] tzname;
    extern __gshared c_long __timezone;
    extern __gshared int __daylight;
    extern __gshared char*[2] __tzname;
    char* ctime_r(const(c_long)*, char*) @nogc nothrow;
    char* asctime_r(const(tm)*, char*) @nogc nothrow;
    char* ctime(const(c_long)*) @nogc nothrow;
    char* asctime(const(tm)*) @nogc nothrow;
    tm* localtime_r(const(c_long)*, tm*) @nogc nothrow;
    tm* gmtime_r(const(c_long)*, tm*) @nogc nothrow;
    tm* localtime(const(c_long)*) @nogc nothrow;
    tm* gmtime(const(c_long)*) @nogc nothrow;
    char* strptime_l(const(char)*, const(char)*, tm*, __locale_struct*) @nogc nothrow;
    c_ulong strftime_l(char*, c_ulong, const(char)*, const(tm)*, __locale_struct*) @nogc nothrow;
    char* strptime(const(char)*, const(char)*, tm*) @nogc nothrow;
    c_ulong strftime(char*, c_ulong, const(char)*, const(tm)*) @nogc nothrow;
    c_long mktime(tm*) @nogc nothrow;
    double difftime(c_long, c_long) @nogc nothrow;
    c_long time(c_long*) @nogc nothrow;
    c_long clock() @nogc nothrow;
    struct sigevent;
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
    int sched_getaffinity(int, c_ulong, cpu_set_t*) @nogc nothrow;
    int sched_setaffinity(int, c_ulong, const(cpu_set_t)*) @nogc nothrow;
    int sched_rr_get_interval(int, timespec*) @nogc nothrow;
    int sched_get_priority_min(int) @nogc nothrow;
    int sched_get_priority_max(int) @nogc nothrow;
    int sched_yield() @nogc nothrow;
    int sched_getscheduler(int) @nogc nothrow;
    int sched_setscheduler(int, int, const(sched_param)*) @nogc nothrow;
    int sched_getparam(int, sched_param*) @nogc nothrow;
    int sched_setparam(int, const(sched_param)*) @nogc nothrow;
    alias pid_t = int;
    int pthread_atfork(void function(), void function(), void function()) @nogc nothrow;
    int pthread_getcpuclockid(c_ulong, int*) @nogc nothrow;
    int pthread_setspecific(uint, const(void)*) @nogc nothrow;
    void* pthread_getspecific(uint) @nogc nothrow;
    int pthread_key_delete(uint) @nogc nothrow;
    int pthread_key_create(uint*, void function(void*)) @nogc nothrow;
    int pthread_barrierattr_setpshared(pthread_barrierattr_t*, int) @nogc nothrow;
    int pthread_barrierattr_getpshared(const(pthread_barrierattr_t)*, int*) @nogc nothrow;
    int pthread_barrierattr_destroy(pthread_barrierattr_t*) @nogc nothrow;
    int pthread_barrierattr_init(pthread_barrierattr_t*) @nogc nothrow;
    int pthread_barrier_wait(pthread_barrier_t*) @nogc nothrow;
    int pthread_barrier_destroy(pthread_barrier_t*) @nogc nothrow;
    int pthread_barrier_init(pthread_barrier_t*, const(pthread_barrierattr_t)*, uint) @nogc nothrow;
    int pthread_spin_unlock(int*) @nogc nothrow;
    int pthread_spin_trylock(int*) @nogc nothrow;
    int pthread_spin_lock(int*) @nogc nothrow;
    int pthread_spin_destroy(int*) @nogc nothrow;
    int pthread_spin_init(int*, int) @nogc nothrow;
    int pthread_condattr_setclock(pthread_condattr_t*, int) @nogc nothrow;
    int pthread_condattr_getclock(const(pthread_condattr_t)*, int*) @nogc nothrow;
    int pthread_condattr_setpshared(pthread_condattr_t*, int) @nogc nothrow;
    static ushort __bswap_16(ushort) @nogc nothrow;
    int pthread_condattr_getpshared(const(pthread_condattr_t)*, int*) @nogc nothrow;
    static uint __bswap_32(uint) @nogc nothrow;
    static c_ulong __bswap_64(c_ulong) @nogc nothrow;
    int pthread_condattr_destroy(pthread_condattr_t*) @nogc nothrow;
    alias __cpu_mask = c_ulong;
    int pthread_condattr_init(pthread_condattr_t*) @nogc nothrow;
    struct cpu_set_t
    {
        c_ulong[16] __bits;
    }
    int pthread_cond_timedwait(pthread_cond_t*, pthread_mutex_t*, const(timespec)*) @nogc nothrow;
    int pthread_cond_wait(pthread_cond_t*, pthread_mutex_t*) @nogc nothrow;
    int pthread_cond_broadcast(pthread_cond_t*) @nogc nothrow;
    int pthread_cond_signal(pthread_cond_t*) @nogc nothrow;
    int __sched_cpucount(c_ulong, const(cpu_set_t)*) @nogc nothrow;
    cpu_set_t* __sched_cpualloc(c_ulong) @nogc nothrow;
    void __sched_cpufree(cpu_set_t*) @nogc nothrow;
    int pthread_cond_destroy(pthread_cond_t*) @nogc nothrow;
    int pthread_cond_init(pthread_cond_t*, const(pthread_condattr_t)*) @nogc nothrow;
    int pthread_rwlockattr_setkind_np(pthread_rwlockattr_t*, int) @nogc nothrow;
    int pthread_rwlockattr_getkind_np(const(pthread_rwlockattr_t)*, int*) @nogc nothrow;
    int pthread_rwlockattr_setpshared(pthread_rwlockattr_t*, int) @nogc nothrow;
    int pthread_rwlockattr_getpshared(const(pthread_rwlockattr_t)*, int*) @nogc nothrow;
    int pthread_rwlockattr_destroy(pthread_rwlockattr_t*) @nogc nothrow;
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
    int pthread_rwlockattr_init(pthread_rwlockattr_t*) @nogc nothrow;
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
    int pthread_rwlock_unlock(pthread_rwlock_t*) @nogc nothrow;
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
    int pthread_rwlock_timedwrlock(pthread_rwlock_t*, const(timespec)*) @nogc nothrow;
    int pthread_rwlock_trywrlock(pthread_rwlock_t*) @nogc nothrow;
    int pthread_rwlock_wrlock(pthread_rwlock_t*) @nogc nothrow;
    int pthread_rwlock_timedrdlock(pthread_rwlock_t*, const(timespec)*) @nogc nothrow;
    int pthread_rwlock_tryrdlock(pthread_rwlock_t*) @nogc nothrow;
    int pthread_rwlock_rdlock(pthread_rwlock_t*) @nogc nothrow;
    int pthread_rwlock_destroy(pthread_rwlock_t*) @nogc nothrow;
    int pthread_rwlock_init(pthread_rwlock_t*, const(pthread_rwlockattr_t)*) @nogc nothrow;
    int pthread_mutexattr_setrobust_np(pthread_mutexattr_t*, int) @nogc nothrow;
    int clone(int function(void*), void*, int, void*, ...) @nogc nothrow;
    int unshare(int) @nogc nothrow;
    int sched_getcpu() @nogc nothrow;
    int getcpu(uint*, uint*) @nogc nothrow;
    int setns(int, int) @nogc nothrow;
    alias __jmp_buf = c_long[8];
    int pthread_mutexattr_setrobust(pthread_mutexattr_t*, int) @nogc nothrow;
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
    int pthread_mutexattr_getrobust_np(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
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
    int pthread_mutexattr_getrobust(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
    int pthread_mutexattr_setprioceiling(pthread_mutexattr_t*, int) @nogc nothrow;
    int pthread_mutexattr_getprioceiling(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
    int pthread_mutexattr_setprotocol(pthread_mutexattr_t*, int) @nogc nothrow;
    int clock_adjtime(int, timex*) @nogc nothrow;
    int pthread_mutexattr_getprotocol(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
    int pthread_mutexattr_settype(pthread_mutexattr_t*, int) @nogc nothrow;
    struct timex
    {
        import std.bitmanip: bitfields;

        align(4):
        uint modes;
        c_long offset;
        c_long freq;
        c_long maxerror;
        c_long esterror;
        int status;
        c_long constant;
        c_long precision;
        c_long tolerance;
        timeval time;
        c_long tick;
        c_long ppsfreq;
        c_long jitter;
        int shift;
        c_long stabil;
        c_long jitcnt;
        c_long calcnt;
        c_long errcnt;
        c_long stbcnt;
        int tai;
        mixin(bitfields!(
            int, "_anonymous_6", 32,
            int, "_anonymous_7", 32,
        ));
        mixin(bitfields!(
            int, "_anonymous_8", 32,
            int, "_anonymous_9", 32,
        ));
        mixin(bitfields!(
            int, "_anonymous_10", 32,
            int, "_anonymous_11", 32,
        ));
        mixin(bitfields!(
            int, "_anonymous_12", 32,
            int, "_anonymous_13", 32,
        ));
        mixin(bitfields!(
            int, "_anonymous_14", 32,
            int, "_anonymous_15", 32,
        ));
        mixin(bitfields!(
            int, "_anonymous_16", 32,
        ));
    }
    int pthread_mutexattr_gettype(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
    int pthread_mutexattr_setpshared(pthread_mutexattr_t*, int) @nogc nothrow;
    int pthread_mutexattr_getpshared(const(pthread_mutexattr_t)*, int*) @nogc nothrow;
    int pthread_mutexattr_destroy(pthread_mutexattr_t*) @nogc nothrow;
    int pthread_mutexattr_init(pthread_mutexattr_t*) @nogc nothrow;
    int pthread_mutex_consistent_np(pthread_mutex_t*) @nogc nothrow;
    int pthread_mutex_consistent(pthread_mutex_t*) @nogc nothrow;
    int pthread_mutex_setprioceiling(pthread_mutex_t*, int, int*) @nogc nothrow;
    int pthread_mutex_getprioceiling(const(pthread_mutex_t)*, int*) @nogc nothrow;
    int pthread_mutex_unlock(pthread_mutex_t*) @nogc nothrow;
    int pthread_mutex_timedlock(pthread_mutex_t*, const(timespec)*) @nogc nothrow;
    int pthread_mutex_lock(pthread_mutex_t*) @nogc nothrow;
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
    int pthread_mutex_trylock(pthread_mutex_t*) @nogc nothrow;
    int pthread_mutex_destroy(pthread_mutex_t*) @nogc nothrow;
    int pthread_mutex_init(pthread_mutex_t*, const(pthread_mutexattr_t)*) @nogc nothrow;
    int __sigsetjmp(__jmp_buf_tag*, int) @nogc nothrow;
    struct __jmp_buf_tag;
    void __pthread_unwind_next(__pthread_unwind_buf_t*) @nogc nothrow;
    void __pthread_unregister_cancel_restore(__pthread_unwind_buf_t*) @nogc nothrow;
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
    void __pthread_register_cancel_defer(__pthread_unwind_buf_t*) @nogc nothrow;
    struct __locale_struct
    {
        __locale_data*[13] __locales;
        const(ushort)* __ctype_b;
        const(int)* __ctype_tolower;
        const(int)* __ctype_toupper;
        const(char)*[13] __names;
    }
    alias __locale_t = __locale_struct*;
    alias clock_t = c_long;
    alias clockid_t = int;
    void __pthread_unregister_cancel(__pthread_unwind_buf_t*) @nogc nothrow;
    alias locale_t = __locale_struct*;
    struct itimerspec
    {
        timespec it_interval;
        timespec it_value;
    }
    void __pthread_register_cancel(__pthread_unwind_buf_t*) @nogc nothrow;
    struct sched_param
    {
        int sched_priority;
    }
    struct timespec
    {
        c_long tv_sec;
        c_long tv_nsec;
    }
    struct __pthread_cleanup_frame
    {
        void function(void*) __cancel_routine;
        void* __cancel_arg;
        int __do_it;
        int __cancel_type;
    }
    struct timeval
    {
        c_long tv_sec;
        c_long tv_usec;
    }
    struct tm
    {
        int tm_sec;
        int tm_min;
        int tm_hour;
        int tm_mday;
        int tm_mon;
        int tm_year;
        int tm_wday;
        int tm_yday;
        int tm_isdst;
        c_long tm_gmtoff;
        const(char)* tm_zone;
    }
    struct __pthread_unwind_buf_t
    {
        static struct _Anonymous_17
        {
            c_long[8] __cancel_jmp_buf;
            int __mask_was_saved;
        }
        _Anonymous_17[1] __cancel_jmp_buf;
        void*[4] __pad;
    }
    alias time_t = c_long;
    void pthread_testcancel() @nogc nothrow;
    alias timer_t = void*;
    int pthread_cancel(c_ulong) @nogc nothrow;
    int pthread_setcanceltype(int, int*) @nogc nothrow;
    int pthread_setcancelstate(int, int*) @nogc nothrow;
    int pthread_once(int*, void function()) @nogc nothrow;
    int pthread_getaffinity_np(c_ulong, c_ulong, cpu_set_t*) @nogc nothrow;
    int pthread_setaffinity_np(c_ulong, c_ulong, const(cpu_set_t)*) @nogc nothrow;
    int pthread_yield() @nogc nothrow;
    int pthread_setconcurrency(int) @nogc nothrow;
    int pthread_getconcurrency() @nogc nothrow;
    int pthread_setname_np(c_ulong, const(char)*) @nogc nothrow;
    int pthread_getname_np(c_ulong, char*, c_ulong) @nogc nothrow;
    int pthread_setschedprio(c_ulong, int) @nogc nothrow;
    int pthread_getschedparam(c_ulong, int*, sched_param*) @nogc nothrow;
    int pthread_setschedparam(c_ulong, int, const(sched_param)*) @nogc nothrow;
    int pthread_getattr_np(c_ulong, pthread_attr_t*) @nogc nothrow;
    int pthread_setattr_default_np(const(pthread_attr_t)*) @nogc nothrow;
    static ushort __uint16_identity(ushort) @nogc nothrow;
    static uint __uint32_identity(uint) @nogc nothrow;
    static c_ulong __uint64_identity(c_ulong) @nogc nothrow;
    int pthread_getattr_default_np(pthread_attr_t*) @nogc nothrow;
    int pthread_attr_getaffinity_np(const(pthread_attr_t)*, c_ulong, cpu_set_t*) @nogc nothrow;
    int pthread_attr_setaffinity_np(pthread_attr_t*, c_ulong, const(cpu_set_t)*) @nogc nothrow;
    int pthread_attr_setstack(pthread_attr_t*, void*, c_ulong) @nogc nothrow;
    int pthread_attr_getstack(const(pthread_attr_t)*, void**, c_ulong*) @nogc nothrow;
    int pthread_attr_setstacksize(pthread_attr_t*, c_ulong) @nogc nothrow;
    int pthread_attr_getstacksize(const(pthread_attr_t)*, c_ulong*) @nogc nothrow;
    int pthread_attr_setstackaddr(pthread_attr_t*, void*) @nogc nothrow;
    int pthread_attr_getstackaddr(const(pthread_attr_t)*, void**) @nogc nothrow;
    int pthread_attr_setscope(pthread_attr_t*, int) @nogc nothrow;
    int pthread_attr_getscope(const(pthread_attr_t)*, int*) @nogc nothrow;
    int pthread_attr_setinheritsched(pthread_attr_t*, int) @nogc nothrow;
    int pthread_attr_getinheritsched(const(pthread_attr_t)*, int*) @nogc nothrow;
    int pthread_attr_setschedpolicy(pthread_attr_t*, int) @nogc nothrow;
    int pthread_attr_getschedpolicy(const(pthread_attr_t)*, int*) @nogc nothrow;
    int pthread_attr_setschedparam(pthread_attr_t*, const(sched_param)*) @nogc nothrow;
    int pthread_attr_getschedparam(const(pthread_attr_t)*, sched_param*) @nogc nothrow;
    int pthread_attr_setguardsize(pthread_attr_t*, c_ulong) @nogc nothrow;
    int pthread_attr_getguardsize(const(pthread_attr_t)*, c_ulong*) @nogc nothrow;
    int pthread_attr_setdetachstate(pthread_attr_t*, int) @nogc nothrow;
    int pthread_attr_getdetachstate(const(pthread_attr_t)*, int*) @nogc nothrow;
    int pthread_attr_destroy(pthread_attr_t*) @nogc nothrow;
    int pthread_attr_init(pthread_attr_t*) @nogc nothrow;
    int pthread_equal(c_ulong, c_ulong) @nogc nothrow;
    c_ulong pthread_self() @nogc nothrow;
    int pthread_detach(c_ulong) @nogc nothrow;
    int pthread_timedjoin_np(c_ulong, void**, const(timespec)*) @nogc nothrow;
    int pthread_tryjoin_np(c_ulong, void**) @nogc nothrow;
    int pthread_join(c_ulong, void**) @nogc nothrow;
    void pthread_exit(void*) @nogc nothrow;
    int pthread_create(c_ulong*, const(pthread_attr_t)*, void* function(void*), void*) @nogc nothrow;
    enum _Anonymous_18
    {
        PTHREAD_CANCEL_DEFERRED = 0,
        PTHREAD_CANCEL_ASYNCHRONOUS = 1,
    }
    enum PTHREAD_CANCEL_DEFERRED = _Anonymous_18.PTHREAD_CANCEL_DEFERRED;
    enum PTHREAD_CANCEL_ASYNCHRONOUS = _Anonymous_18.PTHREAD_CANCEL_ASYNCHRONOUS;
    enum _Anonymous_19
    {
        PTHREAD_CANCEL_ENABLE = 0,
        PTHREAD_CANCEL_DISABLE = 1,
    }
    enum PTHREAD_CANCEL_ENABLE = _Anonymous_19.PTHREAD_CANCEL_ENABLE;
    enum PTHREAD_CANCEL_DISABLE = _Anonymous_19.PTHREAD_CANCEL_DISABLE;
    struct _pthread_cleanup_buffer
    {
        void function(void*) __routine;
        void* __arg;
        int __canceltype;
        _pthread_cleanup_buffer* __prev;
    }
    enum _Anonymous_20
    {
        PTHREAD_PROCESS_PRIVATE = 0,
        PTHREAD_PROCESS_SHARED = 1,
    }
    enum PTHREAD_PROCESS_PRIVATE = _Anonymous_20.PTHREAD_PROCESS_PRIVATE;
    enum PTHREAD_PROCESS_SHARED = _Anonymous_20.PTHREAD_PROCESS_SHARED;
    enum _Anonymous_21
    {
        PTHREAD_SCOPE_SYSTEM = 0,
        PTHREAD_SCOPE_PROCESS = 1,
    }
    enum PTHREAD_SCOPE_SYSTEM = _Anonymous_21.PTHREAD_SCOPE_SYSTEM;
    enum PTHREAD_SCOPE_PROCESS = _Anonymous_21.PTHREAD_SCOPE_PROCESS;
    enum _Anonymous_22
    {
        PTHREAD_INHERIT_SCHED = 0,
        PTHREAD_EXPLICIT_SCHED = 1,
    }
    enum PTHREAD_INHERIT_SCHED = _Anonymous_22.PTHREAD_INHERIT_SCHED;
    enum PTHREAD_EXPLICIT_SCHED = _Anonymous_22.PTHREAD_EXPLICIT_SCHED;
    enum _Anonymous_23
    {
        PTHREAD_RWLOCK_PREFER_READER_NP = 0,
        PTHREAD_RWLOCK_PREFER_WRITER_NP = 1,
        PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP = 2,
        PTHREAD_RWLOCK_DEFAULT_NP = 0,
    }
    enum PTHREAD_RWLOCK_PREFER_READER_NP = _Anonymous_23.PTHREAD_RWLOCK_PREFER_READER_NP;
    enum PTHREAD_RWLOCK_PREFER_WRITER_NP = _Anonymous_23.PTHREAD_RWLOCK_PREFER_WRITER_NP;
    enum PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP = _Anonymous_23.PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP;
    enum PTHREAD_RWLOCK_DEFAULT_NP = _Anonymous_23.PTHREAD_RWLOCK_DEFAULT_NP;
    enum _Anonymous_24
    {
        PTHREAD_PRIO_NONE = 0,
        PTHREAD_PRIO_INHERIT = 1,
        PTHREAD_PRIO_PROTECT = 2,
    }
    enum PTHREAD_PRIO_NONE = _Anonymous_24.PTHREAD_PRIO_NONE;
    enum PTHREAD_PRIO_INHERIT = _Anonymous_24.PTHREAD_PRIO_INHERIT;
    enum PTHREAD_PRIO_PROTECT = _Anonymous_24.PTHREAD_PRIO_PROTECT;
    enum _Anonymous_25
    {
        PTHREAD_MUTEX_STALLED = 0,
        PTHREAD_MUTEX_STALLED_NP = 0,
        PTHREAD_MUTEX_ROBUST = 1,
        PTHREAD_MUTEX_ROBUST_NP = 1,
    }
    enum PTHREAD_MUTEX_STALLED = _Anonymous_25.PTHREAD_MUTEX_STALLED;
    enum PTHREAD_MUTEX_STALLED_NP = _Anonymous_25.PTHREAD_MUTEX_STALLED_NP;
    enum PTHREAD_MUTEX_ROBUST = _Anonymous_25.PTHREAD_MUTEX_ROBUST;
    enum PTHREAD_MUTEX_ROBUST_NP = _Anonymous_25.PTHREAD_MUTEX_ROBUST_NP;
    void grpc_metadata_array_init(grpc_metadata_array*) @nogc nothrow;
    void grpc_metadata_array_destroy(grpc_metadata_array*) @nogc nothrow;
    void grpc_call_details_init(grpc_call_details*) @nogc nothrow;
    void grpc_call_details_destroy(grpc_call_details*) @nogc nothrow;
    void grpc_register_plugin(void function(), void function()) @nogc nothrow;
    void grpc_init() @nogc nothrow;
    void grpc_shutdown() @nogc nothrow;
    int grpc_is_initialized() @nogc nothrow;
    void grpc_shutdown_blocking() @nogc nothrow;
    const(char)* grpc_version_string() @nogc nothrow;
    const(char)* grpc_g_stands_for() @nogc nothrow;
    const(grpc_completion_queue_factory)* grpc_completion_queue_factory_lookup(const(grpc_completion_queue_attributes)*) @nogc nothrow;
    grpc_completion_queue* grpc_completion_queue_create_for_next(void*) @nogc nothrow;
    grpc_completion_queue* grpc_completion_queue_create_for_pluck(void*) @nogc nothrow;
    grpc_completion_queue* grpc_completion_queue_create_for_callback(grpc_experimental_completion_queue_functor*, void*) @nogc nothrow;
    grpc_completion_queue* grpc_completion_queue_create(const(grpc_completion_queue_factory)*, const(grpc_completion_queue_attributes)*, void*) @nogc nothrow;
    grpc_event grpc_completion_queue_next(grpc_completion_queue*, gpr_timespec, void*) @nogc nothrow;
    grpc_event grpc_completion_queue_pluck(grpc_completion_queue*, void*, gpr_timespec, void*) @nogc nothrow;
    void grpc_completion_queue_shutdown(grpc_completion_queue*) @nogc nothrow;
    void grpc_completion_queue_destroy(grpc_completion_queue*) @nogc nothrow;
    void grpc_completion_queue_thread_local_cache_init(grpc_completion_queue*) @nogc nothrow;
    int grpc_completion_queue_thread_local_cache_flush(grpc_completion_queue*, void**, int*) @nogc nothrow;
    grpc_connectivity_state grpc_channel_check_connectivity_state(grpc_channel*, int) @nogc nothrow;
    int grpc_channel_num_external_connectivity_watchers(grpc_channel*) @nogc nothrow;
    void grpc_channel_watch_connectivity_state(grpc_channel*, grpc_connectivity_state, gpr_timespec, grpc_completion_queue*, void*) @nogc nothrow;
    int grpc_channel_support_connectivity_watcher(grpc_channel*) @nogc nothrow;
    grpc_call* grpc_channel_create_call(grpc_channel*, grpc_call*, uint, grpc_completion_queue*, grpc_slice, const(grpc_slice)*, gpr_timespec, void*) @nogc nothrow;
    void grpc_channel_ping(grpc_channel*, grpc_completion_queue*, void*, void*) @nogc nothrow;
    void* grpc_channel_register_call(grpc_channel*, const(char)*, const(char)*, void*) @nogc nothrow;
    grpc_call* grpc_channel_create_registered_call(grpc_channel*, grpc_call*, uint, grpc_completion_queue*, void*, gpr_timespec, void*) @nogc nothrow;
    void* grpc_call_arena_alloc(grpc_call*, c_ulong) @nogc nothrow;
    grpc_call_error grpc_call_start_batch(grpc_call*, const(grpc_op)*, c_ulong, void*, void*) @nogc nothrow;
    char* grpc_call_get_peer(grpc_call*) @nogc nothrow;
    struct census_context;
    void grpc_census_call_set_context(grpc_call*, census_context*) @nogc nothrow;
    census_context* grpc_census_call_get_context(grpc_call*) @nogc nothrow;
    char* grpc_channel_get_target(grpc_channel*) @nogc nothrow;
    void grpc_channel_get_info(grpc_channel*, const(grpc_channel_info)*) @nogc nothrow;
    void grpc_channel_reset_connect_backoff(grpc_channel*) @nogc nothrow;
    grpc_channel* grpc_insecure_channel_create(const(char)*, const(grpc_channel_args)*, void*) @nogc nothrow;
    grpc_channel* grpc_lame_client_channel_create(const(char)*, grpc_status_code, const(char)*) @nogc nothrow;
    void grpc_channel_destroy(grpc_channel*) @nogc nothrow;
    grpc_call_error grpc_call_cancel(grpc_call*, void*) @nogc nothrow;
    grpc_call_error grpc_call_cancel_with_status(grpc_call*, grpc_status_code, const(char)*, void*) @nogc nothrow;
    void grpc_call_ref(grpc_call*) @nogc nothrow;
    void grpc_call_unref(grpc_call*) @nogc nothrow;
    grpc_call_error grpc_server_request_call(grpc_server*, grpc_call**, grpc_call_details*, grpc_metadata_array*, grpc_completion_queue*, grpc_completion_queue*, void*) @nogc nothrow;
    alias grpc_server_register_method_payload_handling = _Anonymous_26;
    enum _Anonymous_26
    {
        GRPC_SRM_PAYLOAD_NONE = 0,
        GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER = 1,
    }
    enum GRPC_SRM_PAYLOAD_NONE = _Anonymous_26.GRPC_SRM_PAYLOAD_NONE;
    enum GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER = _Anonymous_26.GRPC_SRM_PAYLOAD_READ_INITIAL_BYTE_BUFFER;
    void* grpc_server_register_method(grpc_server*, const(char)*, const(char)*, grpc_server_register_method_payload_handling, uint) @nogc nothrow;
    grpc_call_error grpc_server_request_registered_call(grpc_server*, void*, grpc_call**, gpr_timespec*, grpc_metadata_array*, grpc_byte_buffer**, grpc_completion_queue*, grpc_completion_queue*, void*) @nogc nothrow;
    grpc_server* grpc_server_create(const(grpc_channel_args)*, void*) @nogc nothrow;
    void grpc_server_register_completion_queue(grpc_server*, grpc_completion_queue*, void*) @nogc nothrow;
    int grpc_server_add_insecure_http2_port(grpc_server*, const(char)*) @nogc nothrow;
    void grpc_server_start(grpc_server*) @nogc nothrow;
    void grpc_server_shutdown_and_notify(grpc_server*, grpc_completion_queue*, void*) @nogc nothrow;
    void grpc_server_cancel_all_calls(grpc_server*) @nogc nothrow;
    void grpc_server_destroy(grpc_server*) @nogc nothrow;
    int grpc_tracer_set_enabled(const(char)*, int) @nogc nothrow;
    int grpc_header_key_is_legal(grpc_slice) @nogc nothrow;
    int grpc_header_nonbin_value_is_legal(grpc_slice) @nogc nothrow;
    int grpc_is_binary_header(grpc_slice) @nogc nothrow;
    const(char)* grpc_call_error_to_string(grpc_call_error) @nogc nothrow;
    grpc_resource_quota* grpc_resource_quota_create(const(char)*) @nogc nothrow;
    void grpc_resource_quota_ref(grpc_resource_quota*) @nogc nothrow;
    void grpc_resource_quota_unref(grpc_resource_quota*) @nogc nothrow;
    void grpc_resource_quota_resize(grpc_resource_quota*, c_ulong) @nogc nothrow;
    void grpc_resource_quota_set_max_threads(grpc_resource_quota*, int) @nogc nothrow;
    const(grpc_arg_pointer_vtable)* grpc_resource_quota_arg_vtable() @nogc nothrow;
    char* grpc_channelz_get_top_channels(c_long) @nogc nothrow;
    char* grpc_channelz_get_servers(c_long) @nogc nothrow;
    char* grpc_channelz_get_server(c_long) @nogc nothrow;
    char* grpc_channelz_get_server_sockets(c_long, c_long, c_long) @nogc nothrow;
    char* grpc_channelz_get_channel(c_long) @nogc nothrow;
    char* grpc_channelz_get_subchannel(c_long) @nogc nothrow;
    char* grpc_channelz_get_socket(c_long) @nogc nothrow;
    enum _Anonymous_27
    {
        PTHREAD_MUTEX_TIMED_NP = 0,
        PTHREAD_MUTEX_RECURSIVE_NP = 1,
        PTHREAD_MUTEX_ERRORCHECK_NP = 2,
        PTHREAD_MUTEX_ADAPTIVE_NP = 3,
        PTHREAD_MUTEX_NORMAL = 0,
        PTHREAD_MUTEX_RECURSIVE = 1,
        PTHREAD_MUTEX_ERRORCHECK = 2,
        PTHREAD_MUTEX_DEFAULT = 0,
        PTHREAD_MUTEX_FAST_NP = 0,
    }
    enum PTHREAD_MUTEX_TIMED_NP = _Anonymous_27.PTHREAD_MUTEX_TIMED_NP;
    enum PTHREAD_MUTEX_RECURSIVE_NP = _Anonymous_27.PTHREAD_MUTEX_RECURSIVE_NP;
    enum PTHREAD_MUTEX_ERRORCHECK_NP = _Anonymous_27.PTHREAD_MUTEX_ERRORCHECK_NP;
    enum PTHREAD_MUTEX_ADAPTIVE_NP = _Anonymous_27.PTHREAD_MUTEX_ADAPTIVE_NP;
    enum PTHREAD_MUTEX_NORMAL = _Anonymous_27.PTHREAD_MUTEX_NORMAL;
    enum PTHREAD_MUTEX_RECURSIVE = _Anonymous_27.PTHREAD_MUTEX_RECURSIVE;
    enum PTHREAD_MUTEX_ERRORCHECK = _Anonymous_27.PTHREAD_MUTEX_ERRORCHECK;
    enum PTHREAD_MUTEX_DEFAULT = _Anonymous_27.PTHREAD_MUTEX_DEFAULT;
    enum PTHREAD_MUTEX_FAST_NP = _Anonymous_27.PTHREAD_MUTEX_FAST_NP;
    c_long gpr_atm_no_barrier_clamped_add(c_long*, c_long, c_long, c_long) @nogc nothrow;
    enum _Anonymous_28
    {
        PTHREAD_CREATE_JOINABLE = 0,
        PTHREAD_CREATE_DETACHED = 1,
    }
    enum PTHREAD_CREATE_JOINABLE = _Anonymous_28.PTHREAD_CREATE_JOINABLE;
    enum PTHREAD_CREATE_DETACHED = _Anonymous_28.PTHREAD_CREATE_DETACHED;
    alias gpr_atm = c_long;
    double gpr_timespec_to_micros(gpr_timespec) @nogc nothrow;
    void gpr_sleep_until(gpr_timespec) @nogc nothrow;
    static int gpr_atm_no_barrier_cas(c_long*, c_long, c_long) @nogc nothrow;
    static int gpr_atm_acq_cas(c_long*, c_long, c_long) @nogc nothrow;
    static int gpr_atm_rel_cas(c_long*, c_long, c_long) @nogc nothrow;
    static int gpr_atm_full_cas(c_long*, c_long, c_long) @nogc nothrow;
    int gpr_time_similar(gpr_timespec, gpr_timespec, gpr_timespec) @nogc nothrow;
    grpc_byte_buffer* grpc_raw_byte_buffer_create(grpc_slice*, c_ulong) @nogc nothrow;
    grpc_byte_buffer* grpc_raw_compressed_byte_buffer_create(grpc_slice*, c_ulong, grpc_compression_algorithm) @nogc nothrow;
    grpc_byte_buffer* grpc_byte_buffer_copy(grpc_byte_buffer*) @nogc nothrow;
    c_ulong grpc_byte_buffer_length(grpc_byte_buffer*) @nogc nothrow;
    void grpc_byte_buffer_destroy(grpc_byte_buffer*) @nogc nothrow;
    struct grpc_byte_buffer_reader
    {
        grpc_byte_buffer* buffer_in;
        grpc_byte_buffer* buffer_out;
        union grpc_byte_buffer_reader_current
        {
            uint index;
        }
        grpc_byte_buffer_reader_current current;
    }
    int grpc_byte_buffer_reader_init(grpc_byte_buffer_reader*, grpc_byte_buffer*) @nogc nothrow;
    void grpc_byte_buffer_reader_destroy(grpc_byte_buffer_reader*) @nogc nothrow;
    int grpc_byte_buffer_reader_next(grpc_byte_buffer_reader*, grpc_slice*) @nogc nothrow;
    int grpc_byte_buffer_reader_peek(grpc_byte_buffer_reader*, grpc_slice**) @nogc nothrow;
    grpc_slice grpc_byte_buffer_reader_readall(grpc_byte_buffer_reader*) @nogc nothrow;
    grpc_byte_buffer* grpc_raw_byte_buffer_from_reader(grpc_byte_buffer_reader*) @nogc nothrow;
    int gpr_time_to_millis(gpr_timespec) @nogc nothrow;
    gpr_timespec gpr_time_from_hours(c_long, gpr_clock_type) @nogc nothrow;
    alias grpc_compression_algorithm = _Anonymous_29;
    enum _Anonymous_29
    {
        GRPC_COMPRESS_NONE = 0,
        GRPC_COMPRESS_DEFLATE = 1,
        GRPC_COMPRESS_GZIP = 2,
        GRPC_COMPRESS_STREAM_GZIP = 3,
        GRPC_COMPRESS_ALGORITHMS_COUNT = 4,
    }
    enum GRPC_COMPRESS_NONE = _Anonymous_29.GRPC_COMPRESS_NONE;
    enum GRPC_COMPRESS_DEFLATE = _Anonymous_29.GRPC_COMPRESS_DEFLATE;
    enum GRPC_COMPRESS_GZIP = _Anonymous_29.GRPC_COMPRESS_GZIP;
    enum GRPC_COMPRESS_STREAM_GZIP = _Anonymous_29.GRPC_COMPRESS_STREAM_GZIP;
    enum GRPC_COMPRESS_ALGORITHMS_COUNT = _Anonymous_29.GRPC_COMPRESS_ALGORITHMS_COUNT;
    alias grpc_compression_level = _Anonymous_30;
    enum _Anonymous_30
    {
        GRPC_COMPRESS_LEVEL_NONE = 0,
        GRPC_COMPRESS_LEVEL_LOW = 1,
        GRPC_COMPRESS_LEVEL_MED = 2,
        GRPC_COMPRESS_LEVEL_HIGH = 3,
        GRPC_COMPRESS_LEVEL_COUNT = 4,
    }
    enum GRPC_COMPRESS_LEVEL_NONE = _Anonymous_30.GRPC_COMPRESS_LEVEL_NONE;
    enum GRPC_COMPRESS_LEVEL_LOW = _Anonymous_30.GRPC_COMPRESS_LEVEL_LOW;
    enum GRPC_COMPRESS_LEVEL_MED = _Anonymous_30.GRPC_COMPRESS_LEVEL_MED;
    enum GRPC_COMPRESS_LEVEL_HIGH = _Anonymous_30.GRPC_COMPRESS_LEVEL_HIGH;
    enum GRPC_COMPRESS_LEVEL_COUNT = _Anonymous_30.GRPC_COMPRESS_LEVEL_COUNT;
    struct grpc_compression_options
    {
        uint enabled_algorithms_bitset;
        struct grpc_compression_options_default_level
        {
            int is_set;
            grpc_compression_level level;
        }
        grpc_compression_options_default_level default_level;
        struct grpc_compression_options_default_algorithm
        {
            int is_set;
            grpc_compression_algorithm algorithm;
        }
        grpc_compression_options_default_algorithm default_algorithm;
    }
    gpr_timespec gpr_time_from_minutes(c_long, gpr_clock_type) @nogc nothrow;
    alias grpc_connectivity_state = _Anonymous_31;
    enum _Anonymous_31
    {
        GRPC_CHANNEL_IDLE = 0,
        GRPC_CHANNEL_CONNECTING = 1,
        GRPC_CHANNEL_READY = 2,
        GRPC_CHANNEL_TRANSIENT_FAILURE = 3,
        GRPC_CHANNEL_SHUTDOWN = 4,
    }
    enum GRPC_CHANNEL_IDLE = _Anonymous_31.GRPC_CHANNEL_IDLE;
    enum GRPC_CHANNEL_CONNECTING = _Anonymous_31.GRPC_CHANNEL_CONNECTING;
    enum GRPC_CHANNEL_READY = _Anonymous_31.GRPC_CHANNEL_READY;
    enum GRPC_CHANNEL_TRANSIENT_FAILURE = _Anonymous_31.GRPC_CHANNEL_TRANSIENT_FAILURE;
    enum GRPC_CHANNEL_SHUTDOWN = _Anonymous_31.GRPC_CHANNEL_SHUTDOWN;
    gpr_timespec gpr_time_from_seconds(c_long, gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_time_from_millis(c_long, gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_time_from_nanos(c_long, gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_time_from_micros(c_long, gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_time_sub(gpr_timespec, gpr_timespec) @nogc nothrow;
    gpr_timespec gpr_time_add(gpr_timespec, gpr_timespec) @nogc nothrow;
    gpr_timespec gpr_time_min(gpr_timespec, gpr_timespec) @nogc nothrow;
    gpr_timespec gpr_time_max(gpr_timespec, gpr_timespec) @nogc nothrow;
    int gpr_time_cmp(gpr_timespec, gpr_timespec) @nogc nothrow;
    gpr_timespec gpr_convert_clock_type(gpr_timespec, gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_now(gpr_clock_type) @nogc nothrow;
    void gpr_time_init() @nogc nothrow;
    gpr_timespec gpr_inf_past(gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_inf_future(gpr_clock_type) @nogc nothrow;
    gpr_timespec gpr_time_0(gpr_clock_type) @nogc nothrow;
    alias gpr_clock_type = _Anonymous_32;
    enum _Anonymous_32
    {
        GPR_CLOCK_MONOTONIC = 0,
        GPR_CLOCK_REALTIME = 1,
        GPR_CLOCK_PRECISE = 2,
        GPR_TIMESPAN = 3,
    }
    enum GPR_CLOCK_MONOTONIC = _Anonymous_32.GPR_CLOCK_MONOTONIC;
    enum GPR_CLOCK_REALTIME = _Anonymous_32.GPR_CLOCK_REALTIME;
    enum GPR_CLOCK_PRECISE = _Anonymous_32.GPR_CLOCK_PRECISE;
    enum GPR_TIMESPAN = _Anonymous_32.GPR_TIMESPAN;
    struct gpr_timespec
    {
        c_long tv_sec;
        int tv_nsec;
        gpr_clock_type clock_type;
    }
    c_long gpr_stats_read(const(gpr_stats_counter)*) @nogc nothrow;
    alias grpc_byte_buffer_type = _Anonymous_33;
    enum _Anonymous_33
    {
        GRPC_BB_RAW = 0,
    }
    enum GRPC_BB_RAW = _Anonymous_33.GRPC_BB_RAW;
    struct grpc_byte_buffer
    {
        void* reserved;
        grpc_byte_buffer_type type;
        union grpc_byte_buffer_data
        {
            static struct _Anonymous_34
            {
                void*[8] reserved;
            }
            _Anonymous_34 reserved;
            struct grpc_compressed_buffer
            {
                grpc_compression_algorithm compression;
                grpc_slice_buffer slice_buffer;
            }
            grpc_compressed_buffer raw;
        }
        grpc_byte_buffer_data data;
    }
    struct grpc_completion_queue;
    struct grpc_alarm;
    struct grpc_channel;
    struct grpc_server;
    struct grpc_call;
    struct grpc_socket_mutator;
    struct grpc_socket_factory;
    alias grpc_arg_type = _Anonymous_35;
    enum _Anonymous_35
    {
        GRPC_ARG_STRING = 0,
        GRPC_ARG_INTEGER = 1,
        GRPC_ARG_POINTER = 2,
    }
    enum GRPC_ARG_STRING = _Anonymous_35.GRPC_ARG_STRING;
    enum GRPC_ARG_INTEGER = _Anonymous_35.GRPC_ARG_INTEGER;
    enum GRPC_ARG_POINTER = _Anonymous_35.GRPC_ARG_POINTER;
    struct grpc_arg_pointer_vtable
    {
        void* function(void*) copy;
        void function(void*) destroy;
        int function(void*, void*) cmp;
    }
    struct grpc_arg
    {
        grpc_arg_type type;
        char* key;
        union grpc_arg_value
        {
            char* string;
            int integer;
            struct grpc_arg_pointer
            {
                void* p;
                const(grpc_arg_pointer_vtable)* vtable;
            }
            grpc_arg_pointer pointer;
        }
        grpc_arg_value value;
    }
    struct grpc_channel_args
    {
        c_ulong num_args;
        grpc_arg* args;
    }
    void gpr_stats_inc(gpr_stats_counter*, c_long) @nogc nothrow;
    void gpr_stats_init(gpr_stats_counter*, c_long) @nogc nothrow;
    int gpr_ref_is_unique(gpr_refcount*) @nogc nothrow;
    int gpr_unref(gpr_refcount*) @nogc nothrow;
    void gpr_refn(gpr_refcount*, int) @nogc nothrow;
    void gpr_ref_non_zero(gpr_refcount*) @nogc nothrow;
    void gpr_ref(gpr_refcount*) @nogc nothrow;
    void gpr_ref_init(gpr_refcount*, int) @nogc nothrow;
    void* gpr_event_wait(gpr_event*, gpr_timespec) @nogc nothrow;
    void* gpr_event_get(gpr_event*) @nogc nothrow;
    void gpr_event_set(gpr_event*, void*) @nogc nothrow;
    void gpr_event_init(gpr_event*) @nogc nothrow;
    void gpr_once_init(int*, void function()) @nogc nothrow;
    void gpr_cv_broadcast(pthread_cond_t*) @nogc nothrow;
    void gpr_cv_signal(pthread_cond_t*) @nogc nothrow;
    int gpr_cv_wait(pthread_cond_t*, pthread_mutex_t*, gpr_timespec) @nogc nothrow;
    void gpr_cv_destroy(pthread_cond_t*) @nogc nothrow;
    void gpr_cv_init(pthread_cond_t*) @nogc nothrow;
    int gpr_mu_trylock(pthread_mutex_t*) @nogc nothrow;
    void gpr_mu_unlock(pthread_mutex_t*) @nogc nothrow;
    void gpr_mu_lock(pthread_mutex_t*) @nogc nothrow;
    void gpr_mu_destroy(pthread_mutex_t*) @nogc nothrow;
    void gpr_mu_init(pthread_mutex_t*) @nogc nothrow;
    void grpc_slice_buffer_undo_take_first(grpc_slice_buffer*, grpc_slice) @nogc nothrow;
    grpc_slice grpc_slice_buffer_take_first(grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_move_first_into_buffer(grpc_slice_buffer*, c_ulong, void*) @nogc nothrow;
    void grpc_slice_buffer_move_first_no_ref(grpc_slice_buffer*, c_ulong, grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_move_first(grpc_slice_buffer*, c_ulong, grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_trim_end(grpc_slice_buffer*, c_ulong, grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_move_into(grpc_slice_buffer*, grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_swap(grpc_slice_buffer*, grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_reset_and_unref(grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_pop(grpc_slice_buffer*) @nogc nothrow;
    enum grpc_call_error
    {
        GRPC_CALL_OK = 0,
        GRPC_CALL_ERROR = 1,
        GRPC_CALL_ERROR_NOT_ON_SERVER = 2,
        GRPC_CALL_ERROR_NOT_ON_CLIENT = 3,
        GRPC_CALL_ERROR_ALREADY_ACCEPTED = 4,
        GRPC_CALL_ERROR_ALREADY_INVOKED = 5,
        GRPC_CALL_ERROR_NOT_INVOKED = 6,
        GRPC_CALL_ERROR_ALREADY_FINISHED = 7,
        GRPC_CALL_ERROR_TOO_MANY_OPERATIONS = 8,
        GRPC_CALL_ERROR_INVALID_FLAGS = 9,
        GRPC_CALL_ERROR_INVALID_METADATA = 10,
        GRPC_CALL_ERROR_INVALID_MESSAGE = 11,
        GRPC_CALL_ERROR_NOT_SERVER_COMPLETION_QUEUE = 12,
        GRPC_CALL_ERROR_BATCH_TOO_BIG = 13,
        GRPC_CALL_ERROR_PAYLOAD_TYPE_MISMATCH = 14,
        GRPC_CALL_ERROR_COMPLETION_QUEUE_SHUTDOWN = 15,
    }
    enum GRPC_CALL_OK = grpc_call_error.GRPC_CALL_OK;
    enum GRPC_CALL_ERROR = grpc_call_error.GRPC_CALL_ERROR;
    enum GRPC_CALL_ERROR_NOT_ON_SERVER = grpc_call_error.GRPC_CALL_ERROR_NOT_ON_SERVER;
    enum GRPC_CALL_ERROR_NOT_ON_CLIENT = grpc_call_error.GRPC_CALL_ERROR_NOT_ON_CLIENT;
    enum GRPC_CALL_ERROR_ALREADY_ACCEPTED = grpc_call_error.GRPC_CALL_ERROR_ALREADY_ACCEPTED;
    enum GRPC_CALL_ERROR_ALREADY_INVOKED = grpc_call_error.GRPC_CALL_ERROR_ALREADY_INVOKED;
    enum GRPC_CALL_ERROR_NOT_INVOKED = grpc_call_error.GRPC_CALL_ERROR_NOT_INVOKED;
    enum GRPC_CALL_ERROR_ALREADY_FINISHED = grpc_call_error.GRPC_CALL_ERROR_ALREADY_FINISHED;
    enum GRPC_CALL_ERROR_TOO_MANY_OPERATIONS = grpc_call_error.GRPC_CALL_ERROR_TOO_MANY_OPERATIONS;
    enum GRPC_CALL_ERROR_INVALID_FLAGS = grpc_call_error.GRPC_CALL_ERROR_INVALID_FLAGS;
    enum GRPC_CALL_ERROR_INVALID_METADATA = grpc_call_error.GRPC_CALL_ERROR_INVALID_METADATA;
    enum GRPC_CALL_ERROR_INVALID_MESSAGE = grpc_call_error.GRPC_CALL_ERROR_INVALID_MESSAGE;
    enum GRPC_CALL_ERROR_NOT_SERVER_COMPLETION_QUEUE = grpc_call_error.GRPC_CALL_ERROR_NOT_SERVER_COMPLETION_QUEUE;
    enum GRPC_CALL_ERROR_BATCH_TOO_BIG = grpc_call_error.GRPC_CALL_ERROR_BATCH_TOO_BIG;
    enum GRPC_CALL_ERROR_PAYLOAD_TYPE_MISMATCH = grpc_call_error.GRPC_CALL_ERROR_PAYLOAD_TYPE_MISMATCH;
    enum GRPC_CALL_ERROR_COMPLETION_QUEUE_SHUTDOWN = grpc_call_error.GRPC_CALL_ERROR_COMPLETION_QUEUE_SHUTDOWN;
    ubyte* grpc_slice_buffer_tiny_add(grpc_slice_buffer*, c_ulong) @nogc nothrow;
    void grpc_slice_buffer_addn(grpc_slice_buffer*, grpc_slice*, c_ulong) @nogc nothrow;
    c_ulong grpc_slice_buffer_add_indexed(grpc_slice_buffer*, grpc_slice) @nogc nothrow;
    void grpc_slice_buffer_add(grpc_slice_buffer*, grpc_slice) @nogc nothrow;
    void grpc_slice_buffer_destroy(grpc_slice_buffer*) @nogc nothrow;
    void grpc_slice_buffer_init(grpc_slice_buffer*) @nogc nothrow;
    struct grpc_metadata
    {
        grpc_slice key;
        grpc_slice value;
        uint flags;
        static struct _Anonymous_36
        {
            void*[4] obfuscated;
        }
        _Anonymous_36 internal_data;
    }
    enum grpc_completion_type
    {
        GRPC_QUEUE_SHUTDOWN = 0,
        GRPC_QUEUE_TIMEOUT = 1,
        GRPC_OP_COMPLETE = 2,
    }
    enum GRPC_QUEUE_SHUTDOWN = grpc_completion_type.GRPC_QUEUE_SHUTDOWN;
    enum GRPC_QUEUE_TIMEOUT = grpc_completion_type.GRPC_QUEUE_TIMEOUT;
    enum GRPC_OP_COMPLETE = grpc_completion_type.GRPC_OP_COMPLETE;
    struct grpc_event
    {
        grpc_completion_type type;
        int success;
        void* tag;
    }
    struct grpc_metadata_array
    {
        c_ulong count;
        c_ulong capacity;
        grpc_metadata* metadata;
    }
    struct grpc_call_details
    {
        grpc_slice method;
        grpc_slice host;
        gpr_timespec deadline;
        uint flags;
        void* reserved;
    }
    alias grpc_op_type = _Anonymous_37;
    enum _Anonymous_37
    {
        GRPC_OP_SEND_INITIAL_METADATA = 0,
        GRPC_OP_SEND_MESSAGE = 1,
        GRPC_OP_SEND_CLOSE_FROM_CLIENT = 2,
        GRPC_OP_SEND_STATUS_FROM_SERVER = 3,
        GRPC_OP_RECV_INITIAL_METADATA = 4,
        GRPC_OP_RECV_MESSAGE = 5,
        GRPC_OP_RECV_STATUS_ON_CLIENT = 6,
        GRPC_OP_RECV_CLOSE_ON_SERVER = 7,
    }
    enum GRPC_OP_SEND_INITIAL_METADATA = _Anonymous_37.GRPC_OP_SEND_INITIAL_METADATA;
    enum GRPC_OP_SEND_MESSAGE = _Anonymous_37.GRPC_OP_SEND_MESSAGE;
    enum GRPC_OP_SEND_CLOSE_FROM_CLIENT = _Anonymous_37.GRPC_OP_SEND_CLOSE_FROM_CLIENT;
    enum GRPC_OP_SEND_STATUS_FROM_SERVER = _Anonymous_37.GRPC_OP_SEND_STATUS_FROM_SERVER;
    enum GRPC_OP_RECV_INITIAL_METADATA = _Anonymous_37.GRPC_OP_RECV_INITIAL_METADATA;
    enum GRPC_OP_RECV_MESSAGE = _Anonymous_37.GRPC_OP_RECV_MESSAGE;
    enum GRPC_OP_RECV_STATUS_ON_CLIENT = _Anonymous_37.GRPC_OP_RECV_STATUS_ON_CLIENT;
    enum GRPC_OP_RECV_CLOSE_ON_SERVER = _Anonymous_37.GRPC_OP_RECV_CLOSE_ON_SERVER;
    struct grpc_op
    {
        grpc_op_type op;
        uint flags;
        void* reserved;
        union grpc_op_data
        {
            static struct _Anonymous_38
            {
                void*[8] reserved;
            }
            _Anonymous_38 reserved;
            struct grpc_op_send_initial_metadata
            {
                c_ulong count;
                grpc_metadata* metadata;
                struct grpc_op_send_initial_metadata_maybe_compression_level
                {
                    ubyte is_set;
                    grpc_compression_level level;
                }
                grpc_op_send_initial_metadata_maybe_compression_level maybe_compression_level;
            }
            grpc_op_send_initial_metadata send_initial_metadata;
            struct grpc_op_send_message
            {
                grpc_byte_buffer* send_message;
            }
            grpc_op_send_message send_message;
            struct grpc_op_send_status_from_server
            {
                c_ulong trailing_metadata_count;
                grpc_metadata* trailing_metadata;
                grpc_status_code status;
                grpc_slice* status_details;
            }
            grpc_op_send_status_from_server send_status_from_server;
            struct grpc_op_recv_initial_metadata
            {
                grpc_metadata_array* recv_initial_metadata;
            }
            grpc_op_recv_initial_metadata recv_initial_metadata;
            struct grpc_op_recv_message
            {
                grpc_byte_buffer** recv_message;
            }
            grpc_op_recv_message recv_message;
            struct grpc_op_recv_status_on_client
            {
                grpc_metadata_array* trailing_metadata;
                grpc_status_code* status;
                grpc_slice* status_details;
                const(char)** error_string;
            }
            grpc_op_recv_status_on_client recv_status_on_client;
            struct grpc_op_recv_close_on_server
            {
                int* cancelled;
            }
            grpc_op_recv_close_on_server recv_close_on_server;
        }
        grpc_op_data data;
    }
    struct grpc_channel_info
    {
        char** lb_policy_name;
        char** service_config_json;
    }
    struct grpc_resource_quota;
    alias grpc_cq_polling_type = _Anonymous_39;
    enum _Anonymous_39
    {
        GRPC_CQ_DEFAULT_POLLING = 0,
        GRPC_CQ_NON_LISTENING = 1,
        GRPC_CQ_NON_POLLING = 2,
    }
    enum GRPC_CQ_DEFAULT_POLLING = _Anonymous_39.GRPC_CQ_DEFAULT_POLLING;
    enum GRPC_CQ_NON_LISTENING = _Anonymous_39.GRPC_CQ_NON_LISTENING;
    enum GRPC_CQ_NON_POLLING = _Anonymous_39.GRPC_CQ_NON_POLLING;
    alias grpc_cq_completion_type = _Anonymous_40;
    enum _Anonymous_40
    {
        GRPC_CQ_NEXT = 0,
        GRPC_CQ_PLUCK = 1,
        GRPC_CQ_CALLBACK = 2,
    }
    enum GRPC_CQ_NEXT = _Anonymous_40.GRPC_CQ_NEXT;
    enum GRPC_CQ_PLUCK = _Anonymous_40.GRPC_CQ_PLUCK;
    enum GRPC_CQ_CALLBACK = _Anonymous_40.GRPC_CQ_CALLBACK;
    struct grpc_experimental_completion_queue_functor
    {
        void function(grpc_experimental_completion_queue_functor*, int) functor_run;
        int internal_success;
        grpc_experimental_completion_queue_functor* internal_next;
    }
    struct grpc_completion_queue_attributes
    {
        int version_;
        grpc_cq_completion_type cq_completion_type;
        grpc_cq_polling_type cq_polling_type;
        grpc_experimental_completion_queue_functor* cq_shutdown_cb;
    }
    struct grpc_completion_queue_factory;
    char* grpc_slice_to_c_string(grpc_slice) @nogc nothrow;
    grpc_slice grpc_slice_dup(grpc_slice) @nogc nothrow;
    int grpc_slice_is_equivalent(grpc_slice, grpc_slice) @nogc nothrow;
    uint grpc_slice_hash(grpc_slice) @nogc nothrow;
    int grpc_slice_slice(grpc_slice, grpc_slice) @nogc nothrow;
    int grpc_slice_chr(grpc_slice, char) @nogc nothrow;
    int grpc_slice_rchr(grpc_slice, char) @nogc nothrow;
    int grpc_slice_buf_start_eq(grpc_slice, const(void)*, c_ulong) @nogc nothrow;
    int grpc_slice_str_cmp(grpc_slice, const(char)*) @nogc nothrow;
    int grpc_slice_cmp(grpc_slice, grpc_slice) @nogc nothrow;
    int grpc_slice_eq(grpc_slice, grpc_slice) @nogc nothrow;
    int grpc_slice_default_eq_impl(grpc_slice, grpc_slice) @nogc nothrow;
    uint grpc_slice_default_hash_impl(grpc_slice) @nogc nothrow;
    grpc_slice grpc_empty_slice() @nogc nothrow;
    grpc_slice grpc_slice_split_head(grpc_slice*, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_split_tail_maybe_ref(grpc_slice*, c_ulong, grpc_slice_ref_whom) @nogc nothrow;
    enum _Anonymous_41
    {
        GRPC_SLICE_REF_TAIL = 1,
        GRPC_SLICE_REF_HEAD = 2,
        GRPC_SLICE_REF_BOTH = 3,
    }
    enum GRPC_SLICE_REF_TAIL = _Anonymous_41.GRPC_SLICE_REF_TAIL;
    enum GRPC_SLICE_REF_HEAD = _Anonymous_41.GRPC_SLICE_REF_HEAD;
    enum GRPC_SLICE_REF_BOTH = _Anonymous_41.GRPC_SLICE_REF_BOTH;
    alias grpc_slice_ref_whom = _Anonymous_41;
    grpc_slice grpc_slice_split_tail(grpc_slice*, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_sub_no_ref(grpc_slice, c_ulong, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_sub(grpc_slice, c_ulong, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_from_static_buffer(const(void)*, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_from_static_string(const(char)*) @nogc nothrow;
    grpc_slice grpc_slice_from_copied_buffer(const(char)*, c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_from_copied_string(const(char)*) @nogc nothrow;
    grpc_slice grpc_slice_intern(grpc_slice) @nogc nothrow;
    grpc_slice grpc_slice_malloc_large(c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_malloc(c_ulong) @nogc nothrow;
    grpc_slice grpc_slice_new_with_len(void*, c_ulong, void function(void*, c_ulong)) @nogc nothrow;
    struct grpc_slice
    {
        grpc_slice_refcount* refcount;
        union grpc_slice_data
        {
            struct grpc_slice_refcounted
            {
                c_ulong length;
                ubyte* bytes;
            }
            grpc_slice_refcounted refcounted;
            struct grpc_slice_inlined
            {
                ubyte length;
                ubyte[23] bytes;
            }
            grpc_slice_inlined inlined;
        }
        grpc_slice_data data;
    }
    grpc_slice grpc_slice_new_with_user_data(void*, c_ulong, void function(void*), void*) @nogc nothrow;
    struct grpc_slice_refcount;
    grpc_slice grpc_slice_new(void*, c_ulong, void function(void*)) @nogc nothrow;
    struct grpc_slice_buffer
    {
        grpc_slice* base_slices;
        grpc_slice* slices;
        c_ulong count;
        c_ulong capacity;
        c_ulong length;
        grpc_slice[8] inlined;
    }
    grpc_slice grpc_slice_copy(grpc_slice) @nogc nothrow;
    void grpc_slice_unref(grpc_slice) @nogc nothrow;
    grpc_slice grpc_slice_ref(grpc_slice) @nogc nothrow;
    alias gpr_once = int;
    alias grpc_status_code = _Anonymous_42;
    enum _Anonymous_42
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
    enum GRPC_STATUS_OK = _Anonymous_42.GRPC_STATUS_OK;
    enum GRPC_STATUS_CANCELLED = _Anonymous_42.GRPC_STATUS_CANCELLED;
    enum GRPC_STATUS_UNKNOWN = _Anonymous_42.GRPC_STATUS_UNKNOWN;
    enum GRPC_STATUS_INVALID_ARGUMENT = _Anonymous_42.GRPC_STATUS_INVALID_ARGUMENT;
    enum GRPC_STATUS_DEADLINE_EXCEEDED = _Anonymous_42.GRPC_STATUS_DEADLINE_EXCEEDED;
    enum GRPC_STATUS_NOT_FOUND = _Anonymous_42.GRPC_STATUS_NOT_FOUND;
    enum GRPC_STATUS_ALREADY_EXISTS = _Anonymous_42.GRPC_STATUS_ALREADY_EXISTS;
    enum GRPC_STATUS_PERMISSION_DENIED = _Anonymous_42.GRPC_STATUS_PERMISSION_DENIED;
    enum GRPC_STATUS_UNAUTHENTICATED = _Anonymous_42.GRPC_STATUS_UNAUTHENTICATED;
    enum GRPC_STATUS_RESOURCE_EXHAUSTED = _Anonymous_42.GRPC_STATUS_RESOURCE_EXHAUSTED;
    enum GRPC_STATUS_FAILED_PRECONDITION = _Anonymous_42.GRPC_STATUS_FAILED_PRECONDITION;
    enum GRPC_STATUS_ABORTED = _Anonymous_42.GRPC_STATUS_ABORTED;
    enum GRPC_STATUS_OUT_OF_RANGE = _Anonymous_42.GRPC_STATUS_OUT_OF_RANGE;
    enum GRPC_STATUS_UNIMPLEMENTED = _Anonymous_42.GRPC_STATUS_UNIMPLEMENTED;
    enum GRPC_STATUS_INTERNAL = _Anonymous_42.GRPC_STATUS_INTERNAL;
    enum GRPC_STATUS_UNAVAILABLE = _Anonymous_42.GRPC_STATUS_UNAVAILABLE;
    enum GRPC_STATUS_DATA_LOSS = _Anonymous_42.GRPC_STATUS_DATA_LOSS;
    enum GRPC_STATUS__DO_NOT_USE = _Anonymous_42.GRPC_STATUS__DO_NOT_USE;
    alias gpr_cv = pthread_cond_t;
    alias gpr_mu = pthread_mutex_t;
    struct gpr_event
    {
        c_long state;
    }
    struct gpr_refcount
    {
        c_long count;
    }
    struct gpr_stats_counter
    {
        c_long value;
    }
    static if(!is(typeof(GRPC_SLICE_BUFFER_INLINE_ELEMENTS))) {
        enum GRPC_SLICE_BUFFER_INLINE_ELEMENTS = 8;
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
    static if(!is(typeof(GRPC_CQ_VERSION_MINIMUM_FOR_CALLBACKABLE))) {
        enum GRPC_CQ_VERSION_MINIMUM_FOR_CALLBACKABLE = 2;
    }




    static if(!is(typeof(GRPC_CQ_CURRENT_VERSION))) {
        enum GRPC_CQ_CURRENT_VERSION = 2;
    }
    static if(!is(typeof(GRPC_ARG_CHANNEL_ID))) {
        enum GRPC_ARG_CHANNEL_ID = "grpc.channel_id";
    }




    static if(!is(typeof(GRPC_ARG_CHANNEL_POOL_DOMAIN))) {
        enum GRPC_ARG_CHANNEL_POOL_DOMAIN = "grpc.channel_pooling_domain";
    }




    static if(!is(typeof(GRPC_ARG_USE_LOCAL_SUBCHANNEL_POOL))) {
        enum GRPC_ARG_USE_LOCAL_SUBCHANNEL_POOL = "grpc.use_local_subchannel_pool";
    }




    static if(!is(typeof(GRPC_ARG_DNS_ARES_QUERY_TIMEOUT_MS))) {
        enum GRPC_ARG_DNS_ARES_QUERY_TIMEOUT_MS = "grpc.dns_ares_query_timeout";
    }




    static if(!is(typeof(GRPC_ARG_DNS_ENABLE_SRV_QUERIES))) {
        enum GRPC_ARG_DNS_ENABLE_SRV_QUERIES = "grpc.dns_enable_srv_queries";
    }




    static if(!is(typeof(GRPC_ARG_INHIBIT_HEALTH_CHECKING))) {
        enum GRPC_ARG_INHIBIT_HEALTH_CHECKING = "grpc.inhibit_health_checking";
    }




    static if(!is(typeof(GRPC_ARG_SURFACE_USER_AGENT))) {
        enum GRPC_ARG_SURFACE_USER_AGENT = "grpc.surface_user_agent";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_HTTP_PROXY))) {
        enum GRPC_ARG_ENABLE_HTTP_PROXY = "grpc.enable_http_proxy";
    }




    static if(!is(typeof(GRPC_ARG_DISABLE_CLIENT_AUTHORITY_FILTER))) {
        enum GRPC_ARG_DISABLE_CLIENT_AUTHORITY_FILTER = "grpc.disable_client_authority_filter";
    }




    static if(!is(typeof(GRPC_ARG_MOBILE_LOG_CONTEXT))) {
        enum GRPC_ARG_MOBILE_LOG_CONTEXT = "grpc.mobile_log_context";
    }




    static if(!is(typeof(GRPC_ARG_PER_RPC_RETRY_BUFFER_SIZE))) {
        enum GRPC_ARG_PER_RPC_RETRY_BUFFER_SIZE = "grpc.per_rpc_retry_buffer_size";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_RETRIES))) {
        enum GRPC_ARG_ENABLE_RETRIES = "grpc.enable_retries";
    }




    static if(!is(typeof(GRPC_ARG_OPTIMIZATION_TARGET))) {
        enum GRPC_ARG_OPTIMIZATION_TARGET = "grpc.optimization_target";
    }




    static if(!is(typeof(GRPC_ARG_WORKAROUND_CRONET_COMPRESSION))) {
        enum GRPC_ARG_WORKAROUND_CRONET_COMPRESSION = "grpc.workaround.cronet_compression";
    }




    static if(!is(typeof(GRPC_ARG_LOCALITY_RETENTION_INTERVAL_MS))) {
        enum GRPC_ARG_LOCALITY_RETENTION_INTERVAL_MS = "grpc.xds_locality_retention_interval_ms";
    }




    static if(!is(typeof(GRPC_ARG_XDS_FALLBACK_TIMEOUT_MS))) {
        enum GRPC_ARG_XDS_FALLBACK_TIMEOUT_MS = "grpc.xds_fallback_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_GRPCLB_FALLBACK_TIMEOUT_MS))) {
        enum GRPC_ARG_GRPCLB_FALLBACK_TIMEOUT_MS = "grpc.grpclb_fallback_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_GRPCLB_CALL_TIMEOUT_MS))) {
        enum GRPC_ARG_GRPCLB_CALL_TIMEOUT_MS = "grpc.grpclb_call_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_TCP_MAX_READ_CHUNK_SIZE))) {
        enum GRPC_ARG_TCP_MAX_READ_CHUNK_SIZE = "grpc.experimental.tcp_max_read_chunk_size";
    }




    static if(!is(typeof(GRPC_ARG_TCP_MIN_READ_CHUNK_SIZE))) {
        enum GRPC_ARG_TCP_MIN_READ_CHUNK_SIZE = "grpc.experimental.tcp_min_read_chunk_size";
    }






    static if(!is(typeof(GRPC_TCP_DEFAULT_READ_SLICE_SIZE))) {
        enum GRPC_TCP_DEFAULT_READ_SLICE_SIZE = 8192;
    }




    static if(!is(typeof(GRPC_ARG_TCP_READ_CHUNK_SIZE))) {
        enum GRPC_ARG_TCP_READ_CHUNK_SIZE = "grpc.experimental.tcp_read_chunk_size";
    }






    static if(!is(typeof(GRPC_ARG_USE_CRONET_PACKET_COALESCING))) {
        enum GRPC_ARG_USE_CRONET_PACKET_COALESCING = "grpc.use_cronet_packet_coalescing";
    }






    static if(!is(typeof(GRPC_ARG_ENABLE_CHANNELZ))) {
        enum GRPC_ARG_ENABLE_CHANNELZ = "grpc.enable_channelz";
    }




    static if(!is(typeof(GRPC_ARG_MAX_CHANNEL_TRACE_EVENT_MEMORY_PER_NODE))) {
        enum GRPC_ARG_MAX_CHANNEL_TRACE_EVENT_MEMORY_PER_NODE = "grpc.max_channel_trace_event_memory_per_node";
    }




    static if(!is(typeof(GRPC_ARG_SOCKET_FACTORY))) {
        enum GRPC_ARG_SOCKET_FACTORY = "grpc.socket_factory";
    }




    static if(!is(typeof(GRPC_ARG_SOCKET_MUTATOR))) {
        enum GRPC_ARG_SOCKET_MUTATOR = "grpc.socket_mutator";
    }




    static if(!is(typeof(GRPC_ARG_LB_POLICY_NAME))) {
        enum GRPC_ARG_LB_POLICY_NAME = "grpc.lb_policy_name";
    }




    static if(!is(typeof(GRPC_ARG_SERVICE_CONFIG_DISABLE_RESOLUTION))) {
        enum GRPC_ARG_SERVICE_CONFIG_DISABLE_RESOLUTION = "grpc.service_config_disable_resolution";
    }




    static if(!is(typeof(GRPC_ARG_SERVICE_CONFIG))) {
        enum GRPC_ARG_SERVICE_CONFIG = "grpc.service_config";
    }




    static if(!is(typeof(GRPC_ARG_EXPAND_WILDCARD_ADDRS))) {
        enum GRPC_ARG_EXPAND_WILDCARD_ADDRS = "grpc.expand_wildcard_addrs";
    }




    static if(!is(typeof(GRPC_ARG_RESOURCE_QUOTA))) {
        enum GRPC_ARG_RESOURCE_QUOTA = "grpc.resource_quota";
    }




    static if(!is(typeof(GRPC_ARG_ALLOW_REUSEPORT))) {
        enum GRPC_ARG_ALLOW_REUSEPORT = "grpc.so_reuseport";
    }




    static if(!is(typeof(GRPC_ARG_MAX_METADATA_SIZE))) {
        enum GRPC_ARG_MAX_METADATA_SIZE = "grpc.max_metadata_size";
    }




    static if(!is(typeof(GRPC_SSL_SESSION_CACHE_ARG))) {
        enum GRPC_SSL_SESSION_CACHE_ARG = "grpc.ssl_session_cache";
    }




    static if(!is(typeof(GRPC_SSL_TARGET_NAME_OVERRIDE_ARG))) {
        enum GRPC_SSL_TARGET_NAME_OVERRIDE_ARG = "grpc.ssl_target_name_override";
    }




    static if(!is(typeof(GRPC_ARG_SERVER_HANDSHAKE_TIMEOUT_MS))) {
        enum GRPC_ARG_SERVER_HANDSHAKE_TIMEOUT_MS = "grpc.server_handshake_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_DNS_MIN_TIME_BETWEEN_RESOLUTIONS_MS))) {
        enum GRPC_ARG_DNS_MIN_TIME_BETWEEN_RESOLUTIONS_MS = "grpc.dns_min_time_between_resolutions_ms";
    }




    static if(!is(typeof(GRPC_ARG_INITIAL_RECONNECT_BACKOFF_MS))) {
        enum GRPC_ARG_INITIAL_RECONNECT_BACKOFF_MS = "grpc.initial_reconnect_backoff_ms";
    }




    static if(!is(typeof(GRPC_ARG_MAX_RECONNECT_BACKOFF_MS))) {
        enum GRPC_ARG_MAX_RECONNECT_BACKOFF_MS = "grpc.max_reconnect_backoff_ms";
    }




    static if(!is(typeof(GRPC_ARG_MIN_RECONNECT_BACKOFF_MS))) {
        enum GRPC_ARG_MIN_RECONNECT_BACKOFF_MS = "grpc.min_reconnect_backoff_ms";
    }




    static if(!is(typeof(GRPC_ARG_SECONDARY_USER_AGENT_STRING))) {
        enum GRPC_ARG_SECONDARY_USER_AGENT_STRING = "grpc.secondary_user_agent";
    }




    static if(!is(typeof(GRPC_ARG_PRIMARY_USER_AGENT_STRING))) {
        enum GRPC_ARG_PRIMARY_USER_AGENT_STRING = "grpc.primary_user_agent";
    }




    static if(!is(typeof(GRPC_ARG_DEFAULT_AUTHORITY))) {
        enum GRPC_ARG_DEFAULT_AUTHORITY = "grpc.default_authority";
    }




    static if(!is(typeof(GRPC_ARG_KEEPALIVE_PERMIT_WITHOUT_CALLS))) {
        enum GRPC_ARG_KEEPALIVE_PERMIT_WITHOUT_CALLS = "grpc.keepalive_permit_without_calls";
    }




    static if(!is(typeof(GRPC_ARG_KEEPALIVE_TIMEOUT_MS))) {
        enum GRPC_ARG_KEEPALIVE_TIMEOUT_MS = "grpc.keepalive_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_KEEPALIVE_TIME_MS))) {
        enum GRPC_ARG_KEEPALIVE_TIME_MS = "grpc.keepalive_time_ms";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_ENABLE_TRUE_BINARY))) {
        enum GRPC_ARG_HTTP2_ENABLE_TRUE_BINARY = "grpc.http2.true_binary";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_WRITE_BUFFER_SIZE))) {
        enum GRPC_ARG_HTTP2_WRITE_BUFFER_SIZE = "grpc.http2.write_buffer_size";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_MAX_PING_STRIKES))) {
        enum GRPC_ARG_HTTP2_MAX_PING_STRIKES = "grpc.http2.max_ping_strikes";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_MAX_PINGS_WITHOUT_DATA))) {
        enum GRPC_ARG_HTTP2_MAX_PINGS_WITHOUT_DATA = "grpc.http2.max_pings_without_data";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_SCHEME))) {
        enum GRPC_ARG_HTTP2_SCHEME = "grpc.http2_scheme";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_MIN_RECV_PING_INTERVAL_WITHOUT_DATA_MS))) {
        enum GRPC_ARG_HTTP2_MIN_RECV_PING_INTERVAL_WITHOUT_DATA_MS = "grpc.http2.min_ping_interval_without_data_ms";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_MIN_SENT_PING_INTERVAL_WITHOUT_DATA_MS))) {
        enum GRPC_ARG_HTTP2_MIN_SENT_PING_INTERVAL_WITHOUT_DATA_MS = "grpc.http2.min_time_between_pings_ms";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_BDP_PROBE))) {
        enum GRPC_ARG_HTTP2_BDP_PROBE = "grpc.http2.bdp_probe";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_MAX_FRAME_SIZE))) {
        enum GRPC_ARG_HTTP2_MAX_FRAME_SIZE = "grpc.http2.max_frame_size";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_HPACK_TABLE_SIZE_ENCODER))) {
        enum GRPC_ARG_HTTP2_HPACK_TABLE_SIZE_ENCODER = "grpc.http2.hpack_table_size.encoder";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_HPACK_TABLE_SIZE_DECODER))) {
        enum GRPC_ARG_HTTP2_HPACK_TABLE_SIZE_DECODER = "grpc.http2.hpack_table_size.decoder";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_STREAM_LOOKAHEAD_BYTES))) {
        enum GRPC_ARG_HTTP2_STREAM_LOOKAHEAD_BYTES = "grpc.http2.lookahead_bytes";
    }




    static if(!is(typeof(GRPC_ARG_HTTP2_INITIAL_SEQUENCE_NUMBER))) {
        enum GRPC_ARG_HTTP2_INITIAL_SEQUENCE_NUMBER = "grpc.http2.initial_sequence_number";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_DEADLINE_CHECKS))) {
        enum GRPC_ARG_ENABLE_DEADLINE_CHECKS = "grpc.enable_deadline_checking";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_PER_MESSAGE_COMPRESSION))) {
        enum GRPC_ARG_ENABLE_PER_MESSAGE_COMPRESSION = "grpc.per_message_compression";
    }




    static if(!is(typeof(GRPC_ARG_CLIENT_IDLE_TIMEOUT_MS))) {
        enum GRPC_ARG_CLIENT_IDLE_TIMEOUT_MS = "grpc.client_idle_timeout_ms";
    }




    static if(!is(typeof(GRPC_ARG_MAX_CONNECTION_AGE_GRACE_MS))) {
        enum GRPC_ARG_MAX_CONNECTION_AGE_GRACE_MS = "grpc.max_connection_age_grace_ms";
    }




    static if(!is(typeof(GRPC_ARG_MAX_CONNECTION_AGE_MS))) {
        enum GRPC_ARG_MAX_CONNECTION_AGE_MS = "grpc.max_connection_age_ms";
    }




    static if(!is(typeof(GRPC_ARG_MAX_CONNECTION_IDLE_MS))) {
        enum GRPC_ARG_MAX_CONNECTION_IDLE_MS = "grpc.max_connection_idle_ms";
    }




    static if(!is(typeof(GRPC_ARG_MAX_SEND_MESSAGE_LENGTH))) {
        enum GRPC_ARG_MAX_SEND_MESSAGE_LENGTH = "grpc.max_send_message_length";
    }






    static if(!is(typeof(GRPC_ARG_MAX_RECEIVE_MESSAGE_LENGTH))) {
        enum GRPC_ARG_MAX_RECEIVE_MESSAGE_LENGTH = "grpc.max_receive_message_length";
    }




    static if(!is(typeof(GRPC_ARG_MAX_CONCURRENT_STREAMS))) {
        enum GRPC_ARG_MAX_CONCURRENT_STREAMS = "grpc.max_concurrent_streams";
    }




    static if(!is(typeof(GRPC_ARG_MINIMAL_STACK))) {
        enum GRPC_ARG_MINIMAL_STACK = "grpc.minimal_stack";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_LOAD_REPORTING))) {
        enum GRPC_ARG_ENABLE_LOAD_REPORTING = "grpc.loadreporting";
    }




    static if(!is(typeof(GRPC_ARG_ENABLE_CENSUS))) {
        enum GRPC_ARG_ENABLE_CENSUS = "grpc.census";
    }
    static if(!is(typeof(GPR_MS_PER_SEC))) {
        enum GPR_MS_PER_SEC = 1000;
    }




    static if(!is(typeof(GPR_US_PER_SEC))) {
        enum GPR_US_PER_SEC = 1000000;
    }




    static if(!is(typeof(GPR_NS_PER_SEC))) {
        enum GPR_NS_PER_SEC = 1000000000;
    }




    static if(!is(typeof(GPR_NS_PER_MS))) {
        enum GPR_NS_PER_MS = 1000000;
    }




    static if(!is(typeof(GPR_NS_PER_US))) {
        enum GPR_NS_PER_US = 1000;
    }




    static if(!is(typeof(GPR_US_PER_MS))) {
        enum GPR_US_PER_MS = 1000;
    }
    static if(!is(typeof(GRPC_ALLOW_GPR_SLICE_FUNCTIONS))) {
        enum GRPC_ALLOW_GPR_SLICE_FUNCTIONS = 1;
    }
    static if(!is(typeof(GRPC_COMPRESSION_CHANNEL_ENABLED_ALGORITHMS_BITSET))) {
        enum GRPC_COMPRESSION_CHANNEL_ENABLED_ALGORITHMS_BITSET = "grpc.compression_enabled_algorithms_bitset";
    }




    static if(!is(typeof(GRPC_COMPRESSION_CHANNEL_DEFAULT_LEVEL))) {
        enum GRPC_COMPRESSION_CHANNEL_DEFAULT_LEVEL = "grpc.default_compression_level";
    }




    static if(!is(typeof(GRPC_COMPRESSION_CHANNEL_DEFAULT_ALGORITHM))) {
        enum GRPC_COMPRESSION_CHANNEL_DEFAULT_ALGORITHM = "grpc.default_compression_algorithm";
    }




    static if(!is(typeof(GRPC_COMPRESSION_REQUEST_ALGORITHM_MD_KEY))) {
        enum GRPC_COMPRESSION_REQUEST_ALGORITHM_MD_KEY = "grpc-internal-encoding-request";
    }
    static if(!is(typeof(LINUX_VERSION_CODE))) {
        enum LINUX_VERSION_CODE = 327936;
    }






    static if(!is(typeof(_PTHREAD_H))) {
        enum _PTHREAD_H = 1;
    }
    static if(!is(typeof(GRPC_MAX_COMPLETION_QUEUE_PLUCKERS))) {
        enum GRPC_MAX_COMPLETION_QUEUE_PLUCKERS = 6;
    }
    static if(!is(typeof(__GLIBC_MINOR__))) {
        enum __GLIBC_MINOR__ = 29;
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
    static if(!is(typeof(PTHREAD_ONCE_INIT))) {
        enum PTHREAD_ONCE_INIT = 0;
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




    static if(!is(typeof(__struct_tm_defined))) {
        enum __struct_tm_defined = 1;
    }






    static if(!is(typeof(__timeval_defined))) {
        enum __timeval_defined = 1;
    }




    static if(!is(typeof(_STRUCT_TIMESPEC))) {
        enum _STRUCT_TIMESPEC = 1;
    }






    static if(!is(typeof(_BITS_TYPES_STRUCT_SCHED_PARAM))) {
        enum _BITS_TYPES_STRUCT_SCHED_PARAM = 1;
    }




    static if(!is(typeof(__itimerspec_defined))) {
        enum __itimerspec_defined = 1;
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






    static if(!is(typeof(STA_CLK))) {
        enum STA_CLK = 0x8000;
    }




    static if(!is(typeof(STA_MODE))) {
        enum STA_MODE = 0x4000;
    }




    static if(!is(typeof(STA_NANO))) {
        enum STA_NANO = 0x2000;
    }




    static if(!is(typeof(STA_CLOCKERR))) {
        enum STA_CLOCKERR = 0x1000;
    }




    static if(!is(typeof(STA_PPSERROR))) {
        enum STA_PPSERROR = 0x0800;
    }




    static if(!is(typeof(STA_PPSWANDER))) {
        enum STA_PPSWANDER = 0x0400;
    }




    static if(!is(typeof(STA_PPSJITTER))) {
        enum STA_PPSJITTER = 0x0200;
    }




    static if(!is(typeof(STA_PPSSIGNAL))) {
        enum STA_PPSSIGNAL = 0x0100;
    }




    static if(!is(typeof(STA_FREQHOLD))) {
        enum STA_FREQHOLD = 0x0080;
    }




    static if(!is(typeof(STA_UNSYNC))) {
        enum STA_UNSYNC = 0x0040;
    }




    static if(!is(typeof(STA_DEL))) {
        enum STA_DEL = 0x0020;
    }




    static if(!is(typeof(STA_INS))) {
        enum STA_INS = 0x0010;
    }




    static if(!is(typeof(STA_FLL))) {
        enum STA_FLL = 0x0008;
    }




    static if(!is(typeof(STA_PPSTIME))) {
        enum STA_PPSTIME = 0x0004;
    }




    static if(!is(typeof(STA_PPSFREQ))) {
        enum STA_PPSFREQ = 0x0002;
    }




    static if(!is(typeof(STA_PLL))) {
        enum STA_PLL = 0x0001;
    }
    static if(!is(typeof(ADJ_OFFSET_SS_READ))) {
        enum ADJ_OFFSET_SS_READ = 0xa001;
    }




    static if(!is(typeof(ADJ_OFFSET_SINGLESHOT))) {
        enum ADJ_OFFSET_SINGLESHOT = 0x8001;
    }




    static if(!is(typeof(ADJ_TICK))) {
        enum ADJ_TICK = 0x4000;
    }




    static if(!is(typeof(ADJ_NANO))) {
        enum ADJ_NANO = 0x2000;
    }




    static if(!is(typeof(ADJ_MICRO))) {
        enum ADJ_MICRO = 0x1000;
    }




    static if(!is(typeof(ADJ_SETOFFSET))) {
        enum ADJ_SETOFFSET = 0x0100;
    }




    static if(!is(typeof(ADJ_TAI))) {
        enum ADJ_TAI = 0x0080;
    }




    static if(!is(typeof(ADJ_TIMECONST))) {
        enum ADJ_TIMECONST = 0x0020;
    }




    static if(!is(typeof(ADJ_STATUS))) {
        enum ADJ_STATUS = 0x0010;
    }




    static if(!is(typeof(ADJ_ESTERROR))) {
        enum ADJ_ESTERROR = 0x0008;
    }




    static if(!is(typeof(ADJ_MAXERROR))) {
        enum ADJ_MAXERROR = 0x0004;
    }




    static if(!is(typeof(ADJ_FREQUENCY))) {
        enum ADJ_FREQUENCY = 0x0002;
    }




    static if(!is(typeof(ADJ_OFFSET))) {
        enum ADJ_OFFSET = 0x0001;
    }




    static if(!is(typeof(_BITS_TIMEX_H))) {
        enum _BITS_TIMEX_H = 1;
    }
    static if(!is(typeof(_BITS_TIME64_H))) {
        enum _BITS_TIME64_H = 1;
    }




    static if(!is(typeof(TIMER_ABSTIME))) {
        enum TIMER_ABSTIME = 1;
    }




    static if(!is(typeof(CLOCK_TAI))) {
        enum CLOCK_TAI = 11;
    }




    static if(!is(typeof(CLOCK_BOOTTIME_ALARM))) {
        enum CLOCK_BOOTTIME_ALARM = 9;
    }




    static if(!is(typeof(CLOCK_REALTIME_ALARM))) {
        enum CLOCK_REALTIME_ALARM = 8;
    }




    static if(!is(typeof(CLOCK_BOOTTIME))) {
        enum CLOCK_BOOTTIME = 7;
    }




    static if(!is(typeof(CLOCK_MONOTONIC_COARSE))) {
        enum CLOCK_MONOTONIC_COARSE = 6;
    }




    static if(!is(typeof(CLOCK_REALTIME_COARSE))) {
        enum CLOCK_REALTIME_COARSE = 5;
    }




    static if(!is(typeof(CLOCK_MONOTONIC_RAW))) {
        enum CLOCK_MONOTONIC_RAW = 4;
    }




    static if(!is(typeof(CLOCK_THREAD_CPUTIME_ID))) {
        enum CLOCK_THREAD_CPUTIME_ID = 3;
    }




    static if(!is(typeof(CLOCK_PROCESS_CPUTIME_ID))) {
        enum CLOCK_PROCESS_CPUTIME_ID = 2;
    }




    static if(!is(typeof(CLOCK_MONOTONIC))) {
        enum CLOCK_MONOTONIC = 1;
    }




    static if(!is(typeof(CLOCK_REALTIME))) {
        enum CLOCK_REALTIME = 0;
    }






    static if(!is(typeof(_BITS_TIME_H))) {
        enum _BITS_TIME_H = 1;
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




    static if(!is(typeof(_BITS_SETJMP_H))) {
        enum _BITS_SETJMP_H = 1;
    }




    static if(!is(typeof(CLONE_IO))) {
        enum CLONE_IO = 0x80000000;
    }




    static if(!is(typeof(CLONE_NEWNET))) {
        enum CLONE_NEWNET = 0x40000000;
    }




    static if(!is(typeof(CLONE_NEWPID))) {
        enum CLONE_NEWPID = 0x20000000;
    }




    static if(!is(typeof(CLONE_NEWUSER))) {
        enum CLONE_NEWUSER = 0x10000000;
    }




    static if(!is(typeof(CLONE_NEWIPC))) {
        enum CLONE_NEWIPC = 0x08000000;
    }




    static if(!is(typeof(CLONE_NEWUTS))) {
        enum CLONE_NEWUTS = 0x04000000;
    }




    static if(!is(typeof(CLONE_NEWCGROUP))) {
        enum CLONE_NEWCGROUP = 0x02000000;
    }




    static if(!is(typeof(CLONE_CHILD_SETTID))) {
        enum CLONE_CHILD_SETTID = 0x01000000;
    }




    static if(!is(typeof(CLONE_UNTRACED))) {
        enum CLONE_UNTRACED = 0x00800000;
    }




    static if(!is(typeof(CLONE_DETACHED))) {
        enum CLONE_DETACHED = 0x00400000;
    }




    static if(!is(typeof(CLONE_CHILD_CLEARTID))) {
        enum CLONE_CHILD_CLEARTID = 0x00200000;
    }




    static if(!is(typeof(CLONE_PARENT_SETTID))) {
        enum CLONE_PARENT_SETTID = 0x00100000;
    }




    static if(!is(typeof(CLONE_SETTLS))) {
        enum CLONE_SETTLS = 0x00080000;
    }




    static if(!is(typeof(CLONE_SYSVSEM))) {
        enum CLONE_SYSVSEM = 0x00040000;
    }




    static if(!is(typeof(CLONE_NEWNS))) {
        enum CLONE_NEWNS = 0x00020000;
    }




    static if(!is(typeof(CLONE_THREAD))) {
        enum CLONE_THREAD = 0x00010000;
    }




    static if(!is(typeof(CLONE_PARENT))) {
        enum CLONE_PARENT = 0x00008000;
    }




    static if(!is(typeof(CLONE_VFORK))) {
        enum CLONE_VFORK = 0x00004000;
    }




    static if(!is(typeof(CLONE_PTRACE))) {
        enum CLONE_PTRACE = 0x00002000;
    }




    static if(!is(typeof(CLONE_SIGHAND))) {
        enum CLONE_SIGHAND = 0x00000800;
    }




    static if(!is(typeof(CLONE_FILES))) {
        enum CLONE_FILES = 0x00000400;
    }




    static if(!is(typeof(CLONE_FS))) {
        enum CLONE_FS = 0x00000200;
    }




    static if(!is(typeof(CLONE_VM))) {
        enum CLONE_VM = 0x00000100;
    }




    static if(!is(typeof(CSIGNAL))) {
        enum CSIGNAL = 0x000000ff;
    }




    static if(!is(typeof(SCHED_RESET_ON_FORK))) {
        enum SCHED_RESET_ON_FORK = 0x40000000;
    }




    static if(!is(typeof(SCHED_DEADLINE))) {
        enum SCHED_DEADLINE = 6;
    }




    static if(!is(typeof(SCHED_IDLE))) {
        enum SCHED_IDLE = 5;
    }




    static if(!is(typeof(SCHED_ISO))) {
        enum SCHED_ISO = 4;
    }




    static if(!is(typeof(SCHED_BATCH))) {
        enum SCHED_BATCH = 3;
    }




    static if(!is(typeof(SCHED_RR))) {
        enum SCHED_RR = 2;
    }




    static if(!is(typeof(SCHED_FIFO))) {
        enum SCHED_FIFO = 1;
    }




    static if(!is(typeof(SCHED_OTHER))) {
        enum SCHED_OTHER = 0;
    }




    static if(!is(typeof(_BITS_SCHED_H))) {
        enum _BITS_SCHED_H = 1;
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
    static if(!is(typeof(__CPU_SETSIZE))) {
        enum __CPU_SETSIZE = 1024;
    }




    static if(!is(typeof(_BITS_CPU_SET_H))) {
        enum _BITS_CPU_SET_H = 1;
    }
    static if(!is(typeof(_BITS_BYTESWAP_H))) {
        enum _BITS_BYTESWAP_H = 1;
    }




    static if(!is(typeof(_SCHED_H))) {
        enum _SCHED_H = 1;
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




    static if(!is(typeof(_TIME_H))) {
        enum _TIME_H = 1;
    }




    static if(!is(typeof(TIME_UTC))) {
        enum TIME_UTC = 1;
    }
}
