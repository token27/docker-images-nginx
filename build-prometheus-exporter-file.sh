#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE="prometheus-exporter-file"

declare -r DOCKER_FILE="nginx"

declare -r VERSION_NGINX=$1

# I could create a placeholder like nginx:x.y-alpine in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="nginx:1.[0-9][0-9]?-alpine"

declare -r IMAGE_TAG="nginx:${VERSION_NGINX}-alpine"
declare -r TOKEN27_TAG_PREFIX="token27/nginx"
declare -r TOKEN27_TAG="${TOKEN27_TAG_PREFIX}:${IMAGE}"

TAG_FILE="./tmp/build-${IMAGE}.tags"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "./docker/${DOCKER_FILE}.Dockerfile" | docker build --pull -t "${TOKEN27_TAG}" \
  --build-arg=NGINX_VHOST_TEMPLATE=prometheus-exporter-file --target="http-dev" -f - . &&
  echo "${TOKEN27_TAG}" >>"${TAG_FILE}"

for TOKEN27_TAG_EXTRA in "${@:2}"; do
  docker tag "${TOKEN27_TAG}" "${TOKEN27_TAG_PREFIX}:${TOKEN27_TAG_EXTRA}" &&
    echo "${TOKEN27_TAG_PREFIX}:${TOKEN27_TAG_EXTRA}" >>"${TAG_FILE}"
done
