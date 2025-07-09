#!/bin/bash

set -x -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-binary>"
  exit 1
fi

TARGET="$1"
INPUT_DIR="${INPUT_DIR:-./in}"
SESSION_NAME=$(basename "$TARGET")
OUTPUT_DIR="./out/$SESSION_NAME"

# Environment config
export AFL_TESTCACHE_SIZE=200
export AFL_IMPORT_FIRST=1
export AFL_FINAL_SYNC=1
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_AFFINITY=1

# Kill existing tmux session
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# --- Main instance ---
tmux new-session -d -s "$SESSION_NAME" -n "main"
tmux send-keys -t "$SESSION_NAME:main" \
  "AFL_LLVM_LAF_ALL=1 AFL_LLVM_INSTRUMENT=PCGUARD cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -M main-${SESSION_NAME} \"$TARGET\"" C-m

SECONDARY="$2"

if [ "$SECONDARY" == "true" ]; then
    # --- Secondary instance 1 ---
    tmux new-window -t "$SESSION_NAME" -n "sec1"
    tmux send-keys -t "$SESSION_NAME:sec1" \
    "AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_USE_CFISAN=1 cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -S sec-${SESSION_NAME}-1 \"$TARGET\"" C-m

    # --- Secondary instance 2 ---
    tmux new-window -t "$SESSION_NAME" -n "sec2"
    tmux send-keys -t "$SESSION_NAME:sec2" \
    "cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -S sec-${SESSION_NAME}-2 -l 2AT \"$TARGET\"" C-m
fi
