#!/bin/sh
set -eu

DIR=/data/local/tmp/libbbs
adb shell "rm -rf $DIR && mkdir -p $DIR"
adb push out/bin/. "$DIR"
adb shell "cd $DIR && failed=0 && for t in *; do echo \$t; chmod 755 \$t; ./\$t || failed=1; done && exit \$failed"
