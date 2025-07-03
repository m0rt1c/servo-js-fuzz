
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

You may start a single core fuzzing instance with: 

`cargo afl fuzz -i in/random -o out target/debug/<target_name>`

Note you may change the `in/random` folder to select different starting inputs
Note you may use just the `in` folder to select all starting inputs
Note that folder in/custom is not tracked by git and you may use it to test new inputs

### Wrapper script

To run multiple master and secondary instances on the same target you may use the `run_fuzzer.sh` script like this

```
./run_fuzzer.sh target/debug/<target_name> in out 10
```

* #1 arg is the full path of the target
* #2 arg is the full path of the input folder
* #3 arg is the full path of the output folder, afl will automatically create subdirs based on the main and secondary names **but you may still have conflicts** so you might need to set it to `out/something`
* #4 arg is the number of cores to use from 2 to 10, this is not yet checked or enfored in the script

This script will create a tmux instance with a sub instance for each main and secondary instances, not the best but it is a simple example
