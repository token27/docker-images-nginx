# Nginx Docker Images Builder

An easy way to create and maintain Nginx Docker images

[![Latest Stable Version](https://poser.pugx.org/token27/docker-images-nginx/v/stable.svg)](https://packagist.org/packages/token27/docker-images-nginx)
[![License](https://poser.pugx.org/token27/docker-images-nginx/license)](https://packagist.org/packages/token27/docker-images-nginx)
[![Total Downloads](https://poser.pugx.org/token27/docker-images-nginx/d/total)](https://packagist.org/packages/token27/docker-images-nginx)

## Requirements

The following prerequisites are needed for ```Nginx Docker Images Builder``` to run.

- Docker
    - [Linux](https://www.gnu.org/software/make)
    - [Windows](https://docs.docker.com/engine/install/ubuntu/)


- Makefile
    - [Linux](https://www.gnu.org/software/make)
    - [Windows](http://gnuwin32.sourceforge.net/packages/make.htm)

## How to start ?

### Set you Docker Hub credentials in the environments vars and do login:

```
export CONTAINER_REGISTRY_USERNAME=[YOUR_USERNAME]
export CONTAINER_REGISTRY_PASSWORD=[YOUR_PASSWORD]

make ci-docker-login
```

### Build, test or push `NGINX` images:

```
make build
make test
make push
```

## Docs

See [Documentation](docs).