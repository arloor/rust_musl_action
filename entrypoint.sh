#!/bin/sh -l

echo -e "\e[32m=========================================\e[0m"
echo "extra_deps: $INPUT_EXTRA_DEPS"
echo "after_install: $INPUT_AFTER_INSTALL"
echo "rust_version: $INPUT_RUST_VERSION"
echo "use_musl: $INPUT_USE_MUSL"
echo "musl_version: $INPUT_MUSL_VERSION"
echo "use_zigbuild: $INPUT_USE_ZIGBUILD"
echo "zig_version: $INPUT_ZIG_VERSION"
echo "zig_glibc_version: $INPUT_ZIG_GLIBC_VERSION"
echo "path: $INPUT_PATH"
echo "args: $INPUT_ARGS"
echo "debug: $INPUT_DEBUG"
echo "apt_mirror: $INPUT_APT_MIRROR"
echo "rust_flags: ${RUSTFLAGS}"
echo -e "\e[32m=========================================\e[0m"

setup_apt_source() {
    if [ -n "$INPUT_APT_MIRROR" ]; then # 更简洁的非空检查
        echo "Using mirror: $INPUT_APT_MIRROR"
        if sed -i "s/archive.ubuntu.com/$INPUT_APT_MIRROR/g" /etc/apt/sources.list; then
            echo "Sources list updated successfully."
            if [ "true" = "$INPUT_DEBUG" ]; then
                echo -e "\e[32mcurrent /etc/apt/sources.list:\e[0m"
                cat /etc/apt/sources.list
                echo -e "\e[32m=============/etc/apt/sources.list END================\e[0m"
            fi
        else
            echo -e "\e[31mFailed to update sources list.\e[0m"
            exit 1 # 添加错误退出状态
        fi
    fi
}

apt_install() {
    [ -n "$1" ] && {
        if [ "$setup_apt_source_done" != "1" ]; then
            setup_apt_source
            setup_apt_source_done=1
        fi
        start=$(date +%s)
        echo install "$@"
        if [ "true" = "$INPUT_DEBUG" ]; then
            apt-get update
            apt-get install "$@" -y
        else
            apt-get update >/dev/null
            apt-get install "$@" -y >/dev/null
        fi
        end=$(date +%s)
        echo -e "\e[32m=============install ""$@"" in $((end - start)) seconds ================\e[0m"
    }
}

install_musl() {
    start=$(date +%s)
    cd /var/
    version=$INPUT_MUSL_VERSION
    curl -SsLf http://musl.libc.org/releases/musl-${version}.tar.gz -o musl-${version}.tar.gz
    tar -zxf musl-${version}.tar.gz
    cd musl-${version}
    ./configure >/dev/null
    make -j 2 >/dev/null
    make install >/dev/null
    ln -fs /usr/local/musl/bin/musl-gcc /usr/bin/musl-gcc
    musl-gcc --version
    # Install musl target
    rustup target add x86_64-unknown-linux-musl
    end=$(date +%s)
    echo -e "\e[32m=============compile musl-gcc in $((end - start)) seconds ================\e[0m"
}

install_rust() {
    start=$(date +%s)
    if [ "" != "$INPUT_RUST_VERSION" ]; then
        local version_part="--default-toolchain $INPUT_RUST_VERSION"
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y $version_part
    export PATH="$HOME/.cargo/bin:$PATH"
    rustc --version
    end=$(date +%s)
    echo -e "\e[32m=============install rust in $((end - start)) seconds ================\e[0m"
}

install_zig() {
    start=$(date +%s)
    version=$INPUT_ZIG_VERSION
    name=zig-x86_64-linux-${version}
    echo "Installing zig ${version}..."
    curl -SsLf https://ziglang.org/download/${version}/${name}.tar.xz -o- | tar -xJf - -C /tmp
    export PATH="/tmp/${name}:$PATH"
    zig version
    echo "Installing cargo-zigbuild..."
    cargo install cargo-zigbuild
    end=$(date +%s)
    echo -e "\e[32m=============install zig and cargo-zigbuild in $((end - start)) seconds ================\e[0m"
}

build() {
    start=$(date +%s)
    if [ "true" = "$INPUT_USE_ZIGBUILD" ]; then
        cargo zigbuild --release --target x86_64-unknown-linux-gnu.${INPUT_ZIG_GLIBC_VERSION} "$@"
    elif [ "true" = "$INPUT_USE_MUSL" ]; then
        cargo build --release --target x86_64-unknown-linux-musl "$@"
    else
        cargo build --release --target x86_64-unknown-linux-gnu "$@"
    fi
    if [ $? -ne 0 ]; then
        exit 1
    fi
    end=$(date +%s)
    echo -e "\e[32m=============build finished in $((end - start)) seconds ================\e[0m"
}

apt_install curl gcc $INPUT_EXTRA_DEPS
install_rust

if [ "true" = "$INPUT_USE_ZIGBUILD" ]; then
    echo "Using cargo zigbuild"
    install_zig
elif [ "true" = "$INPUT_USE_MUSL" ]; then
    echo "Using musl"
    apt_install make
    install_musl
fi

if [ "true" = "$INPUT_USE_MUSL" ]; then
    target_part_path="/x86_64-unknown-linux-musl"
else
    target_part_path="/x86_64-unknown-linux-gnu"
fi

if [ "" != "$INPUT_AFTER_INSTALL" ]; then
    eval "$INPUT_AFTER_INSTALL"
    echo -e "\e[32m============= run commands after install END ================\e[0m"
fi

echo -e "\e[32mCompiling Rust crate.....\e[0m"
# Use INPUT_<INPUT_NAME> to get the value of an input
echo "cd /github/workspace/$INPUT_PATH"
cd /github/workspace/$INPUT_PATH
build $INPUT_ARGS
# Write outputs to the $GITHUB_OUTPUT file
if [ "" = "$INPUT_PATH" ]; then
    echo "release_dir=./target${target_part_path}/release" >>"$GITHUB_OUTPUT"
else
    echo "release_dir=$INPUT_PATH/target${target_part_path}/release" >>"$GITHUB_OUTPUT"
fi
exit 0
