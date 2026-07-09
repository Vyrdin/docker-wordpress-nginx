FROM nginx:alpine

RUN apk add --no-cache \
    php7 \
    php7-fpm \
    php7-sqlite3 \
    php7-opcache \
    php7-mbstring \
    php7-session \
    bash

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
