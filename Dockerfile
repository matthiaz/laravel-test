# ---- Base FrankenPHP image ----
FROM dunglas/frankenphp:1-php8.4-alpine AS base

# Install PHP extensions Laravel needs
RUN install-php-extensions \
    pdo_mysql \
    zip \
    intl \
    mbstring \
    gd \
    opcache \
    redis \
    pcntl \
    bcmath \
    bash

WORKDIR /app

# Copy FrankenPHP Caddyfile for proper routing
COPY Caddyfile /etc/caddy/Caddyfile

# Copy php.ini if needed
COPY php.ini /usr/local/etc/php/conf.d/php.ini

# ---- Composer stage for caching ----
FROM composer:2 AS vendor

WORKDIR /app

# Copy composer files first for caching
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist

# ---- Final application image ----
FROM base

WORKDIR /app

# Copy application source
COPY --chown=www-data:www-data . .

# Copy vendor from composer stage
COPY --from=vendor --chown=www-data:www-data /app/vendor ./vendor

# Set Laravel permissions
RUN mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chown -R www-data:www-data /app/storage /app/bootstrap/cache \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# Run Laravel optimizations
# RUN php artisan config:cache \
#    && php artisan route:cache \
#    && php artisan view:cache

# Expose HTTP port
EXPOSE 80


# Create an entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# FrankenPHP starts via our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]