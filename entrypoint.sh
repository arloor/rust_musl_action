#!/bin/sh -l

echo "Github Action: build musl static binary"
echo ========================================
echo "extra_deps: $INPUT_EXTRA_DEPS"
echo "rust_version: $INPUT_RUST_VERSION"
echo "use_musl: $INPUT_USE_MUSL"
echo "musl_version: $INPUT_MUSL_VERSION"
echo "path: $INPUT_PATH"
echo "args: $INPUT_ARGS"
echo "debug: $INPUT_DEBUG"
echo "apt_mirror: $INPUT_APT_MIRROR"
echo ========================================

apt(){
    if [ -n "$INPUT_APT_MIRROR" ]; then  # 更简洁的非空检查
        echo "Using mirror: $INPUT_APT_MIRROR"
        if sed -i "s/archive.ubuntu.com/$INPUT_APT_MIRROR/g" /etc/apt/sources.list; then
            echo "Sources list updated successfully."
            if [ "true" = "$INPUT_USE_MUSL" ]; then
                cat /etc/apt/sources.list  # 可选，根据需要查看或省略
            fi
        else
            echo "Failed to update sources list."
            # exit 1  # 添加错误退出状态
        fi
    else
        echo "No mirror specified. Skipping updates."
    fi


    if [ "true" = "$INPUT_DEBUG" ]; then
        apt-get update
        apt-get install curl make gcc "$@" -y
    else
        apt-get update > /dev/null
        apt-get install curl make gcc "$@" -y > /dev/null
    fi
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
    # Install musl target
    rustup target add x86_64-unknown-linux-musl
}

rust() {
    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y;
    export PATH="$HOME/.cargo/bin:$PATH"
    if [ "" != "$INPUT_RUST_VERSION" ]; then 
        rustup install $INPUT_RUST_VERSION
        rustup default $INPUT_RUST_VERSION
    fi
    rustc --version
}

build(){
    if [ "true" = "$INPUT_USE_MUSL" ]; then
        cargo build --release --target x86_64-unknown-linux-musl "$@"
    else
        cargo build --release "$@"
    fi
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

apt $INPUT_EXTRA_DEPS
rust
if [ "true" = "$INPUT_USE_MUSL" ]; then
    echo "Using musl"
    musl_path_part="/x86_64-unknown-linux-musl"
    musl
fi

# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
build $INPUT_ARGS
# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
    echo "release_dir=./target${musl_path_part}/release/" >> "$GITHUB_OUTPUT"
else
    echo "release_dir=$INPUT_PATH/target${musl_path_part}/release/" >> "$GITHUB_OUTPUT"
fi
exit 0
