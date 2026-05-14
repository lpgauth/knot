#!/usr/bin/env bash
#
# Build knot's NIF.
#
# Honors:
#   ERTS_INCLUDE_DIR : path to erl_nif.h (default: derived from `erl`)
#   CC               : compiler (default: cc)
#   CFLAGS           : extra compile flags appended after defaults
#   KNOT_NO_NATIVE  : if set, skip -march=native (use for portable builds)
#
# Sources the ERTS include dir via `erl -noshell -eval ... -s init stop`
# with the **correct option order** — `-eval` comes *before* `-s init stop`
# so that on OTP 27+ the eval runs before init terminates the node.

set -eu

cd "$(dirname "$0")/.."

if [ -z "${ERTS_INCLUDE_DIR:-}" ]; then
    ERTS_INCLUDE_DIR=$(erl -noshell \
        -eval 'io:format("~s/erts-~s/include/", [code:root_dir(), erlang:system_info(version)]).' \
        -s init stop)
fi

CC=${CC:-cc}
TARGET=priv/knot.so
SRC=c_src/knot.c

BASE_CFLAGS="-fPIC -O3 -std=gnu11 -Wall -Wextra -Wno-missing-field-initializers"
if [ -z "${KNOT_NO_NATIVE:-}" ]; then
    BASE_CFLAGS="$BASE_CFLAGS -march=native -mtune=native"
fi

LDFLAGS="-shared"
if [ "$(uname -s)" = "Darwin" ]; then
    LDFLAGS="$LDFLAGS -undefined dynamic_lookup"
fi

mkdir -p priv
exec $CC \
    $BASE_CFLAGS \
    -I"$ERTS_INCLUDE_DIR" \
    ${CFLAGS:-} \
    $LDFLAGS \
    -o "$TARGET" \
    "$SRC"
