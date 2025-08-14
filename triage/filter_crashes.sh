#!/usr/bin/env bash

set -euo pipefail

TARGET="./target/debug/eval_script"

if [ "$#" -eq 1 ]; then 
    TARGET="${1}"
fi

# Copy all the crashes and traces in one folder

find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec cp {} ./triage/crashes \;
find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec bash -c 'cat ${0} | RUST_BACKTRACE=1 ${1} &> ./triage/crashes/$(basename ${0}).backtrace_one' {} "${TARGET}" \;
find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec bash -c 'cat ${0} | RUST_BACKTRACE=FULL ${1} &> ./triage/crashes/$(basename ${0}).backtrace_full' {} "${TARGET}" \;
