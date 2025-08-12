#!/usr/bin/env bash

# Copy all the crashes in one single folder

find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec cp {} ./triage/crashes \;

# Use afl tmin to minimize the crash corpus

find ./triage/crashes -type f -not -name '.gitkeep' -print -exec bash -c 'cargo afl tmin -i {} -o ./triage/crashes-min/$(basename {}).min.js -- ./target/debug/eval_script' \;

# Use afl cmin to find unique crashes

cargo afl tmin -C -i ./triage/crashes-min/ -o ../triage/crashes-unique/ ./target/debug/eval_script


