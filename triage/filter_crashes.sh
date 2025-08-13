#!/usr/bin/env bash

set -euo pipefail

TARGET="${1}"

if [ -z "${TARGET}" ]; then
    TARGET="./target/debug/eval_script"
fi

# Copy all the crashes in one single folder

find ./out -type f -path '*/crashes/*' -not -name '*.txt' -exec cp ./triage/crashes \;

# Minimize each crash

find ./triage/crashes -type f -not -name '.gitkeep' -print -exec bash -c 'cargo afl tmin -i ${1} -o ./triage/crashes-min/$(basename ${1}).min.js ${2}' {} "${TARGET}" \;
