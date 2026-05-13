# Changelog

## 0.1.0

Initial release.

- `rotor:uniform/1` — fast non-cryptographic PRNG NIF, drop-in
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
