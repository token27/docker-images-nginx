FROM nginx:1.15-alpine as http

LABEL maintainer="Token27 <admin@token27.com>" \
    org.opencontainers.image.title="nginx" \
    org.opencontainers.image.description="Nginx on Alpine Linux" \
    org.opencontainers.image.authors="Token27 <admin@token27.com>" \
    org.opencontainers.image.vendor="Token27" \
    org.opencontainers.image.version="v1.0.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/token27/nginx/" \
    org.opencontainers.image.source="https://github.com/token27/nginx"

ENV APP_OWNER=app
ENV APP_GROUP=app

# Add user and group
RUN set -x \
    && addgroup -g 1000 ${APP_OWNER} \
    && adduser -u 1000 -D -G ${APP_OWNER} ${APP_GROUP}

ARG NGINX_VHOST_TEMPLATE
ENV NGINX_VHOST_TEMPLATE=$NGINX_VHOST_TEMPLATE
# Env definition
ENV NGINX_DOCUMENT_ROOT="/var/www/html"
ENV NGINX_SERVER_NAME=localhost
ENV NGINX_PORT=80
ENV NGINX_WORKERS_PROCESSES=1
ENV NGINX_WORKERS_CONNECTIONS=1024
ENV NGINX_KEEPALIVE_TIMEOUT=65
ENV NGINX_EXPOSE_VERSION=off
ENV NGINX_CLIENT_BODY_BUFFER_SIZE=16k
ENV NGINX_CLIENT_MAX_BODY_SIZE=1m
ENV NGINX_LARGE_CLIENT_HEADER_BUFFERS="4 8k"
ENV NGINX_CORS_ENABLE=false
ENV NGINX_CORS_ALLOW_ORIGIN="*"

ENV NGINX_LOG_FOLDER=/var/log/nginx
ENV NGINX_FILE_LOG_ERROR=error.log
ENV NGINX_FILE_LOG_ACCESS=access.log
ENV FCGI_CONNECT="unix:/var/run/php-fpm.sock"
ENV NGINX_USER=nginx
ENV NGINX_DEFAULT_TYPE=text/plain


# Nginx logs
RUN mkdir -p ${NGINX_LOG_FOLDER} \
    && touch ${NGINX_LOG_FOLDER}/${NGINX_FILE_LOG_ERROR} \
    && touch ${NGINX_LOG_FOLDER}/${NGINX_FILE_LOG_ACCESS} \
    && chown -R ${APP_OWNER}:${APP_GROUP} ${NGINX_LOG_FOLDER}

# Patch gCVE-2019-11068 (libxslt)
RUN apk add --no-cache --upgrade apk-tools \
 && apk add --no-cache --upgrade nano vim curl wget zip unzip git g++ make autoconf bash supervisor tzdata gettext gcc pkgconf \
 && apk add --no-cache --upgrade libxml2-dev libxslt-dev

# Nginx helper scripts
COPY src/http/nginx/docker-nginx-* /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-nginx-*

# Nginx configuration filesg 
COPY src/http/nginx/conf/main/ /etc/nginx/
COPY src/http/nginx/conf/${NGINX_VHOST_TEMPLATE} /etc/nginx/

CMD ["docker-nginx-entrypoint"]

# Base images don't need healthcheck since they are not running applications
# this can be overriden in the child images
HEALTHCHECK NONE

FROM http as http-dev

ENV NGINX_EXPOSE_VERSION=on
