#!/usr/bin/env -S just --justfile

set quiet
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[private]
default:
    just --list

[doc('Build and test locally')]
local-build:
    mkdir -p .cache
    docker buildx bake --no-cache --metadata-file .cache/docker-bake.json --set=*.output=type=docker --load --file docker-bake.hcl image-local
    TEST_IMAGE="$(jq -r '."image-local"."image.name" | sub("^docker.io/library/"; "")' .cache/docker-bake.json)" \
        go test -v ./tests/...

[doc('Trigger a remote build')]
remote-build release="false":
    gh workflow run release.yaml -f release={{ release }}
