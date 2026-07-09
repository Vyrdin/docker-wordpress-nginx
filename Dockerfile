FROM nginx:alpine

安装PHP核心及扩展 (来自新配置)
RUN apk add --no-cache \
    php81 \
    php81-fpm \
    php81-sqlite3 \
    php81-opcache \
    php81-mbstring \
    php81-session \
    bash

配置PHP-FPM (来自新配置，并优化)
RUN sed -i \
    -e 's/;listen.owner = nobody/listen.owner = nginx/g' \
    -e 's/;listen.group = nobody/listen.group = nginx/g' \
    -e 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g' \
    /etc/php81/php-fpm.d/www.conf

配置Nginx (来自旧配置，更完整)
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx-site.conf /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf

初始化SQLite数据库和数据目录 (来自新配置)
RUN mkdir -p /var/www/data && \
    touch /var/www/data/database.sqlite && \
    chown -R nginx:nginx /var/www

设置工作目录和复制应用文件 (来自旧配置)
WORKDIR /usr/share/nginx/html
# COPY ./www /usr/share/nginx/html  # 假设您的应用文件在这里
RUN chown -R nginx:nginx /usr/share/nginx/html

创建启动脚本 (整合两个部分)
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

健康检查 (来自旧配置)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/wp-admin/admin-ajax.php || exit 1

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
