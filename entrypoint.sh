#!/bin/sh -l
    apt-get update >dev/null; \
    apt-get install -y gcc make curl; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y; \
    . $HOME/.cargo/env; \
    curl -L http://musl.libc.org/releases/musl-1.2.3.tar.gz -o musl-1.2.3.tar.gz; \
    tar -zxvf musl-1.2.3.tar.gz; \
    cd musl-1.2.3; \
    ./configure >dev/null; \
    make -j 2 >dev/null; \
    make install; \
    ln -fs /usr/local/musl/bin/musl-gcc /usr/local/bin/musl-gcc; \
    rustup target add x86_64-unknown-linux-musl; 
# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
. "$HOME/.cargo/env"
cargo install --path . --target x86_64-unknown-linux-musl

# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
  echo "release_dir=/github/workspace/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
  exit 0
else
  echo "release_dir=/github/workspace/$INPUT_PATH/target/x86_64-unknown-linux-musl/release/" >> "$GITHUB_OUTPUT"
  exit 0
fi
