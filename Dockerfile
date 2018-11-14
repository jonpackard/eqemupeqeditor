FROM php:5.6.38-apache-jessie

RUN docker-php-ext-install mysqli pdo pdo_mysql
COPY peqphpeditor/ /var/www/html/
COPY start.sh /usr/local/bin/
COPY php.ini $PHP_INI_DIR/php.ini

CMD [ "start.sh" ]