# syntax=docker/dockerfile:1.4

# ---------- Stage 1 : RT-SDK base (prebuilt image) ----------
FROM --platform=linux/amd64 ghcr.io/tk42/rtsdk-base:latest AS rtsdk-base

# ---------- Stage 2 : Build Rust App ----------
FROM --platform=linux/amd64 rust:1.82-bookworm AS rust-builder

# Bring in RT-SDK libraries & headers
COPY --from=rtsdk-base /usr/local /usr/local
COPY --from=rtsdk-base /opt/rtsdk /opt/rtsdk

# Extra deps for cargo build
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git cmake make g++ libssl-dev libxml2-dev libcurl4-openssl-dev zlib1g-dev nlohmann-json3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy project sources
WORKDIR /usr/src
COPY wrapper ./wrapper
COPY rust-ema ./rust-ema

ENV LIBRARY_PATH=/usr/local/lib \
    LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /usr/src/rust-ema
RUN cargo build --release

# ---------- Stage 3 : Runtime ----------
FROM --platform=linux/amd64 ubuntu:22.04 AS runtime

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libcurl4 openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy RT-SDK libs & built binary
COPY --from=rtsdk-base /usr/local /usr/local
COPY --from=rust-builder /usr/src/rust-ema/target/release/rtsdk_consumer /usr/local/bin/rtsdk_consumer

ENV LD_LIBRARY_PATH=/usr/local/lib
CMD ["rtsdk_consumer"]
