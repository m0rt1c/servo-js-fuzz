#!/usr/bin/env bash

./run_fuzzer.sh ./target/debug/readable_stream_with_query_strategy ./in/strings
./run_fuzzer.sh ./target/debug/writable_stream ./in/strings
./run_fuzzer.sh ./target/debug/queueing_strategy ./in/numbers
./run_fuzzer.sh ./target/debug/readable_stream_byob_reader ./in/strings
./run_fuzzer.sh ./target/debug/readable_stream_default_controller ./in/strings
./run_fuzzer.sh ./target/debug/writable_stream_default_controller ./in/strings
./run_fuzzer.sh ./target/debug/transform_stream ./in/strings true
./run_fuzzer.sh ./target/debug/pipe_readable_stream ./in/strings
./run_fuzzer.sh ./target/debug/readable_stream ./in/strings
./run_fuzzer.sh ./target/debug/count_queuing_strategy ./in/numbers
./run_fuzzer.sh ./target/debug/eval_script ./in/scripts true
