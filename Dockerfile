# syntax=docker/dockerfile:1

FROM nvcr.io/nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 AS darknet-builder

ARG DARKNET_VERSION
ENV DEBIAN_FRONTEND="noninteractive"

WORKDIR /

RUN \
  echo "**** install darknet build packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    g++ \
    gcc \
    git && \
  echo "**** download darknet ****" && \
  git clone https://github.com/AlexeyAB/darknet.git /darknet && \
  git -C /darknet checkout "${DARKNET_VERSION}" && \
  echo "**** build gpu darknet ****" && \
  cd /darknet && \
  sed -i \
    -e 's/GPU=0/GPU=1/' \
    -e 's/CUDNN=0/CUDNN=1/' \
    -e 's/CUDNN_HALF=0/CUDNN_HALF=1/' \
    -e 's/LIBSO=0/LIBSO=1/' \
    -e 's/^ARCH=.*/ARCH= -gencode arch=compute_50,code=[sm_50,compute_50] \\/' \
    -e '/^[[:space:]]*-gencode arch=compute_50/d' \
    Makefile && \
  make -j"$(nproc)" && \
  mv libdarknet.so libdarknet_gpu.so && \
  echo "**** build cpu darknet ****" && \
  sed -i \
    -e 's/GPU=1/GPU=0/' \
    -e 's/CUDNN=1/CUDNN=0/' \
    -e 's/CUDNN_HALF=1/CUDNN_HALF=0/' \
    Makefile && \
  make -j"$(nproc)" && \
  mv libdarknet.so libdarknet_cpu.so && \
  cp -a /darknet /darknet-gpu && \
  cp -a /darknet /darknet-cpu && \
  rm -f /darknet-cpu/libdarknet_gpu.so

FROM scratch AS darknet

COPY --from=darknet-builder /darknet-cpu /darknet-cpu
COPY --from=darknet-builder /darknet-gpu /darknet-gpu

FROM ghcr.io/linuxserver/baseimage-ubuntu:noble AS obico-base

# set version label
ARG VERSION
LABEL maintainer="hydazz"
LABEL org.opencontainers.image.authors="hydazz"

# environment settings
ENV DEBIAN_FRONTEND="noninteractive" \
  DATABASE_URL="sqlite:////config/db.sqlite3" \
  INTERNAL_MEDIA_HOST="http://localhost:3334" \
  ML_API_HOST="http://localhost:3333" \
  MOONRAKER_COMMIT="f735c0419444848b59342a98ad3532eef123ea46"

RUN \
  echo "**** install repo setup packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg && \
  echo "**** add python3.10 to apt ****" && \
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys f23c5a6cf475977595c89f51ba6932366a755776 && \
  gpg --batch --export f23c5a6cf475977595c89f51ba6932366a755776 > /usr/share/keyrings/deadsnakes.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" > /etc/apt/sources.list.d/python.list && \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    gcc \
    git \
    libfontconfig1 \
    libpq-dev \
    libsm6 \
    libxrender1 \
    postgresql \
    python3.10 \
    python3.10-dev \
    python3.10-distutils && \
  curl -s https://bootstrap.pypa.io/get-pip.py | python3.10 && \
  python3.10 -m pip install --upgrade \
    packaging \
    pip \
    setuptools \
    wheel && \
  echo "**** install obico ****" && \
  git init /tmp/obico-server && \
  git -C /tmp/obico-server remote add origin https://github.com/TheSpaghettiDetective/obico-server.git && \
  git -C /tmp/obico-server fetch --depth 1 origin "${VERSION}" && \
  git -C /tmp/obico-server checkout FETCH_HEAD && \
  python3.10 -m pip install \
    importlib_metadata==8.2.0 \
    onnxruntime-gpu \
    opencv_python_headless \
    pipenv==2022.12.19 && \
  python3.10 -m pip install -r /tmp/obico-server/ml_api/requirements.txt && \
  python3.10 -m pip install -r /tmp/obico-server/backend/requirements.txt && \
  echo "**** install moonraker ****" && \
  git clone https://github.com/Arksine/moonraker.git /app/moonraker && \
  git -C /app/moonraker checkout ${MOONRAKER_COMMIT} && \
  echo "**** move files into place ****" && \
  mkdir -p /app/obico && \
  mv /tmp/obico-server/backend \
    /app/obico/backend && \
  mv /tmp/obico-server/ml_api \
    /app/obico/ml_api && \
  mv /tmp/obico-server/frontend \
    /app/obico/frontend && \
  echo "**** configure obico ****" && \
  mkdir -p \
    /app/model \
    /app/obico/backend/static_build/ \
    /model_cache/ml_api/darknet \
    /model_cache/ml_api/onnx && \
  curl -o \
    /model_cache/ml_api/darknet/model-weights.darknet -L \
    $(cat /app/obico/ml_api/model/model-weights.darknet.url | tr -d '\r') && \
  curl -o \
    /model_cache/ml_api/onnx/model-weights.onnx -L \
    $(cat /app/obico/ml_api/model/model-weights.onnx.url | tr -d '\r') && \
  mv /app/obico/ml_api/model/names /app/model/ && \
  ln -s \
    /config/media \
    /app/obico/backend/static_build/media && \
  echo "**** cleanup ****" && \
  for cleanfiles in *.pyc *.pyo; do \
    find /usr/local/lib/python3.* /usr/lib/python3.* -name "${cleanfiles}" -delete; \
  done && \
  apt-get remove -y --purge \
    curl \
    gcc \
    gnupg \
    libpq-dev \
    python3.10-dev && \
  apt-get autoremove -y --purge && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

# environment settings
ENV PYTHONPATH="/app/moonraker"

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3334
VOLUME /config

FROM obico-base AS final-main

COPY --from=darknet /darknet-cpu /darknet

FROM obico-base AS final-cuda

RUN \
  echo "**** install cuda runtime packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    nvidia-cuda-toolkit && \
  curl -o \
    /tmp/libcudnn.deb -L \
    https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/libcudnn9-cuda-11_9.3.0.75-1_amd64.deb && \
  dpkg -i /tmp/libcudnn.deb && \
  apt-get remove -y --purge \
    curl && \
  apt-get autoremove -y --purge && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

COPY --from=darknet /darknet-gpu /darknet
