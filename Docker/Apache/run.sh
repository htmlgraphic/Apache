#!/bin/bash

if [ ! -f /data/www/conf ]; then
	
	mkdir /data/www
	mkdir /data/www/conf

	# Symlink default directory, for apache conf scripts
	ln -s /etc/apache2/sites-enabled /data/www/conf

	cp apache-config.conf /data/www/conf/000-default.conf

fi

source /etc/apache2/envvars
exec /usr/sbin/apache2ctl -D FOREGROUND