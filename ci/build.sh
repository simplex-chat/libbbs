#!/bin/sh
set -eu

CC=${CC:-cc}
AR=${AR:-ar}
DEFS=${DEFS:-}
LIBS=${LIBS:-}
EXTRA_SOURCES=${EXTRA_SOURCES:-}
EXE=${EXE:-}
SHARED=${SHARED:-}
RUN=${RUN:-1}
OUT=${OUT:-out}
BLST=${BLST:-blst}
FIXTURES=${FIXTURES:-fixtures}
SUITES="bls12-381-sha-256 bls12-381-shake-256"

if [ ! -d "$BLST" ]; then
	git clone -q https://github.com/supranational/blst.git "$BLST"
	git -C "$BLST" checkout -q "$BLST_COMMIT"
fi

CFLAGS="-O2 -fPIC -D__BLST_PORTABLE__ -DENABLE_MODULE_RECOVERY=1 $DEFS -I$BLST/bindings -I$BLST/src -Iinclude -Isrc"

mkdir -p "$OUT/lib" "$OUT/test" "$OUT/bin"
for src in src/bbs.c src/bbs_ciphersuites.c src/bbs_util.c src/compat-string.c src/sha256.c src/shake256.c \
	"$BLST/src/server.c" "$BLST/build/assembly.S" $EXTRA_SOURCES; do
	$CC $CFLAGS -c "$src" -o "$OUT/lib/$(basename "$src").o"
done
rm -f "$OUT/libbbs.a"
$AR rcs "$OUT/libbbs.a" "$OUT"/lib/*.o
if [ -n "$SHARED" ]; then
	$CC -shared -o "$OUT/libbbs$SHARED" "$OUT"/lib/*.o $LIBS
fi
if [ -n "${LIB_ONLY:-}" ]; then
	exit 0
fi

for suite in $SUITES; do
	$CC $CFLAGS -Itest -c "$FIXTURES/fixtures_$suite.c" -o "$OUT/test/fixtures_$suite.o"
done
for test in test/bbs_fix_*.c test/bbs_e2e_*.c; do
	name=$(basename "$test" .c)
	$CC $CFLAGS -Itest -c "$test" -o "$OUT/test/$name.o"
	printf 'int %s();\nint main(void) { return %s(); }\n' "$name" "$name" > "$OUT/test/main_$name.c"
	$CC $CFLAGS -c "$OUT/test/main_$name.c" -o "$OUT/test/main_$name.o"
	for suite in $SUITES; do
		$CC -o "$OUT/bin/${name}_$suite$EXE" "$OUT/test/main_$name.o" "$OUT/test/$name.o" \
			"$OUT/test/fixtures_$suite.o" "$OUT/libbbs.a" $LIBS
	done
done

if [ "$RUN" = 1 ]; then
	for test in "$OUT"/bin/*; do
		echo "$test"
		"$test"
	done
fi
