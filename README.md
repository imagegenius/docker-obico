<!-- DO NOT EDIT THIS FILE MANUALLY  -->

# [imagegenius/obico](https://github.com/imagegenius/docker-obico)

[![GitHub Release](https://img.shields.io/github/release/imagegenius/docker-obico.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/imagegenius/docker-obico/releases)
[![GitHub Package Repository](https://img.shields.io/static/v1.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=imagegenius.io&message=GitHub%20Package&logo=github)](https://github.com/imagegenius/docker-obico/packages)
![Image Size](https://img.shields.io/docker/image-size/imagegenius/obico.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=docker)
[![Jenkins Build](https://img.shields.io/jenkins/build?labelColor=555555&logoColor=ffffff&style=for-the-badge&jobUrl=https%3A%2F%2Fci.imagegenius.io%2Fjob%2FDocker-Pipeline-Builders%2Fjob%2Fdocker-obico%2Fjob%2Fmain%2F&logo=jenkins)](https://ci.imagegenius.io/job/Docker-Pipeline-Builders/job/docker-obico/job/main/)
[![IG CI](https://img.shields.io/badge/dynamic/yaml?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=CI&query=CI&url=https%3A%2F%2Fci-tests.imagegenius.io%2Fimagegenius%2Fobico%2Flatest%2Fci-status.yml)](https://ci-tests.imagegenius.io/imagegenius/obico/latest/index.html)

[Obico](https://www.obico.io/) - Community-built, open-source smart 3D printing platform used by makers, enthusiasts, and tinkerers around the world.

[![obico](https://www.obico.io/wwwimg/logo.svg)](https://www.obico.io/)

## Supported Architectures

We utilise the docker manifest for multi-platform awareness. More information is available from docker [here](https://github.com/docker/distribution/blob/master/docs/spec/manifest-v2-2.md#manifest-list).

Simply pulling `ghcr.io/imagegenius/obico:latest` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

The architectures supported by this image are:

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| x86-64 | ✅ | amd64-\<version tag\> |
| arm64 | ❌ | |

## Application Setup

Please report any issues with the container [here](https://github.com/imagegenius/docker-obico/issues)!

The webui is at `<your ip>:3334`.

**After starting the container, it is important to configure obico-server (Django) to ensure that all assets are properly loaded. Follow steps 1-2 under 'Login as Django admin' and 'Configure Django site' in the [Obico Server Configuration](https://www.obico.io/docs/server-guides/configure/#login-as-django-admin) guide closely. These steps will guide you through setting up login credentials and configuring the domain name to match the IP used to access the container, or your FQDN if using a reverse proxy.**

You can also use environment variables to set various configurations, such as email settings. A list of available environment variables can be found [here](https://github.com/TheSpaghettiDetective/obico-server/blob/release/docker-compose.yml#L13-L40).

Note: Some assets, such as the database (obico configuration) and media files (such as timelapses), are mounted to `/config` and will persist through container recreation. I am still working on identifying all assets that require persistence."

Obico do not publish versioning for obico-server, so we use the latest commit hash to identify the current version.

## Usage

Here are some example snippets to help you get started creating a container.

### docker-compose

```yaml
---
version: "2.1"
services:
  obico:
    image: ghcr.io/imagegenius/obico:latest
    container_name: obico
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - path_to_data:/config
    ports:
      - 3334:3334
    restart: unless-stopped
```

### docker cli ([click here for more info](https://docs.docker.com/engine/reference/commandline/cli/))

```bash
docker run -d \
  --name=obico \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -p 3334:3334 \
  -v path_to_data:/config \
  --restart unless-stopped \
  ghcr.io/imagegenius/obico:latest
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 3334` | WebUI Port |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use eg. Europe/London. |
| `-v /config` | Contains django database, logs and timelapses |

## Environment variables from files (Docker secrets)

You can set any environment variable from a file by using a special prepend `FILE__`.

As an example:

```bash
-e FILE__PASSWORD=/run/secrets/mysecretpassword
```

Will set the environment variable `PASSWORD` based on the contents of the `/run/secrets/mysecretpassword` file.

## Umask for running applications

For all of our images we provide the ability to override the default umask settings for services started within the containers using the optional `-e UMASK=022` setting.
Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add. Please read up [here](https://en.wikipedia.org/wiki/Umask) before asking for support.

## User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```bash
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```

## Support Info

* Shell access whilst the container is running: `docker exec -it obico /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f obico`
* container version number
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' obico`
* image version number
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' ghcr.io/imagegenius/obico:latest`

## Updating Info

Most of our images are static, versioned, and require an image update and container recreation to update the app inside. With some exceptions (ie. nextcloud, plex), we do not recommend or support updating apps inside the container. Please consult the [Application Setup](#application-setup) section above to see if it is recommended for the image.

Below are the instructions for updating containers:

### Via Docker Compose

* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull obico`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d obico`
* You can also remove the old dangling images: `docker image prune`

### Via Docker Run

* Update the image: `docker pull ghcr.io/imagegenius/obico:latest`
* Stop the running container: `docker stop obico`
* Delete the container: `docker rm obico`
* Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* You can also remove the old dangling images: `docker image prune`

## Building locally

If you want to make local modifications to these images for development purposes or just to customize the logic:

```bash
git clone https://github.com/imagegenius/docker-obico.git
cd docker-obico
docker build \
  --no-cache \
  --pull \
  -t ghcr.io/imagegenius/obico:latest .
```

The ARM variants can be built on x86_64 hardware using `multiarch/qemu-user-static`

```bash
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Once registered you can define the dockerfile to use with `-f Dockerfile.aarch64`.

## Versions

* **1.14.23:** - Update to s6v3
* **1.05.23:** - Initial Working Release.
* **1.04.23:** - Initial Release.
