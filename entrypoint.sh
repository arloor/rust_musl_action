#!/bin/sh -l

prepare() {
    # Install Rust
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
    # Install musl target
    rustup target add x86_64-unknown-linux-musl
    # Install musl-gcc
    sudo apt-get update
    sudo apt-get install musl-tools
    # Install cargo-make
    cargo install --force cargo-make
}

prepare

# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
cargo install --path . --target x86_64-unknown-linux-musl
# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
    echo "release_dir=./target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
else
    echo "release_dir=$INPUT_PATH/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
fi
exit 0
