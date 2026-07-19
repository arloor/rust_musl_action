FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

ARG MUSL_VERSION=1.2.5
ARG ZIG_VERSION=0.15.2

# 基础工具 + musl/zig 构建依赖一并装好
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gcc \
    libc6-dev \
    make \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 预装 Rust stable
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- --default-host x86_64-unknown-linux-gnu -y \
    && . "$HOME/.cargo/env" \
    && rustup default stable \
    && rustc --version
ENV PATH="/root/.cargo/bin:${PATH}"

# 预装 zig + cargo-zigbuild
RUN curl -SsLf "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" \
    | tar -xJf - -C /opt \
    && ln -s "/opt/zig-x86_64-linux-${ZIG_VERSION}/zig" /usr/local/bin/zig \
    && cargo install cargo-zigbuild

# 预编译 musl（默认版本）
RUN curl -SsLf "https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz" | tar -xz -C /tmp \
    && cd "/tmp/musl-${MUSL_VERSION}" \
    && ./configure >/dev/null \
    && make -j"$(nproc)" >/dev/null \
    && make install >/dev/null \
    && ln -fs /usr/local/musl/bin/musl-gcc /usr/bin/musl-gcc \
    && echo "${MUSL_VERSION}" > /usr/local/musl/.musl-version \
    && cd / \
    && rm -rf "/tmp/musl-${MUSL_VERSION}" \
    && rustup target add x86_64-unknown-linux-musl

COPY entrypoint.sh /
ENTRYPOINT ["bash", "/entrypoint.sh"]
