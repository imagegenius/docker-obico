# syntax=docker/dockerfile:1

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
  ML_API_HOST="http://localhost:3333"

RUN \
  echo "**** add python3.7 to apt ****" && \
  echo "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >>/etc/apt/sources.list && \
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
    libxrender1 \
    python3-blinker \
    python3-importlib-metadata \
    python3-six \
    python3.7 \
    python3.7-dev \
    python3.7-distutils && \
  curl -s https://bootstrap.pypa.io/get-pip.py | python3.7 && \
  pip install --upgrade \
    packaging \
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
    -r /tmp/obico-server/ml_api/requirements_x86_64.txt && \
  pip install \
    redis==3.2.0 && \
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
    bin \
    lib \
    model \
    auth.py \
    server.py \
    wsgi.py \
    /app/obico/ml_api && \
  mv /tmp/obico-server/frontend \
    /app/obico/frontend && \
  echo "**** configure obico ****" && \
  curl -o \
    /app/obico/ml_api/model/model.weights -L \
    $(cat /app/obico/ml_api/model/model.weights.url | tr -d '\r') && \
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
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /root/.cache

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3334
VOLUME /config
