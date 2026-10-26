#!/usr/bin/env bash
set -euo pipefail
mkdir -p docker
cat > Dockerfile <<'DOCKER'
FROM php:8.4-fpm-alpine

RUN docker-php-ext-install pdo_mysql intl

COPY docker/php.ini /usr/local/etc/php/conf.d/zz-app.ini
WORKDIR /var/www/app
DOCKER
cat > docker/php.ini <<'INI'
memory_limit = 256M
expose_php = Off
zend_extension=opcache.so
opcache.enable = 1
opcache.memory_consumption = 192
opcache.validate_timestamps = 0
INI
