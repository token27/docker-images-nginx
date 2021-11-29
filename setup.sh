#!/bin/bash
git update-index --chmod=+x ./build-nginx.sh
git update-index --chmod=+x ./test-nginx.sh
git update-index --chmod=+x ./src/http/nginx/docker-nginx-entrypoint
git update-index --chmod=+x ./src/http/nginx/docker-nginx-location.d-enable
