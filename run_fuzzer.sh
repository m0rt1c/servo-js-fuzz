#!/bin/bash

set -euo pipefail

SESSION_NAME=$(basename $1)
TARGET=$1
INPUT_DIR=$2
OUTPUT_DIR=$3
CORES=$4

export AFL_TESTCACHE_SIZE=200
export AFL_IMPORT_FIRST=1
export AFL_FINAL_SYNC=1
export AFL_IGNORE_SEED_PROBLEMS=1
export AFL_NO_AFFINITY=1

tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
tmux new-session -d -s "$SESSION_NAME" -n main

# --- MASTER INSTANCE (LAF-INTEL + persistent) ---
tmux send-keys -t "$SESSION_NAME:main" \
	"AFL_LLVM_LAF_ALL=1 AFL_LLVM_INSTRUMENT=PCGUARD cargo afl fuzz -i $INPUT_DIR -o $OUTPUT_DIR -M main-${SESSION_NAME} -p fast $TARGET" C-m

# --- SECONDARY INSTANCES ---
for i in $(seq 0 8); do
    WIN="sec-$i"
    CMD_PREFIX=""
    SCHED=""
    ARGS=""
    ENV_VARS=""

    case $i in
        0)
            CMD_PREFIX="AFL_USE_ASAN=1 AFL_USE_UBSAN=1"
            SCHED="-p exploit"
            ;;
        1)
            CMD_PREFIX="AFL_LLVM_CMPLOG=1"
            SCHED="-p explore"
            ;;
        2)
            CMD_PREFIX="AFL_LLVM_LAF_ALL=1"
            SCHED="-p coe"
            ;;
        3)
            ARGS="-L 0"
            SCHED="-p quad"
            ;;
        4)
            ARGS="-Z"
            SCHED="-p lin"
            ;;
        5)
            ENV_VARS="AFL_DISABLE_TRIM=1"
            SCHED="-p rare"
            ;;
        6)
            ENV_VARS="AFL_DISABLE_TRIM=1"
            SCHED="-p explore"
            ;;
        7)
            ENV_VARS="AFL_DISABLE_TRIM=1"
            ARGS="-a ascii"
            SCHED="-p exploit"
            ;;
        8)
            ARGS="-a binary"
            SCHED="-p fast"
            ;;
    esac

    tmux new-window -t "$SESSION_NAME" -n "$WIN"
    tmux send-keys -t "$SESSION_NAME:$WIN" \
        "$ENV_VARS $CMD_PREFIX cargo afl fuzz -i $INPUT_DIR -o $OUTPUT_DIR -S sec-$SESSION_NAME-$i $ARGS $SCHED $TARGET" C-m
done

# Attach to tmux
tmux select-window -t "$SESSION_NAME:main"
tmux attach-session -t "$SESSION_NAME"

