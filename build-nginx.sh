#!/bin/bash

set -eEuo pipefail

export DOCKER_BUILDKIT=1

declare -r IMAGE="nginx"

declare -r VERSION_NGINX=$1

# I could create a placeholder like nginx:x.y-alpine in the Dockerfile itself,
# but I think it wouldn't be a good experience if you try to build the image yourself
# thus that's the way I opted to have dynamic base images
declare -r IMAGE_ORIGINAL_TAG="nginx:1.[0-9][0-9]?-alpine"

declare -r IMAGE_TAG="nginx:${VERSION_NGINX}-alpine"
declare -r TOKEN27_TAG_PREFIX="token27/nginx"
declare -r TOKEN27_TAG="${TOKEN27_TAG_PREFIX}:${VERSION_NGINX}"
declare -r TOKEN27_TAG_DEV="${TOKEN27_TAG}-dev"

TAG_FILE="./tmp/build-${IMAGE}.tags"
touch "$TAG_FILE"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "./docker/${IMAGE}.Dockerfile" | docker build --pull -t "${TOKEN27_TAG}" \
  --build-arg=NGINX_VHOST_TEMPLATE=php-fpm --target="http" -f - . &&
  echo "${TOKEN27_TAG}" >>"${TAG_FILE}"

sed -E "s/${IMAGE_ORIGINAL_TAG}/${IMAGE_TAG}/g" "./docker/${IMAGE}.Dockerfile" | docker build --pull -t "${TOKEN27_TAG_DEV}" \
  --build-arg=NGINX_VHOST_TEMPLATE=php-fpm --target="http-dev" -f - . &&
  echo "$TOKEN27_TAG_DEV" >>"${TAG_FILE}"

for IMAGE_EXTRA_TAG in "${@:2}"; do
  declare NEW_TAG="${TOKEN27_TAG_PREFIX}:${IMAGE_EXTRA_TAG}"
  docker tag "${TOKEN27_TAG}" "${NEW_TAG}" && echo "${NEW_TAG}" >>"${TAG_FILE}"
  docker tag "${TOKEN27_TAG_DEV}" "${NEW_TAG}-dev" && echo "${NEW_TAG}-dev" >>"${TAG_FILE}"
done
