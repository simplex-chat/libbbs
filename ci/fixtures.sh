#!/bin/sh
set -eu

OUT=${1:-fixtures}
TEST_DIR=$(pwd)/test

mkdir -p "$OUT"
cc -O2 -o "$OUT/fixtures_transpiler" test/fixtures_transpiler.c
cd "$OUT"
for suite in bls12-381-sha-256 bls12-381-shake-256; do
	./fixtures_transpiler "$suite" "$TEST_DIR"
done
