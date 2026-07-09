# WordPress Nginx Container (Lightweight)

A lightweight Nginx-only Docker container designed for hosting WordPress on managed container platforms.

## Architecture

This solution follows **方案 A** (Reverse Proxy Pattern):

```
┌──────────────────────────────────────────┐
│     Client Request                       │
└──────────────────────┬──────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │  Nginx (Port 80)            │
        │  (This Service)             │
        └──────────────┬──────────────┘
                       │
        ┌──────────────┴──────────────────────┐
        │  PHP-FPM Service                   │
        │  (Separate Service)                │
        └──────────────┬──────────────────────┘
                       │
        ┌──────────────┴──────────────────┐
        │  MySQL Database                │
        │  (Managed DB Svc)              │
        └────────────────────────────────┘
```

## Features

✅ **Lightweight** - Based on `nginx:alpine` (~20MB)
✅ **WordPress Optimized** - Proper routing and caching rules
✅ **Reverse Proxy** - Communicates with PHP-FPM service
✅ **Security** - Security headers, denial of service protection
✅ **Performance** - Gzip compression, static file caching
✅ **Health Checks** - Built-in health check endpoint
✅ **Environment Variables** - Dynamic PHP-FPM upstream configuration

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_FPM_HOST` | `php` | PHP-FPM service hostname |
| `PHP_FPM_PORT` | `9000` | PHP-FPM service port |

## Docker Compose Usage

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f nginx

# Stop services
docker-compose down
```

### Environment Configuration

Create `.env` file:

```env
DB_NAME=wordpress
DB_USER=wordpress
DB_PASSWORD=your_secure_password
DB_ROOT_PASSWORD=root_password
```

## Manual Container Deployment

### Build Image

```bash
docker build -t wordpress-nginx:latest .
```

### Run Container

```bash
docker run -d \
  --name wordpress-nginx \
  -p 80:80 \
  -e PHP_FPM_HOST=php-service \
  -e PHP_FPM_PORT=9000 \
  -v $(pwd)/www:/usr/share/nginx/html:ro \
  --link php-service:php \
  wordpress-nginx:latest
```

## Nginx Configuration

### Key Features

1. **WordPress Routing** - Proper `try_files` directive for WordPress permalinks
2. **Static File Caching** - CSS, JS, images cached for 30 days
3. **Security Headers**:
   - X-Frame-Options: SAMEORIGIN
   - X-Content-Type-Options: nosniff
   - X-XSS-Protection: 1; mode=block
   - Referrer-Policy: strict-origin-when-cross-origin

4. **Protected Paths** - Deny access to:
   - Hidden files (`.htaccess`, etc.)
   - WordPress config files
   - PHP files in upload directory

5. **FastCGI Upstream** - Configurable PHP-FPM connection

## Directory Structure

```
.
├── Dockerfile                 # Nginx Alpine-based image
├── nginx.conf                # Main Nginx configuration
├── nginx-site.conf          # Virtual host configuration
├── entrypoint.sh            # Environment variable substitution
├── docker-compose.yml       # Multi-service orchestration
├── www/                     # WordPress files (mounted as volume)
└── README.md
```

## Troubleshooting

### 502 Bad Gateway

**Cause**: PHP-FPM service is unreachable.

**Solution**:
- Verify PHP-FPM service is running
- Check `PHP_FPM_HOST` and `PHP_FPM_PORT` environment variables
- Ensure network connectivity between containers

```bash
docker exec wordpress-nginx curl -v http://php:9000/
```

### Timeout Errors

**Cause**: PHP scripts taking too long.

**Solution**: Increase FastCGI timeouts in `nginx-site.conf`:

```nginx
fastcgi_read_timeout 300s;
```

### Permission Denied

**Cause**: WordPress directory not properly mounted.

**Solution**: Ensure proper mount permissions:

```bash
chmod 755 www/
chmod 644 www/*.php
```

## Performance Tuning

### Enable Caching

Modify `nginx-site.conf` to add caching headers:

```nginx
add_header Cache-Control "max-age=3600, public";
```

### Increase Worker Connections

Modify `nginx.conf`:

```nginx
worker_connections 2048;
```

### Enable HTTP/2

For HTTPS setup, update listen directive:

```nginx
listen 443 ssl http2;
```

## SSL/TLS Setup

To enable HTTPS:

1. Mount SSL certificates:

```bash
docker run -d \
  -v /path/to/cert.pem:/etc/nginx/ssl/cert.pem:ro \
  -v /path/to/key.pem:/etc/nginx/ssl/key.pem:ro \
  wordpress-nginx:latest
```

2. Update `nginx-site.conf`:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # ... rest of configuration
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

## Health Check

The container includes a health check that verifies Nginx is responding:

```bash
docker ps | grep wordpress-nginx
```

Expected output: `(healthy)` status

## License

MIT License

## References

- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress with Nginx](https://wordpress.org/support/article/nginx/)
- [FastCGI Parameters](https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html)
