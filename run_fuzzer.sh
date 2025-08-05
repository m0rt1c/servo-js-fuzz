#!/usr/bin/env bash

set -x -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target-binary> <input-dir-path> [true]"
  echo "Set true to add two secondary instances, instead of just one main instance"
  exit 1
fi

TARGET="$1"
INPUT_DIR="$2"
SESSION_NAME=$(basename "$TARGET")
OUTPUT_DIR="./out/$SESSION_NAME"

if [ -d "${OUTPUT_DIR}" ]; then
  # In case the output dir exists already we recover the past job
  echo "OUTPUT_DIR already exists, recovering past fuzzing session"
  echo "If you want to start from a clean state remove or rename foler '${OUTPUT_DIR}'"
  INPUT_DIR="-"
fi

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
while ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
  sleep 0.1
done
while ! tmux list-windows -t "$SESSION_NAME" | grep -q "^0: main"; do
  sleep 0.1
done
tmux send-keys -t "$SESSION_NAME:main" \
  "nix-shell --run 'AFL_LLVM_LAF_ALL=1 AFL_LLVM_INSTRUMENT=PCGUARD cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -M main-${SESSION_NAME} \"$TARGET\"'" C-m

if [[ $# -ge 3 ]]; then
  SECONDARY="$3"

  if [ "$SECONDARY" == "true" ]; then
    # --- Secondary instance 1 ---
    tmux new-window -t "$SESSION_NAME" -n "sec0"
    while ! tmux list-windows -t "$SESSION_NAME" | grep -q "sec0"; do
      sleep 0.1
    done
    tmux send-keys -t "$SESSION_NAME:sec0" \
      "nix-shell --run 'AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_USE_CFISAN=1 cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -S sec-${SESSION_NAME}-1 \"$TARGET\"'" C-m

    # --- Secondary instance 2 ---
    tmux new-window -t "$SESSION_NAME" -n "sec1"
    while ! tmux list-windows -t "$SESSION_NAME" | grep -q "sec1"; do
      sleep 0.1
    done
    tmux send-keys -t "$SESSION_NAME:sec1" \
      "nix-shell --run 'cargo afl fuzz -i \"$INPUT_DIR\" -o \"$OUTPUT_DIR\" -S sec-${SESSION_NAME}-2 -l 2AT \"$TARGET\"'" C-m
  fi
fi
