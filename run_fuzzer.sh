#!/bin/bash

set -euo pipefail

export AFL_TESTCACHE_SIZE=200
export AFL_IMPORT_FIRST=1
export AFL_FINAL_SYNC=1
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_AFFINITY=1

INPUT_DIR="./in"

for TARGET in $(find ./target/debug -maxdepth 1 -type f -executable);
do
    SESSION_NAME=$(basename $TARGET)
    OUTPUT_DIR="./out/$SESSION_NAME"

    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

    # --- Main instance
    tmux new-session -d -s "$SESSION_NAME" -n "main"
    tmux send-keys -t "$SESSION_NAME:main" \
        "AFL_LLVM_LAF_ALL=1 AFL_LLVM_INSTRUMENT=PCGUARD AFL_FINAL_SYNC=1 cargo afl fuzz -i $INPUT_DIR -o $OUTPUT_DIR -M main-${SESSION_NAME} -p fast $TARGET" C-m

    # --- Secondary instances ---

    tmux new-window -t "$SESSION_NAME" -n "secondary #0"
    tmux send-keys -t "$SESSION_NAME:$WIN" \
        "AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_USE_CFISAN=1 cargo afl fuzz -i $INPUT_DIR -o $OUTPUT_DIR -S sec-${SESSION_NAME}-1 $TARGET" C-m

    tmux new-window -t "$SESSION_NAME" -n "secondary #1"
    tmux send-keys -t "$SESSION_NAME:$WIN" \
        "cargo afl fuzz -i $INPUT_DIR -o $OUTPUT_DIR -S sec-${SESSION_NAME}-2 -l 2AT $TARGET" C-m
done
