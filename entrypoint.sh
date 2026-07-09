#!/bin/bash
set -e

# Substitute environment variables in nginx configuration
echo "Configuring Nginx..."

# Get PHP-FPM host and port from environment
PHP_FPM_HOST=${PHP_FPM_HOST:-php}
PHP_FPM_PORT=${PHP_FPM_PORT:-9000}

echo "PHP-FPM upstream: $PHP_FPM_HOST:$PHP_FPM_PORT"

# Create temporary nginx config with substituted variables
envsubst '${PHP_FPM_HOST},${PHP_FPM_PORT}' < /etc/nginx/conf.d/default.conf > /tmp/default.conf.tmp
mv /tmp/default.conf.tmp /etc/nginx/conf.d/default.conf

# Test nginx configuration
echo "Testing Nginx configuration..."
if ! nginx -t; then
    echo "Nginx configuration test failed!"
    exit 1
fi

echo "Nginx configuration is valid"
echo "Starting Nginx..."

# Execute the main command
exec "$@"
