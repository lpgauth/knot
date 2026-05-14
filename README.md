# knot

Fast non-cryptographic PRNG NIF for Erlang. One function: `knot:uniform/1`.

[wyrand][wyrand] (1 multiply + 1 xor + 1 add per draw; passes BigCrush),
bounded via biased multiply-and-shift (bias < 1e-7 for the small bounds
shackle uses). State is per OS thread via `__thread` — no locks on the
hot path. Lazy seeding from `getrandom`/`arc4random_buf` on first use.

A drop-in replacement for `granderl:uniform/1` that builds cleanly on
modern OTP and scales linearly across schedulers.

[wyrand]: https://github.com/wangyi-fudan/wyhash

## API

```erlang
-spec knot:uniform(pos_integer()) -> pos_integer().
```

`uniform(N)` returns a uniformly random integer in `[1, N]`. `N` must
fit in a `u32` (1..=4_294_967_295).

## Install

```erlang
{deps, [{knot, "0.1.0"}]}.
```

Requires a C compiler (`cc`) on the build host — universally available
on systems that already run Erlang. No Rust toolchain, no cargo, no
extra deps.

## Build

`rebar3 compile` runs `c_src/build.sh`, which:

- Resolves `ERTS_INCLUDE_DIR` via `erl -noshell -eval ... -s init stop`
  (option order is correct for OTP 27+ — the bug that affected
  `granderl 0.1.5` is fixed here).
- Compiles `c_src/knot.c` with `-O3 -march=native -mtune=native`.
- Outputs `priv/knot.so`.

Env vars honored:

| Var | Effect |
|---|---|
| `ERTS_INCLUDE_DIR` | Skip the `erl` probe; use this path for `erl_nif.h`. |
| `CC` | Compiler (default `cc`). |
| `CFLAGS` | Extra flags appended after defaults. |
| `KNOT_NO_NATIVE` | If set, omit `-march=native`/`-mtune=native` (use for portable cross-platform builds). |

## Benchmark

Apple Silicon (M-series), OTP 29, 10M iterations of `uniform(254)`,
median of 5 runs:

| concurrency | `rand:uniform/1` | `granderl:uniform/1` | `knot:uniform/1` |
|---|---|---|---|
| 1 | 34 ns/op | 13 ns/op | **12 ns/op** |
| 8 | 8 ns/op | 7 ns/op | **3.3 ns/op** |
| 32 | 6 ns/op | 8 ns/op | **3.2 ns/op** |
| 128 | 6 ns/op | 8.5 ns/op | **3.1 ns/op** |

Single-process: dispatch-bound (~12 ns is the NIF boundary floor for
both knot and granderl).

Concurrent: knot scales linearly across schedulers because state is
strictly per-OS-thread (`__thread uint64_t`), no atomics or locks
anywhere on the hot path.

Reproduce: `make bench`.

## License

MIT.
