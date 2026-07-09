FROM nginx:alpine

# 设置工作目录
WORKDIR /usr/share/nginx/html

# 删除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 添加自定义配置
#COPY nginx.conf /etc/nginx/conf.d/

# 复制静态文件到容器
#COPY ./static /usr/share/nginx/html


MAINTAINER Eugene Ware <eugene@noblesamurai.com>

# Install curl for health checks and basic utilities
RUN apk add --no-cache curl bash

# Copy WordPress files
#COPY ./www /usr/share/nginx/html

# Copy Nginx configuration
COPY ./nginx-site.conf /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html

# Create a startup script for environment variable substitution
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/wp-admin/admin-ajax.php || exit 1

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
