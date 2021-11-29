#!/bin/bash
set -eEuo pipefail

# The first parameter is a Docker tag or image id
declare -r DOCKER_FPM_TAG="$1"
declare -r DOCKER_NGINX_TAG="$2"

declare -r TEST_SUITE="nginx or nginx_fpm_functional"

printf "Starting a container for '%s'\\n" "$DOCKER_FPM_TAG"

DOCKER_FPM_CONTAINER=$(docker run --rm -t -v "$PWD/test/functional/web:/var/www/html" -d "$DOCKER_FPM_TAG")
readonly DOCKER_FPM_CONTAINER

printf "Starting a container for '%s'\\n" "$DOCKER_NGINX_TAG"

DOCKER_NGINX_CONTAINER=$(docker run --rm -t -v "$PWD/test/functional/web:/var/www/html" --volumes-from="$DOCKER_FPM_CONTAINER" -d "$DOCKER_NGINX_TAG")
readonly DOCKER_NGINX_CONTAINER

# Let's register a trap function, if our tests fail, finish or the script gets
# interrupted, we'll still be able to remove the running container
function tearDown() {
  docker rm -f "$DOCKER_NGINX_CONTAINER" "$DOCKER_FPM_CONTAINER" &>/dev/null &
}
trap tearDown EXIT TERM ERR

# Finally, run the tests!
docker run --rm -t \
  -v "$(pwd)/test:/tests" \
  -v "$(pwd)/tmp/test-results:/results" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  renatomefi/docker-testinfra:5 \
  -m "$TEST_SUITE" --junitxml="/results/nginx-$DOCKER_NGINX_TAG.xml" \
  --verbose --hosts="docker://$DOCKER_NGINX_CONTAINER"
