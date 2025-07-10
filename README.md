
## Setup

1. Install nix
1. `git submodule init && git submodule update --depth 1`
1. `nix-shell` or follow github.com/servo/servo documentation on how to install all the build dependencies and the github.com/AFLplusplus/AFLplusplus requirements
1. `rustup default stable`
1. `cargo afl config --build`
1. `cargo afl build`

## Testing

To test that each target is working you may run the following command and observe the output. Where `target_name` is one of the files under `src/bin` without the `.rs` extension: for example `random_script`.

`cat path/to/test/input | ./target/debug/<target_name>`

Note that the command will hange since it expect the corpus to crash it
You must make sure that the target does not crash with all the inputs, and you may use this to check if your target is behaving correctly

## Fuzzing

### Set up the machine for fuzzing

1. `echo core | sudo tee /proc/sys/kernel/core_pattern`
1. `cd /sys/devices/system/cpu && echo performance | sudo tee cpu*/cpufreq/scaling_governor`

You may start a single core fuzzing instance with: 

`cargo afl fuzz -i in/random -o out target/debug/<target_name>`

Note you may change the `in/random` folder to select different starting inputs
Note you may use just the `in` folder to select all starting inputs
Note that folder in/custom is not tracked by git and you may use it to test new inputs

### Wrapper script

To run multiple master and secondary instances on the same target you may use the `run_fuzzer.sh` script like this

```
./run_fuzzer.sh target/debug/<target_name> <in_folder> [true]
```

* #1 arg is the full path of the target
* #2 arg is the full path of the input folder. This is important since each target uses different inputs: scripts, strings, numbers
* #3 is optional and accepts only value true to start two secondary fuzz instances. Note, this is a work in progress and it might be worth to have more secondary instances for bettere results.

This script will create a tmux instance with a sub instance for each main and secondary instances, not the best but it is a simple example

For example, the all the targets may be started with the following commands. Note, that each instance (main, or secondary) needs a core for itself. So you are limited by the number of CPUs you have (in my case 16). You may list them with `lscpu`.

```bash
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
./run_fuzzer.sh ./target/debug/random_script ./in/scripts true
```

The `run_all.sh` script contains these commands.

### Checking the status

In folder `./out` you will have a folder for each target named after it. For example, `random_script`. You can use the following command to see the stats of the fuzzer.

```
cargo afl whatsup ./out/random_script # or any other target
```
