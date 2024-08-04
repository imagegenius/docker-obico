# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/obico-darknet:latest as darknet
# runtime
FROM ghcr.io/imagegenius/baseimage-ubuntu:noble

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
  MOONRAKER_COMMIT="55e852cd8792c9d158b8b5647bec530cbee1f43a"

RUN \
  echo "**** add python3.10 to apt ****" && \
  echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" >>/etc/apt/sources.list.d/python.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys f23c5a6cf475977595c89f51ba6932366a755776 && \
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
    postgresql \
    libxrender1 \
    python3.10 \
    python3.10-dev \
    python3.10-distutils && \
  curl -s https://bootstrap.pypa.io/get-pip.py | python3.10 && \
  pip3 install --upgrade \
    packaging \
    pip \
    setuptools \
    wheel && \
  echo "**** install obico ****" && \
  if [ -z ${OBICO_VERSION+x} ]; then \
    OBICO_VERSION=$(curl -sL "https://api.github.com/repos/TheSpaghettiDetective/obico-server/commits?ref=release" | jq -r '.[0].sha' | cut -c1-8); \
  fi && \
  git clone -b release https://github.com/TheSpaghettiDetective/obico-server.git /tmp/obico-server && \
  git -C /tmp/obico-server  checkout ${OBICO_VERSION} && \
  pip3 install \
    blinker \
    importlib-metadata==4.13.0 \
    inotify-simple==1.3.5 \
    onnxruntime-gpu \
    opencv_python_headless \
    six \
    tornado==6.2.0 && \
  pip3 install -r /tmp/obico-server/ml_api/requirements.txt && \
  pip3 install -r /tmp/obico-server/backend/requirements.txt && \
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
ENV PYTHONPATH="/app/moonraker/moonraker"

# copy local files
COPY root/ /

# add darknet libraries
COPY --from=darknet /darknet-cpu /darknet

# ports and volumes
EXPOSE 3334
VOLUME /config
