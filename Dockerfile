# ---------- Stage 1 : Build Refinitiv Real-Time SDK ----------
# syntax=docker/dockerfile:1.4
FROM --platform=linux/amd64 debian:bookworm-slim AS rtsdk-builder

# 必要なビルドツールおよび依存ライブラリをインストール
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git cmake make g++ python3 libssl-dev libxml2-dev libcurl4-openssl-dev zlib1g-dev nlohmann-json3-dev ca-certificates

# --------------------- Build Refinitiv Real-Time SDK ------------------------
WORKDIR /opt
RUN git clone --depth 1 https://github.com/Refinitiv/Real-Time-SDK.git rtsdk && \
    cd rtsdk && \
    cmake -B build \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_UNIT_TESTS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_ETA_APPLICATIONS=OFF \
    -DBUILD_EMA_APPLICATIONS=OFF \
    -DBUILD_ETA_EXAMPLES=OFF \
    -DBUILD_EMA_EXAMPLES=OFF \
    . && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

# ---------- Stage 2 : Build Rust App ----------
FROM --platform=linux/amd64 rust:1.78-bookworm AS rust-builder

# RT-SDK の共有ライブラリを取り込む
COPY --from=rtsdk-builder /usr/local /usr/local
# RT-SDK のヘッダを含むビルドツリーもコピー（cmake --install ではヘッダがインストールされないため）
COPY --from=rtsdk-builder /opt/rtsdk /opt/rtsdk

# Rust アプリのビルドに必要な依存ライブラリをインストール
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git cmake make g++ libssl-dev libxml2-dev libcurl4-openssl-dev zlib1g-dev nlohmann-json3-dev && \
    rm -rf /var/lib/apt/lists/*

# プロジェクト直下にある `wrapper` と Rust クレート `rust-ema` をコピー
WORKDIR /usr/src
COPY wrapper ./wrapper
COPY rust-ema ./rust-ema

# RT-SDK のライブラリをリンクできるようパスを設定
ENV LIBRARY_PATH=/usr/local/lib \
    LD_LIBRARY_PATH=/usr/local/lib

# Rust クレートをビルド
WORKDIR /usr/src/rust-ema
RUN cargo build --release

# ---------- Stage 3 : Runtime ----------
FROM --platform=linux/amd64 ubuntu:22.04

# 実行時に必要な最小限のライブラリのみをインストール
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libcurl4 openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# RT-SDK の共有ライブラリとコンパイル済みバイナリをコピー
COPY --from=rust-builder /usr/local /usr/local
COPY --from=rust-builder /usr/src/rust-ema/target/release/rtsdk_consumer /usr/local/bin/rtsdk_consumer

ENV LD_LIBRARY_PATH=/usr/local/lib
CMD ["rtsdk_consumer"]
