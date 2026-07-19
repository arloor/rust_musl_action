FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 基础工具 + musl/zig 构建依赖一并装好
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gcc \
    make \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 预装 Rust stable
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- --default-host x86_64-unknown-linux-gnu -y
ENV PATH="/root/.cargo/bin:${PATH}"

# 预编译 musl 1.2.5（默认版本）
RUN curl -SsLf https://musl.libc.org/releases/musl-1.2.5.tar.gz | tar -xz -C /tmp \
    && cd /tmp/musl-1.2.5 \
    && ./configure >/dev/null \
    && make -j"$(nproc)" >/dev/null \
    && make install >/dev/null \
    && ln -fs /usr/local/musl/bin/musl-gcc /usr/bin/musl-gcc \
    && cd / \
    && rm -rf /tmp/musl-1.2.5 \
    && rustup target add x86_64-unknown-linux-musl

# 预装 zig 0.15.2 + cargo-zigbuild
RUN curl -SsLf https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz \
    | tar -xJf - -C /opt \
    && ln -s /opt/zig-x86_64-linux-0.15.2/zig /usr/local/bin/zig \
    && cargo install cargo-zigbuild

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
