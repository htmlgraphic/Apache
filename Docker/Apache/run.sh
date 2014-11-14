#!/bin/bash

if [ ! -d /data/apache2 ]; then
	
	mkdir -p /data/apache2

	# Move initial apache conf script into directory
	cp -R /etc/apache2/* /data/apache2

	# Set the 'ServerName' directive globally
	echo ServerName localhost >> /data/apache2/conf-enabled/servername.conf

	# Move default coming soon page...
	mv /opt/temp.php /data/www/public_html/index.php

	# Customizable Apache conf file
	sudo mv /opt/apache-config.conf /data/apache2/sites-enabled/apache-config.conf
	
	# Disable the default website
	rm /data/apache2/sites-enabled/000-default.conf

fi

source /data/apache2/envvars
exec /usr/sbin/apache2ctl -D FOREGROUND