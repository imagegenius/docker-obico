<!-- DO NOT EDIT THIS FILE MANUALLY -->
<!-- Please read https://github.com/imagegenius/docker-obico/blob/cuda/.github/CONTRIBUTING.md -->

# [imagegenius/obico](https://github.com/imagegenius/docker-obico)

[![GitHub Release](https://img.shields.io/github/release/imagegenius/docker-obico.svg?color=007EC6&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/imagegenius/docker-obico/releases)
[![GitHub Package Repository](https://shields.io/badge/GitHub%20Package-blue?logo=github&logoColor=ffffff&style=for-the-badge)](https://github.com/imagegenius/docker-obico/packages)
[![Jenkins Build](https://img.shields.io/jenkins/build?labelColor=555555&logoColor=ffffff&style=for-the-badge&jobUrl=https%3A%2F%2Fci.imagegenius.io%2Fjob%2FDocker-Pipeline-Builders%2Fjob%2Fdocker-obico%2Fjob%2Fcuda%2F&logo=jenkins)](https://ci.imagegenius.io/job/Docker-Pipeline-Builders/job/docker-obico/job/cuda/)

Obico is a community-built, open-source smart 3D printing platform used by makers, enthusiasts, and tinkerers around the world.

[![obico](https://www.obico.io/wwwimg/logo.svg)](https://www.obico.io/)

## Supported Architectures

We use Docker manifest for cross-platform compatibility. More details can be found on [Docker's website](https://distribution.github.io/distribution/spec/manifest-v2-2/#manifest-list).

To obtain the appropriate image for your architecture, simply pull `ghcr.io/imagegenius/obico:cuda`. Alternatively, you can also obtain specific architecture images by using tags.

This image supports the following architectures:

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| x86-64 | ✅ | amd64-\<version tag\> |
| arm64 | ❌ | |
| armhf | ❌ | |

## Version Tags

This image offers different versions via tags. Be cautious when using unstable or development tags, and read their descriptions carefully.

| Tag | Available | Description |
| :----: | :----: |--- |
| latest | ✅ | Latest obico-server release, only supports CPU for machine learning. |
| cuda | ✅ | Latest obico-server release with support for GPU (CUDA) acceleration. |

## Application Setup

The WebUI can be found at `http://your-ip:3334`.

**After starting the container, it is important to configure obico-server (Django) to ensure that all assets are properly loaded. 

Follow steps 1-2 under 'Login as Django admin' and 'Configure Django site' in the [Obico Server Configuration](https://www.obico.io/docs/server-guides/configure/#login-as-django-admin) guide closely. These steps will guide you through setting up login credentials and configuring the domain name to match the IP used to access the container, or your FQDN if using a reverse proxy.

You can also use environment variables to set various configurations, such as email settings. A list of available environment variables can be found [here](https://github.com/TheSpaghettiDetective/obico-server/blob/release/docker-compose.yml#L13-L40).

Obico requires that you have Redis setup externally.

Follow these steps if you need help setting up Redis.

#### Redis:

Redis can be ran within the container using a docker-mod or you can use an external Redis server/container.

If you don't need to use Redis elsewhere add this environment variable: `DOCKER_MODS=imagegenius/mods:universal-redis`, and set `REDIS_URL` to `redis://localhost:6379`.

Or within a seperate container:

```bash
docker run -d \
  --name=redis \
  -p 6379:6379 \
  redis
```

## Enabling GPU Acceleration with this container

To start this image with GPU support, you need to modify your Docker settings.

If you're using the Docker CLI, add the `--gpus=all` flag to your command.

```sh
docker run --gpus=all ...
```

If you're using Docker Compose, add the following under your service:

```yaml
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              capabilities: [gpu]
```

This will reserve all available GPUs for your container, using the NVIDIA driver.

Obico do not publish versioning for obico-server, so we use the latest commit hash to identify the current version.

## Usage

Example snippets to start creating a container:

### Docker Compose

```yaml
---
services:
  obico:
    image: ghcr.io/imagegenius/obico:cuda
    container_name: obico
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - REDIS_URL=redis://<ip>:<port>
      - HOST_IP=192.168.0.5/example.com
    volumes:
      - path_to_appdata:/config
    ports:
      - 3334:3334
    restart: unless-stopped
```

### Docker CLI ([Click here for more info](https://docs.docker.com/engine/reference/commandline/cli/))

```bash
docker run -d \
  --name=obico \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e REDIS_URL=redis://<ip>:<port> \
  -e HOST_IP=192.168.0.5/example.com \
  -p 3334:3334 \
  -v path_to_appdata:/config \
  --restart unless-stopped \
  ghcr.io/imagegenius/obico:cuda
```

## Parameters

To configure the container, pass variables at runtime using the format `<external>:<internal>`. For instance, `-p 8080:80` exposes port `80` inside the container, making it accessible outside the container via the host's IP on port `8080`.

| Parameter | Function |
| :----: | --- |
| `-p 3334` | WebUI Port |
| `-e PUID=1000` | UID for permissions - see below for explanation |
| `-e PGID=1000` | GID for permissions - see below for explanation |
| `-e TZ=Etc/UTC` | Specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). |
| `-e REDIS_URL=redis://<ip>:<port>` | Redis URL, eg. `redis://192.168.1.2:6379` |
| `-e HOST_IP=192.168.0.5/example.com` | Domain/IP used to access the frontend |
| `-v /config` | Contains django database, logs and timelapses |

## Umask for running applications

All of our images allow overriding the default umask setting for services started within the containers using the optional -e UMASK=022 option. Note that umask works differently than chmod and subtracts permissions based on its value, not adding. For more information, please refer to the Wikipedia article on umask [here](https://en.wikipedia.org/wiki/Umask).

## User / Group Identifiers

To avoid permissions issues when using volumes (`-v` flags) between the host OS and the container, you can specify the user (`PUID`) and group (`PGID`). Make sure that the volume directories on the host are owned by the same user you specify, and the issues will disappear.

Example: `PUID=1000` and `PGID=1000`. To find your PUID and PGID, run `id user`.

```bash
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```


## Updating the Container

Most of our images are static, versioned, and require an image update and container recreation to update the app. We do not recommend or support updating apps inside the container. Check the [Application Setup](#application-setup) section for recommendations for the specific image.

Instructions for updating containers:

### Via Docker Compose

* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull obico`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d obico`
* You can also remove the old dangling images: `docker image prune`

### Via Docker Run

* Update the image: `docker pull ghcr.io/imagegenius/obico:cuda`
* Stop the running container: `docker stop obico`
* Delete the container: `docker rm obico`
* Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* You can also remove the old dangling images: `docker image prune`

## Versions

* **29.09.23:** - precompile darknet
* **23.03.23:** - add service checks
* **05.03.23:** - rollback moonraker (breaking upstream update)
* **23.01.23:** - BREAKING: removed redis
* **14.01.23:** - Update to s6v3
* **05.01.23:** - Initial Working Release.
* **04.01.23:** - Initial Release.
