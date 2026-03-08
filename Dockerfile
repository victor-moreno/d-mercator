# syntax=docker/dockerfile:1

# ---- Stage 1: build ----
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Madrid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        g++ \
        gfortran \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG CMAKE_VERSION=3.23.2
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64)  CMAKE_ARCH="linux-x86_64" ;; \
        aarch64) CMAKE_ARCH="linux-aarch64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.sh" \
        -O /tmp/cmake-install.sh && \
    chmod +x /tmp/cmake-install.sh && \
    /tmp/cmake-install.sh --skip-license --prefix=/usr/local && \
    rm /tmp/cmake-install.sh

COPY . /app
WORKDIR /app
RUN chmod +x ./build.sh && ./build.sh -b Release && strip ./mercator

# ---- Stage 2: runtime ----
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 \
        libgfortran5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/mercator /app/mercator
WORKDIR /app
ENTRYPOINT ["./mercator"]