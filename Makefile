qa: lint lint-shell build test scan-vulnerability
build: clean-tags build-nginx
push: build push-nginx
ci-push-nginx: ci-docker-login push-nginx

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(abspath $(patsubst %/,%,$(dir $(mkfile_path))))

.PHONY: *

BUILDINGIMAGE=*

#############################################################################################
# Docker HTTP images build matrix ./build-nginx.sh (nginx version) (extra tag)
#############################################################################################
build-nginx: BUILDINGIMAGE=nginx
build-nginx: clean-tags
	./build-nginx.sh 1.21.4 latest
	./build-nginx.sh 1.19
	./build-nginx.sh 1.18

push-nginx: BUILDINGIMAGE=nginx
push-nginx:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

test-nginx: ./tmp/build-nginx.tags ./tmp/build-fpm.tags
	xargs -I % ./test-nginx.sh $$(head -1 ./tmp/build-fpm.tags) % < ./tmp/build-nginx.tags
	xargs -I % ./test-nginx.sh $$(tail -1 ./tmp/build-fpm.tags) % < ./tmp/build-nginx.tags

#############################################################################################
# Docker Prometheus Exporter file images build matrix ./build-prometheus-exporter-file.sh (nginx version) (extra tag)
# Adding arbitrary version 1.0 in order to make sure if we break compa-tibility we have to up it
#############################################################################################
build-prometheus-exporter-file: BUILDINGIMAGE=prometheus-exporter-file
build-prometheus-exporter-file: clean-tags
	./build-prometheus-exporter-file.sh 1.18 prometheus-exporter-file1.0 prometheus-exporter-file1 latest

push-prometheus-exporter-file: BUILDINGIMAGE=prometheus-exporter-file
push-prometheus-exporter-file:
	cat ./tmp/build-${BUILDINGIMAGE}.tags | xargs -I % docker push %

test-nginx-e2e: ./tmp/build-nginx.tags
	xargs -I % ./test-nginx-e2e.sh % < ./tmp/build-nginx.tags

test-prometheus-exporter-file-e2e: ./tmp/build-prometheus-exporter-file.tags
	xargs -I % ./test-prometheus-exporter-file-e2e.sh % < ./tmp/build-prometheus-exporter-file.tags

#############################################################################################
# Clean all tags of the BUILDINGIMAGE
#############################################################################################
.NOTPARALLEL: clean-tags
clean-tags:
	rm ${current_dir}/tmp/build-${BUILDINGIMAGE}.tags || true

#############################################################################################
# CI dependencies
#############################################################################################
# Docker Hub Login
###########################################
ci-docker-login:
	docker login --username $$CONTAINER_REGISTRY_USERNAME --password $$CONTAINER_REGISTRY_PASSWORD docker.io

###########################################
# LINT
###########################################
lint:
	docker run -v ${current_dir}:/project:ro --workdir=/project --rm -it hadolint/hadolint:latest-debian hadolint /project/docker/nginx.Dockerfile

lint-shell:
	docker run --rm -v ${current_dir}:/mnt:ro koalaman/shellcheck src/http/nginx/docker-nginx-* build* test-*

###########################################
# Test
###########################################
test: test-nginx test-prometheus-exporter-file-e2e

#############################################################################################
#
#############################################################################################
scan-vulnerability:
	docker-compose -f test/security/docker-compose.yml -p clair-ci up -d
	RETRIES=0 && while ! wget -T 10 -q -O /dev/null http://localhost:6060/v1/namespaces ; do sleep 1 ; echo -n "." ; if [ $${RETRIES} -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; RETRIES=$$(($${RETRIES}+1)) ; done
	mkdir -p ./tmp/clair/token27
	cat ./tmp/build-*.tags | xargs -I % sh -c 'clair-scanner --ip 172.17.0.1 -r "./tmp/clair/%.json" -l ./tmp/clair/clair.log % || echo "% is vulnerable"'
	docker-compose -f test/security/docker-compose.yml -p clair-ci down