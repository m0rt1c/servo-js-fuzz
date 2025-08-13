#!/usr/bin/env bash

set -euo pipefail

TARGET="./target/debug/eval_script"

if [ "$#" -eq 1 ]; then 
    TARGET="${1}"
fi

# Copy all the crashes in one single folder

find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec cp {} ./triage/crashes \;

# Minimize each crash

find ./triage/crashes -type f -not -name '.gitkeep' -print -exec bash -c 'cargo afl tmin -i ${1} -o ./triage/crashes-min/$(basename ${1}).min.js -- ${2}' {} "${TARGET}" \;
