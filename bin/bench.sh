#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
## Note: `init:stop()` is invoked inside the eval, NOT via `-s init stop`,
## because on OTP 27+ the -s/-eval order is processed differently and a
## trailing `-s init stop` can terminate the node before the eval finishes.
exec erl \
  -noshell \
  -pa _build/bench/lib/*/ebin \
  -pa _build/bench/lib/*/test \
  +K true +scl false +spp true \
  -eval 'rotor_bench:run(), init:stop().'
