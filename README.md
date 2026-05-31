# [imagegenius/obico](https://github.com/imagegenius/docker-obico)

[![GitHub Release](https://img.shields.io/github/release/imagegenius/docker-obico.svg?color=007EC6&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/imagegenius/docker-obico/releases)
[![GitHub Package Repository](https://shields.io/badge/GitHub%20Package-blue?logo=github&logoColor=ffffff&style=for-the-badge)](https://github.com/imagegenius/docker-obico/packages)

Obico is a community-built, open-source smart 3D printing platform used by makers, enthusiasts, and tinkerers around the world.

[![obico](https://www.obico.io/wwwimg/logo.svg)](https://www.obico.io/)

## Variants

| Tag      | Description                                      | Platforms |
| -------- | ------------------------------------------------ | --------- |
| `latest` | Ubuntu + Obico server, ML API, and CPU Darknet   | amd64     |
| `cuda`   | `latest` plus NVIDIA CUDA runtime and GPU Darknet | amd64     |

Obico Server does not publish semver releases. This image pins the upstream `release` branch commit in `docker-bake.hcl`.

### NVIDIA GPU Acceleration

Use the `cuda` tag with the NVIDIA Container Toolkit and pass through the GPU.

```yaml
services:
  obico:
    image: ghcr.io/imagegenius/obico:cuda
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              capabilities: [gpu]
```

## Requirements

- **Redis**: External or via docker mod (see below).
- **HOST_IP**: Set this to the host, IP:port, or DNS name used to access Obico.

### Docker Mod for Redis

- Set `DOCKER_MODS=imagegenius/mods:universal-redis`
- Set `REDIS_URL=redis://localhost:6379`

## Usage

### Docker Compose

```yaml
---
services:
  obico:
    image: ghcr.io/imagegenius/obico:latest
    container_name: obico
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - REDIS_URL=redis://192.168.1.x:6379
      - HOST_IP=192.168.1.x:3334
    volumes:
      - path_to_appdata:/config
    ports:
      - 3334:3334
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - 6379:6379
```

## Parameters

| Parameter                         | Function                                                                                     |
| --------------------------------- | -------------------------------------------------------------------------------------------- |
| `-p 3334`                         | WebUI port                                                                                   |
| `-e PUID=1000`                    | UID for permissions — see below                                                              |
| `-e PGID=1000`                    | GID for permissions — see below                                                              |
| `-e TZ=Etc/UTC`                   | Timezone, see [this list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) |
| `-e REDIS_URL=redis://<ip>:6379`  | Redis URL                                                                                    |
| `-e HOST_IP=192.168.1.x:3334`     | Host, IP:port, or DNS name used to access Obico                                              |
| `-v /config`                      | Django database, logs, media, and timelapses                                                 |
| `DOCKER_MODS=imagegenius/mods:...` | Optional Redis docker mod                                                                    |

## Application Setup

After first start, configure the Django site domain so static assets and links resolve correctly. Follow Obico's [server configuration guide](https://www.obico.io/docs/server-guides/configure/#login-as-django-admin), especially "Login as Django admin" and "Configure Django site".

## User / Group IDs & umask

Set `PUID=1000` `PGID=1000` to match volume ownership on the host (`id user` to find yours). Optionally `UMASK=022` (works subtractively, not additively).

## Updating

```bash
docker pull ghcr.io/imagegenius/obico:latest
docker stop obico && docker rm obico
# recreate with the same docker run parameters
docker image prune  # optional: remove dangling images
```

Or with compose: `docker compose pull && docker compose up -d`.

## Support

- Issues: <https://github.com/imagegenius/docker-obico/issues>
- Obico: <https://www.obico.io/>

## How this image is built

This repo is built with GitHub Actions, based on the workflow shape from [home-operations/containers](https://github.com/home-operations/containers).

- The container starts from [linuxserver/docker-baseimage-ubuntu](https://github.com/linuxserver/docker-baseimage-ubuntu).
- Obico Server is fetched from the upstream `release` branch commit pinned in [`docker-bake.hcl`](docker-bake.hcl).
- Darknet is built from the same upstream-pinned AlexeyAB commit used by Obico's current ML base image.
- The backend, ML API, frontend, Moonraker, model weights, Darknet libraries, and s6 services are assembled in this Dockerfile.
- `latest` and `cuda` are Dockerfile targets, not separate branches.
- s6-overlay bits live under [`root/`](root).
- Renovate tracks the upstream Obico commit from the bake annotations.
