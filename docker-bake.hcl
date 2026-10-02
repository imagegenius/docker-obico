target "docker-metadata-action" {}

variable "APP" {
  default = "obico"
}

variable "VERSION" {
  # renovate: datasource=git-refs depName=obico-server packageName=https://github.com/TheSpaghettiDetective/obico-server currentValue=release
  default = "6f938964c63892df2b6d5b68d99ea783fc1a7c78"
}

variable "DARKNET_VERSION" {
  # Matches obico-server ml_api/Dockerfile.base_amd64
  default = "59c86222c5387bffd9108a21885f80e980ece234"
}

variable "SOURCE" {
  default = "https://github.com/TheSpaghettiDetective/obico-server"
}

group "default" {
  targets = ["image-main-local"]
}

target "image" {
  inherits = ["docker-metadata-action"]
  args = {
    APP             = "${APP}"
    DARKNET_VERSION = "${DARKNET_VERSION}"
    VERSION         = "${VERSION}"
  }
  labels = {
    "org.opencontainers.image.source" = "${SOURCE}"
  }
}

target "image-main" {
  inherits  = ["image"]
  target    = "final-main"
  platforms = ["linux/amd64"]
}

target "image-main-local" {
  inherits  = ["image"]
  target    = "final-main"
  output    = ["type=docker"]
  platforms = ["linux/amd64"]
  tags      = ["${APP}:local-main"]
}

target "image-cuda" {
  inherits  = ["image"]
  target    = "final-cuda"
  platforms = ["linux/amd64"]
}

target "image-cuda-local" {
  inherits  = ["image"]
  target    = "final-cuda"
  output    = ["type=docker"]
  platforms = ["linux/amd64"]
  tags      = ["${APP}:local-cuda"]
}

group "image-all" {
  targets = ["image-main", "image-cuda"]
}
