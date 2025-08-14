#!/usr/bin/env bash

echo "Collecting servo RUST_BACKTRACE=1 traces"

find ./triage/pocs/ -name index.html -print -exec bash -c 'RUST_BACKTRACE=1 timeout 2 servo -z {} 2>&1 | tee {}.servo.backtrace_one' \;

echo "Collecting servo RUST_BACKTRACE=full traces"

find ./triage/pocs/ -name index.html -print -exec bash -c 'RUST_BACKTRACE=full timeout 2 servo -z {} 2>&1 | tee {}.servo.backtrace_full' \;
