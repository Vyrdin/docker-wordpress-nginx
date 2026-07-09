FROM nginx:alpine
FROM php:fpm-alpine

#只用安装 SQLite 扩展，其他都自带了
RUN apk add --no-cache sqlite-libs \
    && docker-php-ext-install pdo_sqlite

#配置 Nginx
COPY ./nginx-site.conf /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf

#你的应用文件和权限设置
WORKDIR /var/www/html
COPY . /var/www/html
RUN chown -R www-data:www-data /var/www/html

#启动脚本
COPY ./entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN sed -i \
    -e 's/;listen.owner = nobody/listen.owner = nginx/g' \
    -e 's/;listen.group = nobody/listen.group = nginx/g' \
    -e 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g' \
    /etc/php7/php-fpm.d/www.conf

RUN rm /etc/nginx/conf.d/default.conf

COPY ./nginx-site.conf /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/data && \
    touch /var/www/data/database.sqlite && \
    chown -R nginx:nginx /var/www

WORKDIR /usr/share/nginx/html

RUN chown -R nginx:nginx /usr/share/nginx/html

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/wp-admin/admin-ajax.php || exit 1

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
