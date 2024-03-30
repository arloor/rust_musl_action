#!/bin/sh -l

echo "Github Action: build musl static binary"
echo ========================================
echo "extra_deps: $INPUT_EXTRA_DEPS"
echo "rust_version: $INPUT_RUST_VERSION"
echo "musl_version: $INPUT_MUSL_VERSION"
echo "path: $INPUT_PATH"
echo "args: $INPUT_ARGS"
echo ========================================

apt(){
    apt-get update >/dev/null
    apt-get install curl make gcc "$@" -y >/dev/null
}

musl(){
    cd /var/
    version=$INPUT_MUSL_VERSION
    curl -SsLf http://musl.libc.org/releases/musl-${version}.tar.gz -o musl-${version}.tar.gz
    tar -zxf musl-${version}.tar.gz
    cd musl-${version}
    ./configure > /dev/null
    make -j 2 > /dev/null
    make install > /dev/null
    ln -fs /usr/local/musl/bin/musl-gcc /usr/bin/musl-gcc
    musl-gcc --version
}

rust() {
    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y;
    export PATH="$HOME/.cargo/bin:$PATH"
    if [ "" != "$INPUT_RUST_VERSION" ]; then 
        rustup install $INPUT_RUST_VERSION
        rustup default $INPUT_RUST_VERSION
    fi
    # Install musl target
    rustup target add x86_64-unknown-linux-musl
    rustc --version
}

build(){
    cargo build --release --target x86_64-unknown-linux-musl "$@"
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

apt $INPUT_EXTRA_DEPS
musl
rust

# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
build $INPUT_ARGS
# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
    echo "release_dir=./target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
else
    echo "release_dir=$INPUT_PATH/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
fi
exit 0
