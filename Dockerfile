# ---- Base PHP image ----
FROM php:8.4-fpm-alpine AS base

# System dependencies
RUN apk add --no-cache \
    bash \
    git \
    unzip \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev

# PHP extensions required by Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        intl \
        pdo \
        pdo_mysql \
        zip \
        mbstring \
        gd \
        opcache

# PHP production settings
COPY ./php.ini /usr/local/etc/php/conf.d/php.ini

WORKDIR /var/www/html

# ---- Composer dependencies ----
FROM composer:2 AS vendor

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# ---- Application image ----
FROM base

# Copy vendor deps
COPY --from=vendor /app/vendor ./vendor

# Copy application source
COPY . .

# Laravel permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

USER www-data

EXPOSE 9000

CMD ["php-fpm"]
