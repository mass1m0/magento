#!/bin/bash
# Set the default values for environment variables
set_default() {
        local var="$1"
        if [ ! "${!var:-}" ]; then
                 export "$var"="$2"
        fi
}

# Start redis in the background
redis-server --daemonize yes

# The file env.php doesn't exitst means that magento hasn't been installed yet
if [ ! -f /var/www/magento/app/etc/env.php ]; then
        set_default 'ADMIN_FIRSTNAME' 'firstname'
        set_default 'ADMIN_LASTNAME' 'lastname'
        set_default 'ADMIN_EMAIL' 'sample@example.com'
        set_default 'ADMIN_USER' 'root'
        set_default 'ADMIN_PASSWORD' 'password1234'
        set_default 'DB_NAME' 'magento'
        set_default 'DB_PASSWORD' 'password1234'
        set_default 'BACKEND_FRONTNAME' 'admin'
        set_default 'PRODUCTION_MODE' false

        # Configure apache2 and PHP
        a2ensite magento.conf
        a2dissite 000-default.conf
        a2enmod rewrite
        phpenmod mcrypt

        # Set mysql password and creat table for magento2
        service mysql start
        mysqladmin -u root password $DB_PASSWORD
        mysql -u root -e "create database magento; GRANT ALL ON magento.* TO magento@localhost IDENTIFIED BY 'magento';" --password=$DB_PASSWORD

        cd /var/www/magento

        # Install the magento2
        bin/magento setup:install --admin-firstname=$ADMIN_FIRSTNAME \
                                                   --admin-lastname=$ADMIN_LASTNAME \
                                                   --admin-email=$ADMIN_EMAIL \
                                                   --admin-user=$ADMIN_USER \
                                                   --admin-password=$ADMIN_PASSWORD \
                                                   --db-name=$DB_NAME \
                                                   --db-password=$DB_PASSWORD \
                                                   --backend-frontname=$BACKEND_FRONTNAME \
                                                   --base-url=$BASE_URL

        # Check if magento installed successfully
        if [ -f app/etc/env.php ]; then

                # Configure magento2 to use redis as cache tool
                sed -e "/'save' => 'files',/ {" -e "r /session.php" -e "d" -e "}" -i app/etc/env.php
                sed -e "/);/ {" -e "r /page_caching.php" -e "d" -e "}" -i app/etc/env.php

		if [ "$PRODUCTION_MODE" = true ] ; then
        	        # Switch the magento2 mode to production, we will enable this process until it can proceed on azure web app for linux
               		echo "switch magento to production mode..."
                	bin/magento deploy:mode:set production

			echo "setting file permissions for production mode..."
			find var vendor lib pub/static pub/media app/etc -type f -exec chmod g+w {} \;
			find var vendor lib pub/static pub/media app/etc -type d -exec chmod g+w {} \;
			chmod o+rwx app/etc/env.php
		else
			# Default mode
			echo "setting file permissions for default mode..."
			find var pub/static pub/media app/etc -type f -exec chmod g+w {} \;
			find var pub/static pub/media app/etc -type d -exec chmod g+ws {} \;
		fi
        fi
fi

# Check if mysql is running or start it
if ! service mysql status; then
        service mysql start
fi

cd /var/www/magento

echo "run cron jobs the first time..."
php bin/magento cron:run
php bin/magento cron:run

echo "schedule cron jobs to run every minute..."
service cron restart
crontab -l > magentocron
cat /cronjobs >> magentocron
crontab magentocron
rm magentocron

# Run apache in the foreground
apachectl -DFOREGROUND