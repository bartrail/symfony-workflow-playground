FROM provolution/php:8.1 as php

ARG APP_ENV=dev
ARG COMPOSER_ALLOW_SUPERUSER=1
# for cache clear
ARG DATABASE_URL=mysql://root@mysql:3306/website?charset=utf8mb4&serverVersion=5.7
ARG SENTRY_DSN=''

WORKDIR /var/build

# prevent the reinstallation of vendors at every changes in the source code
COPY composer.* symfony.* ./
RUN set -eux; \
    if [ -f composer.json ]; then \
		composer install --prefer-dist --no-autoloader --no-scripts --no-progress; \
		composer clear-cache; \
    fi

COPY . .
RUN rm -Rf docker/

RUN set -eux; \
	mkdir -p var/cache var/log; \
    if [ -f composer.json ]; then \
		composer dump-autoload --classmap-authoritative; \
		composer dump-env dev; \
		composer run-script --no-dev post-install-cmd; \
		chmod +x bin/console; sync; \
    fi

# update sulu admin js stuff
RUN bin/console sulu:admin:update-build

#####

#FROM node:10-alpine as assets
#
#WORKDIR /var/build
#COPY . .
#
#RUN yarn --frozen-lockfile
#RUN npm rebuild node-sass
#RUN yarn encore dev
#####

FROM phusion/baseimage:bionic-1.0.0

ARG DEBIAN_FRONTEND=noninteractive

# set environments
RUN echo prod > /etc/container_environment/APP_ENV
RUN echo Europe/Berlin > /etc/container_environment/TZ
ENV APP_ENV=dev

# install common tools & tzdata
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        software-properties-common \
        tzdata \
        && \
    rm -r /var/lib/apt/lists/*

# install php
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.1 \
        php8.1-fpm \
        php8.1-cli \
        php8.1-intl \
        php8.1-pdo \
        php8.1-zip \
        php8.1-xml \
        php8.1-mbstring \
        php8.1-curl \
        php8.1-pdo \
        php8.1-mysql \
        php8.1-opcache \
        php8.1-apcu \
        php8.1-gd \
        && \
    rm -r /var/lib/apt/lists/*

# install & setup nginx
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        nginx \
        && \
    rm -r /var/lib/apt/lists/*

# setup php-fpm
RUN mkdir /etc/service/php-fpm
COPY docker/review/php-fpm.sh /etc/service/php-fpm/run
RUN chmod +x /etc/service/php-fpm/run

RUN mkdir -p /run/php
COPY docker/review/fpm-www.conf /etc/php/8.1/fpm/pool.d/www.conf
COPY docker/review/project.ini /etc/php/8.1/fpm/conf.d/00_project.ini

# setup nginx
RUN mkdir /etc/service/nginx
COPY docker/review/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

COPY docker/review/nginx.conf /etc/nginx/nginx.conf
COPY docker/review/nginx.vhost /etc/nginx/vhosts.d/app.conf

# setup boot script
RUN mkdir -p /etc/my_init.d
COPY docker/review/boot.sh /etc/my_init.d/boot.sh
RUN chmod +x /etc/my_init.d/boot.sh

# copy project
COPY --from=php /var/build /srv/share
RUN chmod -R u+rwX,go+rX,go-w /srv/share
RUN rm -rf /srv/share/var
RUN mkdir /srv/share/var
RUN chown www-data:www-data /srv/share/var
RUN chmod -R 777 /srv/share/var

#COPY --from=assets /var/build/public/build /srv/share/public/build

RUN chown -R www-data:www-data /srv/share/public

EXPOSE 80

CMD ["/sbin/my_init"]
