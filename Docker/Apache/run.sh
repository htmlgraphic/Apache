#!/bin/bash

echo 10.132.191.193 mysql >> /etc/hosts

if [ ! -d /data/apache2 ]; then
	
	mkdir -p /data/apache2

	# Move initial apache conf script into directory
	cp -R /etc/apache2/* /data/apache2

	# Set the 'ServerName' directive globally
	echo ServerName localhost >> /data/apache2/conf-available/servername.conf

	# Move default htmlgraphic conf from /opt
	#mv /opt/apache-config.conf /data/apache2/sites-enabled/htmlgraphic.conf

	# Disable the default website
	rm /data/apache2/sites-enabled/000-default.conf

fi

/bin/bash -c "source /data/apache2/envvars"
/bin/bash -c "etc/init.d/apache2 start"

#exec /usr/sbin/apache2ctl -D FOREGROUND

while ( true )
    do
    echo "Detach with Ctrl-p Ctrl-q. Dropping to shell"
    sleep 1
    /bin/bash
done