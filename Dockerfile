# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/obico-darknet:latest AS darknet
# runtime
FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

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
  git init /tmp/obico-server && \
  git -C /tmp/obico-server remote add origin https://github.com/TheSpaghettiDetective/obico-server.git && \
  git -C /tmp/obico-server fetch --depth 1 origin "${VERSION}" && \
  git -C /tmp/obico-server checkout FETCH_HEAD && \
  pip3 install \
    onnxruntime-gpu \
    pipenv==2022.12.19 \
    importlib_metadata==8.2.0 \
    opencv_python_headless && \
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
ENV PYTHONPATH="/app/moonraker/moonraker"

# copy local files
COPY root/ /

# add darknet libraries
COPY --from=darknet /darknet-cpu /darknet

# ports and volumes
EXPOSE 3334
VOLUME /config
