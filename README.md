
## Setup

1. Install nix
1. If you are on a server, `sudo apt install xorg -y`
1. `git submodule init && git submodule update --depth 1`
1. `nix-shell` or follow github.com/servo/servo documentation on how to install all the build dependencies and the github.com/AFLplusplus/AFLplusplus requirements
     1. Note: From now on every command is meant to be run in the `nix-shell`
1. `rustup default stable`
1. `cargo install cargo-afl`
1. `cargo afl config --build --force`
1. `AFL_LLVM_CMPLOG=1 cargo afl build`

## Testing

To test that each target is working you may run the following command and observe the output. Where `target_name` is one of the files under `src/bin` without the `.rs` extension: for example `eval_script`.

`cat path/to/test/input | ./target/debug/<target_name>` Note that the command migth hang

or

`AFL_DEBUG=1 RUST_BACKTRACE=full cargo afl fuzz -i in/random -o out/<target_name> target/debug/<target_name>`

You must make sure that the target does not crash with all the inputs, and you may use these to check if your target is behaving correctly

## Fuzzing

### Set up the machine for fuzzing

The following commands set the performance settings required by AFl++. Note that when you restart the machine you **must** run them again.

1. `echo core | sudo tee /proc/sys/kernel/core_pattern`
1. `cd /sys/devices/system/cpu && echo performance | sudo tee cpu*/cpufreq/scaling_governor`

You may start a single core fuzzing instance with: 

`cargo afl fuzz -i in/random -o out target/debug/<target_name>`

Note you may change the `in/random` folder to select different starting inputs
Note you may use just the `in` folder to select all starting inputs
Note that folder `in/custom` is not tracked by git and you may use it to test new inputs

### Wrapper script

To run multiple master and secondary instances on the same target you may use the `run_fuzzer.sh` script like this

```
./run_fuzzer.sh target/debug/<target_name> <in_folder> [true]
```

* #1 arg is the full path of the target
* #2 arg is the full path of the input folder. This is important since each target uses different inputs: scripts, strings, numbers
* #3 is optional and accepts only the value true to start two secondary fuzz instances. Note, this is a work in progress, and it might be worth it to have more secondary instances for better results

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
./run_fuzzer.sh ./target/debug/eval_script ./in/scripts true
```

The `run_all.sh` script contains these commands.

Note, that if you start and stop them manually you might have conflicts in the `out/<target_name>` folder and you might need to rename it or delete it.

### Checking the status

In folder `./out` you will have a folder for each target named after it. For example, `eval_script`. You can use the following command to see the stats of the fuzzer.

```
cargo afl whatsup -s -m ./out/eval_script # or any other target
```

Or use `./check_status.sh`

The output will look like
```
./out/readable_stream_byob_reader
Summary stats
=============
        Fuzzers alive : 1
       Total run time : 6 minutes, 1 seconds
Current average speed : 25 execs/sec
   Pending per fuzzer : 1 faves, 107 total (on average)
     Coverage reached : 2.98%
        Crashes saved : 0
   Time without finds : 38 seconds
```

The important things here are:

1. `Fuzzers alive : 1` how many fuzzers are running. Less than one means we are not fuzzing this target, maybe we stopped it or maybe there was some other error
1. `Current average speed : 25 execs/sec` how fast we are fuzzing. We would like to see something above 100
1. `Coverage reached : 2.98%` coverage reached by the fuzzer. If this does not improve over time we need to rethink the targets or the inputs (or just wait more time)
1. `Crashes saved : 0` how many crashes the fuzzer found. If this is above zero we need to go to folder `out/<target_name>/<intance_name>/crashes/` and start triaging the crash. For example, with `cat path/to/crash/file | ./target/debug/<target_name>`
1. `Timme without finds : 38 seconds` this tells the last time the fuzzer found a new path, if this grows too much the fuzzer will stop as it is not able to find new paths. Again here we need to rethink the targets and the inputs because in a way that they make it possible to explore new paths while fuzzing

### Adding a new target

To add a new target, it is enough to create a new file under `./src/bin/` with a new name and implement the target following the examples of the others. For example, the `readable_stream` target.

```rs
#[macro_use]
extern crate afl;
extern crate servo;

use std::sync::OnceLock;

use servo_js_fuzz::{ServoTest, run_script_on};
thread_local! {
  static SERVO_LOCK: OnceLock<ServoTest> = OnceLock::new();
}

const SCRIPT_FORMAT: &str = r#"
function target(input) {
    const readableStream = new ReadableStream({
        start(controller) {
            controller.enqueue(new TextEncoder().encode(input));
            controller.close();
        }
    });

    const reader = readableStream.getReader();

    function readNext() {
        reader.read().then(({ done, value }) => {
            if (done) return;
            readNext();
        });
    }

    readNext();
}
target("%input%")
"#;

fn main() {
    fuzz!(|data: &[u8]| {
        if let Ok(input_data) = std::str::from_utf8(data) {
            SERVO_LOCK.with(|cell| {
                let servo_test = cell.get_or_init(|| ServoTest::new());
                let script = SCRIPT_FORMAT.replace("%input%", input_data);
                let _ = run_script_on(servo_test, &script);
            });
        }
    });
}
```


The fuzzer entry point is the `fuzz!` macro in the main function that takes a lambda as input with a `u8` slice pointer. This slice pointer is the input generated by the fuzzer and can be combined with a script, like in this case, or used directly, like in the `eval_script` example.

Note, it is important to use a `OnceLock` in order to initialize the Servo instance only once and to have thread-safe access to it.

### Adding a new inputs

To add new inputs it is enough to place thme under one of the `./in` folders. Note that adding them while the fuzzer is running will not add them to the queues you have to restart the fuzzer for it to see them. 

## References

1. AFL++ Overview [https://aflplus.plus/](https://aflplus.plus/)
1. AFL++ Fuzzing in depth [https://aflplus.plus/docs/fuzzing_in_depth/](https://aflplus.plus/docs/fuzzing_in_depth/)
1. Rust Fuzz Book [https://rust-fuzz.github.io/book/afl.htm](https://rust-fuzz.github.io/book/afl.htm)
