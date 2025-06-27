# syntax=docker/dockerfile:1.4

# ---------- Stage 1 : RT-SDK base (prebuilt image) ----------
FROM --platform=linux/amd64 docker.io/library/rtsdk-base:local AS rtsdk-base

# ---------- Stage 2 : Build Rust App ----------
FROM --platform=linux/amd64 rust:1.82-bookworm AS rust-builder

# Bring in RT-SDK libraries & headers
COPY --from=rtsdk-base /usr/local /usr/local
COPY --from=rtsdk-base /opt/rtsdk /opt/rtsdk

# Reuse libs from base image to enable offline build
COPY --from=rtsdk-base /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=rtsdk-base /usr/include /usr/include
COPY --from=rtsdk-base /etc/ssl/certs /etc/ssl/certs

# Copy project sources
WORKDIR /usr/src
COPY wrapper ./wrapper
COPY rust-ema ./rust-ema

ENV LIBRARY_PATH=/usr/local/lib \
    LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /usr/src/rust-ema
RUN cargo build --release

# ---------- Stage 3 : Runtime ----------
FROM --platform=linux/amd64 docker.io/library/rtsdk-base:local AS runtime

# Copy built binary only (all required libs already in base image)
COPY --from=rust-builder /usr/src/rust-ema/target/release/rtsdk_consumer /usr/local/bin/rtsdk_consumer

CMD ["rtsdk_consumer"]
