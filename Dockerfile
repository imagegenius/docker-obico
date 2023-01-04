FROM hydaz/baseimage-ubuntu:latest

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OBICO_VERSION
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydaz"

# environment settings
ENV REDIS_URL="redis://localhost:6379" \
  DATABASE_URL="sqlite:////config/db.sqlite3" \
  INTERNAL_MEDIA_HOST="http://localhost:3334" \
  ML_API_HOST="http://localhost:3333"

# this is a really messy dockerfile but it works
RUN \
  echo "**** install build packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends software-properties-common && \
  add-apt-repository ppa:deadsnakes/ppa && \
  apt-get install -y --no-install-recommends \
    curl \
    gcc \
    git \
    jq \
    libpq-dev \
    python3.7-dev \
    wget && \
  echo "**** install packages ****" && \
  apt-get install -y --no-install-recommends \
    ffmpeg \
    libfontconfig1 \
    libsm6 \
    libxrender1 \
    postgresql \
    python3-pip \
    python3-setuptools \
    python3.7-distutils \
    redis && \
  echo "**** install obico-server ****" && \
  mkdir -p \
    /app/obico && \
  if [ -z ${OBICO_VERSION+x} ]; then \
		OBICO_VERSION=$(curl -sL "https://api.github.com/repos/TheSpaghettiDetective/obico-server/commits?ref=release" | \
			jq -r '.[0].sha' | cut -c1-8); \
  fi && \
  git clone -b release https://github.com/TheSpaghettiDetective/obico-server.git /tmp/obico-server && \
  cd /tmp/obico-server && \
  git checkout ${OBICO_VERSION} && \
  mv \
    /tmp/obico-server/backend \
    /tmp/obico-server/frontend \
    /tmp/obico-server/ml_api \
    /app/obico/ && \
  python3.7 -m pip install \
    -r /app/obico/backend/requirements.txt && \
  python3.7 -m pip install \
    -r /app/obico/ml_api/requirements_x86_64.txt && \
  python3.7 -m pip install packaging && \
  wget --quiet -O /app/obico/ml_api/model/model.weights $(cat /app/obico/ml_api/model/model.weights.url | tr -d '\r') && \
  mkdir -p /app/model && \
  mv /app/obico/ml_api/model/names /app/model/ && \
  echo "**** cleanup ****" && \
  for cleanfiles in *.pyc *.pyo; do \
    find /usr/lib/python3.* -iname "${cleanfiles}" -exec rm -f '{}' + \
    ; done && \
  rm -rf \
    /tmp/* \
    /root/.cache

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 3334
VOLUME /config
