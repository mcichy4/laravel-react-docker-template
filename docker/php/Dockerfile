FROM php:8.4-fpm

ARG USER_ID=1000
ARG GROUP_ID=1000

WORKDIR /var/www/backend

RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        libpq-dev \
        libzip-dev \
    && docker-php-ext-install \
        pdo \
        pdo_pgsql \
        zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN if ! getent group "${GROUP_ID}" > /dev/null; then \
        groupadd --gid "${GROUP_ID}" app; \
    fi \
    && useradd \
        --uid "${USER_ID}" \
        --gid "${GROUP_ID}" \
        --create-home \
        --shell /bin/bash \
        app

USER app

CMD ["php-fpm"]