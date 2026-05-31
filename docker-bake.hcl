target "docker-metadata-action" {}

variable "APP" {
  default = "obico"
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
    APP     = "${APP}"
    VERSION = "${VERSION}"
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
