#!/bin/sh
set -e

# Run Laravel optimizations if APP_KEY is set
if [ -n "$APP_KEY" ]; then
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Execute the main command
exec "$@"