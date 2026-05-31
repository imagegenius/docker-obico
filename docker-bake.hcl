target "docker-metadata-action" {}

variable "APP" {
  default = "obico"
}

variable "BASE_IMAGE" {
  # renovate: datasource=docker depName=ghcr.io/linuxserver/baseimage-ubuntu versioning=docker
  default = "ghcr.io/linuxserver/baseimage-ubuntu:noble@sha256:b8812cb84999bcee029fcabe935f28f1edfeee6d5754b1f64446d07d6e9117d1"
}

variable "VERSION" {
  # renovate: datasource=git-refs depName=obico-server packageName=https://github.com/TheSpaghettiDetective/obico-server currentValue=release
  default = "9b73caa7b373e89fd23bf2fed646e629ee602640"
}

variable "SOURCE" {
  default = "https://github.com/TheSpaghettiDetective/obico-server"
}

group "default" {
  targets = ["image-local"]
}

target "image-base" {
  inherits = ["docker-metadata-action"]
  args = {
    APP        = "${APP}"
    BASE_IMAGE = "${BASE_IMAGE}"
    VERSION    = "${VERSION}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image" {
  inherits  = ["image-base"]
  platforms = ["linux/amd64"]
}

target "image-local" {
  inherits  = ["image-base"]
  output    = ["type=docker"]
  platforms = ["linux/amd64"]
  tags      = ["${APP}:local"]
}
