# Changelog

## 0.1.1

### Changed

- `knot:uniform/1` spec tightened from `pos_integer() -> pos_integer()`
  to `1..4294967295 -> 1..4294967295`. The NIF's C-side argument is
  `enif_get_uint` (unsigned 32-bit), so values above `2^32 - 1` raise
  `badarg`. The previous spec lied — dialyzer now catches the
  out-of-range cases at compile time.

- Module and function docstrings (`@doc`) added — algorithm,
  per-thread state, lazy seeding, the bounded-output bias bound, and
  the `badarg` semantics for over-range inputs are now in the
  generated hexdocs without having to read `c_src/knot.c`.

No behavioural changes; no new code paths.

## 0.1.0

Initial release.

- `knot:uniform/1` — fast non-cryptographic PRNG NIF, drop-in
  replacement for `granderl:uniform/1`. Uses wyrand (1 multiply +
  1 xor + 1 add per draw, BigCrush-passing) with the biased
  multiply-and-shift bounded method (single multiply, no rejection
  branch; bias < 1e-7 for bounds ≤ 256).
- Pure C NIF — ~75 LOC. No Rust toolchain, no cargo, no rustler.
  Per-OS-thread state via `__thread`. Lazy seed from `getrandom`/
  `arc4random_buf`.
- Build via `c_src/build.sh` (granderl-style `pre_hooks`), with the
  OTP 27+ `erl -noshell -s init stop -eval` order bug fixed —
  `-eval` runs before init terminates.
