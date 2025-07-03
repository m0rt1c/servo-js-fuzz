
## Steps

1. `git submodule init && git submodule update --depth 1`
1. `nix-shell ./servo/shell.nix` or follow their documentation on how to install all the build dependencies
1. `rustup install nightly`
1. `cargo afl config --build`
1. `cargo afl build`
