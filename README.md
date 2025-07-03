
## Setup

1. Install nix
1. `git submodule init && git submodule update --depth 1`
1. `nix-shell` or follow github.com/servo/servo documentation on how to install all the build dependencies and the github.com/AFLplusplus/AFLplusplus requirements
1. `rustup default stable`
1. `cargo afl config --build`
1. `cargo afl build`

## Testing

To test that each target is working you may run the following command and observe the output. Where `target_name` is one of the files under `src/bin` without the `.rs` extension: for example `random_script`.

`cargo afl run --bin <target_name> < path/to/test/corpus`

Note that the command will hange since it expect the corpus to crash it

## Fuzzing

You may start a single core fuzzing instance with: 

`cargo afl fuzz -i in/random -o out target/debug/<target_name>`

Note you  may change the `in/random` folder to select different starting inputs
Note that folder in/custom is not tracked by git and you may use it to test new inputs
