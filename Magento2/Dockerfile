# Build magento2 from ubuntu base
FROM ubuntu:16.04

ARG PACKAGE_URL=https://raw.githubusercontent.com/Sharpeli/Packages/master/Magento-CE-2_1_3_tar_gz-2016-12-13-09-08-39.tar.gz

# Install build-essential, wget, cron
RUN apt-get update \
    && apt-get install -y build-essential \
                wget \
                cron \
                curl \

# Install apache2 
    && apt-get update \ 
    && apt-get -y install apache2 \

# Install PHP
    && apt-get -y update \
    && apt-get install -y php7.0 \
                libapache2-mod-php7.0 \
                php7.0 \
                php7.0-common \
                php7.0-gd \
                php7.0-mysql \
                php7.0-mcrypt \
                php7.0-curl \
                php7.0-intl \
                php7.0-xsl \
                php7.0-mbstring \
                php7.0-zip \
                php7.0-bcmath \
                php7.0-iconv \
                php7.0-gettext \
    && sed -i 's/memory_limit = 128M/memory_limit = 1G/' /etc/php/7.0/apache2/php.ini \
    && sed -i 's/memory_limit = -1/memory_limit = 1G/' /etc/php/7.0/cli/php.ini \

# Install MySQL without interaction
    && DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server \
    && service mysql start \

# ------------------------
# SSH Server support
# ------------------------
    && apt-get update \ 
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd \

# Install phpmyadmin
    && echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections \
    && echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections \
    && echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections \
    && echo "phpmyadmin phpmyadmin/mysql/app-pass password password" |debconf-set-selections \
    && echo "phpmyadmin phpmyadmin/app-password-confirm password password" | debconf-set-selections \
    && apt-get -y install phpmyadmin \
    && sed -i "s/function StringReader(\$str='') {/function __construct(\$str='') {/" /usr/share/php/php-gettext/streams.php \
    && sed -i "s/function FileReader(\$filename) {/function __construct(\$filename) {/" /usr/share/php/php-gettext/streams.php \
    && sed -i "s/function CachedFileReader(\$filename) {/function __construct(\$filename) {/" /usr/share/php/php-gettext/streams.php \
    && sed -i "s/function gettext_reader(\$Reader, \$enable_cache = true) {/function __construct(\$Reader, \$enable_cache = true) {/" /usr/share/php/php-gettext/gettext.php \


# Install Redis
    && wget http://download.redis.io/redis-stable.tar.gz \
    && tar xvzf redis-stable.tar.gz \
    && rm redis-stable.tar.gz \
    && cd redis-stable \
    && make \
    && make install \

# Download Mangento CE 2.1.3 archive from my github repo and extract it.
# To download package from your repo, add these arguments while you build the image: --build-arg PACKAGE_URL=<your package location> 
    && cd /var/www \
    && mkdir magento \
    && wget -O magento2.tar.gz ${PACKAGE_URL} \
    && tar -xvzf magento2.tar.gz -C ./magento \
    && rm magento2.tar.gz \

# Set pre-installation file permissions
    && usermod -g www-data root \
    && cd /var/www/magento \
    && find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \; \
    && find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \; \
    && chown -R :www-data . \
    && chmod u+x bin/magento \
    
# Download composer
    && curl -s -f -L -o /tmp/installer.php https://raw.githubusercontent.com/composer/getcomposer.org/da290238de6d63faace0343efbdd5aa9354332c5/web/installer \
    && php -r " \
    \$signature = '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410'; \
    \$hash = hash('SHA384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
        unlink('/tmp/installer.php'); \
        echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
        exit(1); \
    }"
    
COPY sshd_config /etc/ssh/
COPY magento.conf /etc/apache2/sites-available/
COPY docker-entrypoint.sh /usr/local/bin/
COPY cronjobs /cronjobs
COPY phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin.conf
COPY phpmyadmin-access /usr/share/phpmyadmin/.htaccess
COPY redis.php /redis.php
COPY index.html /var/www/html/index.html

# Change permissions for docker-entrypoint.sh
RUN chmod +x  /usr/local/bin/docker-entrypoint.sh

EXPOSE 2222 80 433

ENTRYPOINT ["docker-entrypoint.sh"]
