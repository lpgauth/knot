/*
 * rotor — fast non-cryptographic PRNG NIF.
 *
 * Algorithm: wyrand (1 multiply + 1 xor + 1 add per draw; passes BigCrush).
 * Bounded output: biased multiply-and-shift (single multiply, no rejection
 * branch — matches granderl's pcg32 trick; modulo bias for N <= 256 is
 * < 1e-7, invisible at shackle's scale).
 *
 * State: per OS thread via __thread. Lazy seed from getentropy on first
 * use per thread. No locks on the hot path.
 *
 * License: MIT.
 */

#include <erl_nif.h>
#include <stdint.h>
#include <stddef.h>
#include <time.h>
#include <unistd.h>

#if defined(__linux__)
#  include <sys/random.h>
#endif
#if defined(__APPLE__)
#  include <stdlib.h>            /* arc4random_buf */
#endif

#define WY_INC   0xa0761d6478bd642fULL
#define WY_MIX   0xe7037ed1a0b428dbULL
#define GOLDEN   0x9e3779b97f4a7c15ULL

static __thread uint64_t state = 0;

static uint64_t seed_state(void) {
    uint64_t x = 0;
#if defined(__APPLE__)
    arc4random_buf(&x, sizeof(x));
#elif defined(__linux__)
    if (getrandom(&x, sizeof(x), 0) != (ssize_t)sizeof(x)) {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        x = ((uint64_t)ts.tv_sec << 32) ^ (uint64_t)ts.tv_nsec ^ GOLDEN;
    }
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    x = ((uint64_t)ts.tv_sec << 32) ^ (uint64_t)ts.tv_nsec ^ GOLDEN;
#endif
    return x ? x : GOLDEN;
}

static inline uint64_t next_u64(void) {
    if (__builtin_expect(state == 0, 0)) {
        state = seed_state();
    }
    state += WY_INC;
    __uint128_t t = (__uint128_t)state * (__uint128_t)(state ^ WY_MIX);
    return (uint64_t)(t >> 64) ^ (uint64_t)t;
}

static inline uint32_t uniform_impl(uint32_t n) {
    uint32_t r = (uint32_t)next_u64();
    uint64_t m = (uint64_t)r * (uint64_t)n;
    return (uint32_t)(m >> 32) + 1;
}

static ERL_NIF_TERM
uniform_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    unsigned int n;
    if (!enif_get_uint(env, argv[0], &n)) {
        return enif_make_badarg(env);
    }
    return enif_make_uint(env, uniform_impl(n));
}

static ErlNifFunc nif_functions[] = {
    {"uniform", 1, uniform_nif, 0},
};

ERL_NIF_INIT(rotor, nif_functions, NULL, NULL, NULL, NULL)
