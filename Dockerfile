FROM php:7.1-apache

# Omeka-S web publishing platform for digital heritage collections (https://omeka.org/s/)
# Initial maintainer: Oldrich Vykydal (o1da) - Klokan Technologies GmbH  
MAINTAINER Eric Dodemont <eric.dodemont@skynet.be>

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick

# Install the PHP extensions we need
RUN docker-php-ext-install -j$(nproc) iconv mcrypt pdo pdo_mysql mysqli gd 
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

# Add the Omeka-S PHP code
COPY ./omeka-s-1.1.0.zip /var/www/
RUN unzip -q /var/www/omeka-s-1.1.0.zip -d /var/www/ \
&&  rm /var/www/omeka-s-1.1.0.zip \
&&  rm -rf /var/www/html/ \
&&  mv /var/www/omeka-s/ /var/www/html/

COPY ./database.ini /var/www/html/config/database.ini
RUN chmod 600 /var/www/html/config/database.ini
COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
COPY ./.htaccess /var/www/html/.htaccess

# Add some Omeka modules
COPY ./omeka-s-modules.tar.gz /var/www/html/
RUN rm -rf /var/www/html/modules/ \
&&  tar -xzf /var/www/html/omeka-s-modules.tar.gz -C /var/www/html/ \
&&  rm /var/www/html/omeka-s-modules.tar.gz

RUN chown -R www-data:www-data /var/www/html/

VOLUME /var/www/html/files/
VOLUME /var/www/html/config/

CMD ["apache2-foreground"]
