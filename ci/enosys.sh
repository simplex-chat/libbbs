#!/bin/sh
set -eu

cc -shared -fPIC -o out/enosys.so ci/enosys.c -ldl
for test in out/bin/bbs_e2e_*; do
	echo "$test"
	LD_PRELOAD="$PWD/out/enosys.so" strace -f -e trace=openat,getrandom -o out/trace.txt "$test" 2> out/stderr.txt
	cat out/stderr.txt
	if grep -q SYS_getrandom src/bbs.c; then
		grep -q "enosys: getrandom" out/stderr.txt
		grep -q '"/dev/urandom"' out/trace.txt
	fi
done
