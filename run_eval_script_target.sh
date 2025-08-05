#!/usr/bin/env bash

set -x -euo pipefail

TARGET="./target/debug/eval_script"
INPUT_DIR="./in/scripts"
SESSION_NAME=$(basename "${TARGET}")
OUTPUT_DIR="./out/${SESSION_NAME}"
CARGO_FUZZ="cargo afl fuzz -i ${INPUT_DIR} -o ${OUTPUT_DIR}"

function create_wait_tmux_window {
  tmux new-window -t "$SESSION_NAME" -n "${1}"
  wait_tmux_window "${1}"
}

function wait_tmux_window {
  while ! tmux list-windows -t "${SESSION_NAME}" | grep -q "^0: ${1}"; do
    sleep 0.1
  done
}

function run_in_window {
  tmux send-keys -t "${SESSION_NAME}:${1}" "nix-shell --run '${2}'" C-m
}

function create_and_run {
  create_wait_tmux_window "${1}"
  run_in_window "${1}" "${2}"
}

# Kill existing tmux session
tmux kill-session -t "${SESSION_NAME}" 2>/dev/null || true

# --- Main instance ---
NAME="main"
CMD="AFL_FINAL_SYNC=1 ${CARGO_FUZZ} -M main-${SESSION_NAME} ${TARGET}"

tmux new-session -d -s "${SESSION_NAME}" -n "${NAME}"
wait_tmux_window "${NAME}"
run_in_window "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-0"
CMD="AFL_IMPORT_FIRST=1 AFL_USE_ASAN=1 AFL_USE_UBSAN=1 AFL_USE_CFISAN=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-1"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -l 2AT ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-3"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -l 2AT ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-4"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -L 0 ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-5"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -Z ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-6"
CMD="AFL_IMPORT_FIRST=1 AFL_DISABLE_TRIM=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-7"
CMD="AFL_IMPORT_FIRST=1 AFL_DISABLE_TRIM=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-8"
CMD="AFL_IMPORT_FIRST=1 AFL_DISABLE_TRIM=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-9"
CMD="AFL_IMPORT_FIRST=1 AFL_DISABLE_TRIM=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P exploit ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-10"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-11"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-12"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P explore ${TARGET}"
create_and_run "${NAME}" "${CMD}"

# --- Secondary instance ---
NAME="sec-13"
CMD="AFL_IMPORT_FIRST=1 ${CARGO_FUZZ} -S sec-${SESSION_NAME}-${NAME} -P exploit ${TARGET}"
create_and_run "${NAME}" "${CMD}"
