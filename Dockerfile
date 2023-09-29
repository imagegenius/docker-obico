FROM nvcr.io/nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as darknet_builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /

RUN \
  apt update && \
  apt install -y \
    ca-certificates \
    build-essential \
    gcc \
    g++ \
    cmake \
    git && \
  git clone https://github.com/AlexeyAB/darknet && \
  cd darknet && \
  git checkout 59c8622 && \
  sed -i 's/LIBSO=0/LIBSO=1/' Makefile && \
  make && \
  mv libdarknet.so libdarknet_cpu.so && \
  cp -R /darknet /darknet-cpu && \ 
  sed -i 's/GPU=0/GPU=1/;s/CUDNN=0/CUDNN=1/;s/CUDNN_HALF=0/CUDNN_HALF=1/' Makefile && \
  make && \
  mv libdarknet.so libdarknet_gpu.so && \
  cp -R /darknet /darknet-gpu

FROM scratch

COPY --from=darknet_builder /darknet-cpu /darknet-cpu
COPY --from=darknet_builder /darknet-gpu /darknet-gpu
