# syntax=docker/dockerfile:1

FROM nvcr.io/nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as darknet_builder

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt update && \
  apt install -y \
    ca-certificates \
    build-essential \
    gcc \
    g++ \
    cmake \
    git && \
  cd / && \
  git clone https://github.com/AlexeyAB/darknet && \
  cd darknet && \
  git checkout 59c8622 && \
  sed -i 's/GPU=0/GPU=1/;s/CUDNN=0/CUDNN=1/;s/CUDNN_HALF=0/CUDNN_HALF=1/;s/LIBSO=0/LIBSO=1/' Makefile && \
  make -j 4 && \
  mv libdarknet.so libdarknet_gpu.so && \
  sed -i 's/GPU=1/GPU=0/;s/CUDNN=1/CUDNN=0/;s/CUDNN_HALF=1/CUDNN_HALF=0/' Makefile && \
  make -j 4 && \
  mv libdarknet.so libdarknet_cpu.so

FROM ghcr.io/imagegenius/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OBICO_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV DEBIAN_FRONTEND="noninteractive" \
  DATABASE_URL="sqlite:////config/db.sqlite3" \
  INTERNAL_MEDIA_HOST="http://localhost:3334" \
  ML_API_HOST="http://localhost:3333" \
  MOONRAKER_COMMIT="1e7be45"

RUN \
  echo "**** add python3.7 to apt ****" && \
  echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >>/etc/apt/sources.list.d/python.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys f23c5a6cf475977595c89f51ba6932366a755776 && \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    gcc \
    git \
    libfontconfig1 \
    nvidia-cuda-toolkit \
    libpq-dev \
    libsm6 \
    libxrender1 \
    nvidia-cuda-toolkit \
    python3.7 \
    python3.7-dev \
    python3.7-distutils && \
  curl -o \
    /tmp/libcudnn.deb -L \
    https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libcudnn8_8.2.4.15-1+cuda11.4_amd64.deb && \
  dpkg -i /tmp/libcudnn.deb && \
  curl -s https://bootstrap.pypa.io/get-pip.py | python3.7 && \
  pip install --upgrade \
    packaging \
    pip \
    setuptools \
    wheel && \
  echo "**** install obico ****" && \
  mkdir -p \
    /app/obico && \
  if [ -z ${OBICO_VERSION+x} ]; then \
    OBICO_VERSION=$(curl -sL "https://api.github.com/repos/TheSpaghettiDetective/obico-server/commits?ref=release" | jq -r '.[0].sha' | cut -c1-8); \
  fi && \
  git clone -b release https://github.com/TheSpaghettiDetective/obico-server.git /tmp/obico-server && \
  cd /tmp/obico-server && \
  git checkout ${OBICO_VERSION} && \
  pip install \
    -r /tmp/obico-server/backend/requirements.txt && \
  pip install \
    -r /tmp/obico-server/ml_api/requirements.txt && \
  pip install \
    blinker \
    importlib-metadata==4.13.0 \
    inotify-simple==1.3.5 \
    onnxruntime-gpu \
    opencv_python_headless \
    redis==3.2.0 \
    six \
    tornado==6.2.0 && \
  echo "**** install moonraker ****" && \
  git clone https://github.com/Arksine/moonraker.git /app/moonraker && \
  cd /app/moonraker && \
  git checkout ${MOONRAKER_COMMIT} && \
  echo "**** move files into place ****" && \
  mkdir -p \
    /app/obico/backend \
    /app/obico/ml_api && \
  cd /tmp/obico-server/backend && \
  cp -a \
    api \
    app \
    config \
    lib \
    manage.py \
    notifications \
    /app/obico/backend && \
  cd /tmp/obico-server/ml_api && \
  cp -a \
    lib \
    model \
    auth.py \
    detect.py \
    server.py \
    wsgi.py \
    /app/obico/ml_api && \
  mv /tmp/obico-server/frontend \
    /app/obico/frontend && \
  echo "**** configure obico ****" && \
  for weight in onnx darknet; do \
    curl -o \
      /app/obico/ml_api/model/model-weights.${weight} -L \
      $(cat /app/obico/ml_api/model/model-weights.${weight}.url | tr -d '\r'); \
  done && \
  mkdir -p \
    /app/model \
    /app/obico/backend/static_build/ && \
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
    git \
    libpq-dev \
    python3.7-dev && \
  apt-get autoremove -y --purge && \
  apt-get clean && \
  rm -rf \
    /etc/apt/sources.list.d/python.list \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

# environment settings
ENV PYTHONPATH="${PYTHONPATH}:/app/moonraker/moonraker"

# copy local files
COPY root/ /
COPY --from=darknet_builder /darknet /darknet

# ports and volumes
EXPOSE 3334
VOLUME /config
