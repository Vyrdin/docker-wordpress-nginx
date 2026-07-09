FROM nginx:alpine AS nginxstage
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./nginx-site.conf /etc/nginx/conf.d/default.conf

FROM php:fpm-alpine

RUN apk add --no-cache sqlite-dev && docker-php-ext-install pdo_sqlite

RUN mkdir -p /usr/local/etc/php-fpm.d/ && \
    echo '[www]\
user = www-data\
group = www-data\
listen = /var/run/php-fpm.sock\
listen.owner = www-data\
listen.group = www-data\
listen.mode = 0660\
pm = dynamic\
pm.maxchildren = 5\
pm.startservers = 2\
pm.minspareservers = 1\
pm.maxspare_servers = 3' > /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
COPY . .
RUN mkdir -p /var/www/data && touch /var/www/data/database.sqlite && \
    chown -R www-data:www-data /var/www

COPY --from=nginxstage /etc/nginx/ /etc/nginx/

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
FROM php:fpm-alpine
RUN apk add --no-cache sqlite-dev && docker-php-ext-install pdo_sqlite
COPY . /var/www/html/
WORKDIR /var/www/html/
CMD ["php-fpm", "-F"]
