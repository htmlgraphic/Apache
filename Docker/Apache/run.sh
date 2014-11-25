#!/bin/bash

# Apache should be able to write to the /tmp directory
chown nobody:www-data /tmp

if [ ! -d /data/www/public_html ]; then
	
	# Move default coming soon page...
	mkdir -p /data/www/public_html
	mv /opt/temp.php /data/www/public_html/index.php

fi


if [ ! -d /data/apache2 ]; then
	
    mkdir -p /data/apache2/logs

	# Move initial apache conf script into directory
	cp -R /etc/apache2/* /data/apache2

	# Set the 'ServerName' directive globally
	echo ServerName localhost >> /data/apache2/conf-enabled/servername.conf

	# Customizable Apache conf file
	sudo mv /opt/apache-config.conf /data/apache2/sites-enabled/apache-config.conf
	
	# Disable the default website
	rm /data/apache2/sites-enabled/000-default.conf

fi

# Tweak Apache build
sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=1 \nIS_DEV=1 \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php5/apache2/php.ini
sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
sed -i 's|;session.save_path = "/var/lib/php5"|session.save_path = "/tmp"|g' /etc/php5/apache2/php.ini
sed -i 's|"\/var\/log\/apache2\/error.log"|"\/data\/apache2\/error.log"|g' /etc/php5/apache2/php.ini

sed -i 's|#ServerRoot "\/etc\/apache2"|ServerRoot "\/data\/apache2"|g' /etc/apache2/apache2.conf




# Postfix is not using /etc/resolv.conf is because it is running inside a chroot jail, needs its own copy.
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

# Postfix use smart host to relay email
postconf -e \
	relayhost=[post-office.htmlgraphic.com]:25 \
	inet_protocols=ipv4


/usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf