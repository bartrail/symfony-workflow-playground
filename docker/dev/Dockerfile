FROM phusion/baseimage:focal-1.2.0

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_ID=501
ENV APP_ENV=dev
ARG REQUIRE_CHECKER_VERSION="4.2.0"
ARG DEPTRAC_VERSION="0.24.0"

# set environments
RUN echo $APP_ENV > /etc/container_environment/APP_ENV

# install common tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    curl \
    software-properties-common \
    openssh-client \
    make \
    wget \
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
    php8.1-amqp \
    php8.1-gd \
    php8.1-bcmath \
    php8.1-xdebug \
    && \
    rm -r /var/lib/apt/lists/*

# configure php
COPY php/php-fpm.ini /etc/php/8.1/fpm/conf.d/99-app.ini
COPY php/php-cli.ini /etc/php/8.1/cli/conf.d/99-app.ini

RUN mkdir -p /run/php
COPY php/fpm-www.conf /etc/php/8.1/fpm/pool.d/www.conf

# setup php-fpm
RUN mkdir /etc/service/php-fpm
COPY php/php-fpm.sh /etc/service/php-fpm/run
RUN chmod +x /etc/service/php-fpm/run

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install external tools
RUN wget https://github.com/maglnet/ComposerRequireChecker/releases/download/$REQUIRE_CHECKER_VERSION/composer-require-checker.phar -O /usr/local/bin/require-checker
RUN chmod +x /usr/local/bin/require-checker

RUN wget https://github.com/qossmic/deptrac/releases/download/$DEPTRAC_VERSION/deptrac.phar -O /usr/local/bin/deptrac
RUN chmod +x /usr/local/bin/deptrac

# install & setup nginx
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    nginx \
    && \
    rm -r /var/lib/apt/lists/*

# setup nginx
RUN mkdir /etc/service/nginx
COPY nginx/nginx.sh /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/nginx.vhost /etc/nginx/vhosts.d/app.conf

# create user home-directory so we can ssh into the container if we need to
RUN mkdir -p /home/www-data
RUN chown -R www-data:www-data /home/www-data
RUN usermod --shell /bin/bash -u ${USER_ID} -d /home/www-data www-data

EXPOSE 80

WORKDIR "/srv/share"

CMD ["/sbin/my_init"]
