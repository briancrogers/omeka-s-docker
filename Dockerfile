FROM php:apache

# Omeka-S web publishing platform for digital heritage collections (https://omeka.org/s/)
# Initial maintainer: Oldrich Vykydal (o1da) - Klokan Technologies GmbH  
MAINTAINER Brian Rogers <b.c.rogers@swansea.ac.uk>

RUN a2enmod rewrite

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get -qq update && apt-get -qq -y --no-install-recommends install \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libmemcached-dev \
    zlib1g-dev \
    imagemagick \
    libmagickwand-dev \
    git

# Install the PHP extensions we need
RUN docker-php-ext-install -j$(nproc) iconv pdo pdo_mysql mysqli gd
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN pecl install mcrypt-1.0.2 && docker-php-ext-enable mcrypt && pecl install imagick && docker-php-ext-enable imagick 

# Add the Omeka-S PHP code
#COPY ./omeka-s-1.3.0.zip /var/www/
#RUN unzip -q /var/www/omeka-s-1.3.0.zip -d /var/www/ \
#&&  rm /var/www/omeka-s-1.3.0.zip \
#&&  rm -rf /var/www/html/ \
#&&  mv /var/www/omeka-s/ /var/www/html/

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV OMEKA_FORK "digirati-co-uk"
ENV OMEKA_BRANCH "bugfix/7.2-rebase-1.3.0"
ENV TAR_FILE_NAME "7.2-rebase-1.3.0"

# Download our fork.
ADD --chown=www-data:www-data https://github.com/${OMEKA_FORK}/omeka-s/archive/${OMEKA_BRANCH}.tar.gz /var/www/
RUN tar zxf /var/www/${TAR_FILE_NAME}.tar.gz -C /var/www/ \
&& rm /var/www/${TAR_FILE_NAME}.tar.gz \
&& rm -rf /var/www/html/ \
&& mv /var/www/omeka-s-bugfix-7.2-rebase-1.3.0/ /var/www/html/

COPY ./imagemagick-policy.xml /etc/ImageMagick/policy.xml
COPY ./.htaccess /var/www/html/.htaccess

# Add some Omeka modules
COPY ./omeka-s-modules-v4.tar.gz /var/www/html/
RUN rm -rf /var/www/html/modules/ \
&&  tar -xzf /var/www/html/omeka-s-modules-v4.tar.gz -C /var/www/html/ \
&&  rm /var/www/html/omeka-s-modules-v4.tar.gz

# Add some themes
COPY ./centerrow-v1.4.0.zip ./cozy-v1.3.1.zip ./thedaily-v1.4.0.zip /var/www/html/themes/
RUN unzip -q /var/www/html/themes/centerrow-v1.4.0.zip -d /var/www/html/themes/ \
&&  unzip -q /var/www/html/themes/cozy-v1.3.1.zip -d /var/www/html/themes/ \
&&  unzip -q /var/www/html/themes/thedaily-v1.4.0.zip -d /var/www/html/themes/ \
&&  rm /var/www/html/themes/centerrow-v1.4.0.zip /var/www/html/themes/cozy-v1.3.1.zip /var/www/html/themes/thedaily-v1.4.0.zip

# Create one volume for files and config
RUN mkdir -p /var/www/html/volume/config/ && mkdir -p /var/www/html/volume/files/
COPY ./database.ini /var/www/html/volume/config/
#RUN rm /var/www/html/config/database.ini \
RUN ln -s /var/www/html/volume/config/database.ini /var/www/html/config/database.ini \
&& rm -Rf /var/www/html/files/ \
&& ln -s /var/www/html/volume/files/ /var/www/html/files \
&& chown -R www-data:www-data /var/www/html/ \
&& chmod 600 /var/www/html/volume/config/database.ini \
&& chmod 600 /var/www/html/.htaccess

RUN sed -i '/"type": "vcs"/a "no-api": true,' composer.json
RUN composer update \
&& composer require "kokspflanze/zfc-twig" "2.2.0" \
&& composer install

VOLUME /var/www/html/volume/

CMD ["apache2-foreground"]
