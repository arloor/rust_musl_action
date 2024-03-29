#!/bin/sh -l

prepare() {
    apt-get update >/dev/null
    # apt-get install musl-tools curl -y >/dev/null
    apt-get install curl -y >/dev/null
    cd /var/
    wget http://musl.libc.org/releases/musl-1.2.5.tar.gz -O musl-1.2.5.tar.gz
    tar -zxvf musl-1.2.5.tar.gz
    cd musl-1.2.5
    ./configure
    make -j 2
    make install
    ln -fs /usr/local/musl/bin/musl-gcc /usr/local/bin/musl-gcc
    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y;
    export PATH="$HOME/.cargo/bin:$PATH"
    # Install musl target
    rustup target add x86_64-unknown-linux-musl
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
