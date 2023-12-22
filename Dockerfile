# Set the base image to use for subsequent instructions
FROM ubuntu:latest
# Copy any source file(s) required for the action
COPY entrypoint.sh /
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-host x86_64-unknown-linux-gnu -y; \
    . $HOME/.cargo/env; \
    wget http://musl.libc.org/releases/musl-1.2.3.tar.gz -O musl-1.2.3.tar.gz; \
    apt install -y gcc make; \
    tar -zxvf musl-1.2.3.tar.gz; \
    cd musl-1.2.3; \
    ./configure; \
    make -j 2; \
    make install; \
    ln -fs /usr/local/musl/bin/musl-gcc /usr/local/bin/musl-gcc; \
    rustup target add x86_64-unknown-linux-musl; 
# Configure the container to be run as an executable
ENTRYPOINT ["/entrypoint.sh"]
