#!/bin/bash

OutputLog ()
{
	echo "=> Adding environmental variables:"
	echo "=> NODE_ENVIRONMENT: $NODE_ENVIRONMENT"
	echo "=> Log Key: $LOG_TOKEN"
}

# output logs to logentries.com
cat <<EOF > /etc/rsyslog.d/logentries.conf
\$template Logentries,"$LOG_TOKEN %HOSTNAME% %syslogtag%%msg%\n"

*.* @@api.logentries.com:10000;Logentries
EOF


if [ ! -d /data/www/public_html ]; then

	# Move default coming soon page...
	mkdir -p /data/www/public_html
	mv /opt/app/*.php /data/www/public_html/
	mv /opt/app/*.png /data/www/public_html/

fi


if [ ! -d /data/apache2 ]; then

	# Create directories for logs and ssl certificates
	mkdir -p /data/apache2/{logs,ssl}

	# Create diectory for any pear libaries
	mkdir -p /data/pear
	touch /data/pear/empty

	# Move initial apache conf script into directory
	cp -R /etc/apache2/* /data/apache2

	# Symlink modules for Apache so 'a2enmod' can be setup correctly
	cd /data/apache2 && ln -s /etc/apache2/mods-available mods-available
	cd /data/apache2 && ln -s /etc/apache2/mods-enabled mods-enabled

	# Strict permissions on Apache conf files
	cd /etc/apache2/ && chmod 700 *

	# Set the 'ServerName' directive globally
	echo ServerName localhost >> /data/apache2/conf-enabled/servername.conf

	# Customizable Apache configuration file(s)
	sudo mv /opt/app/*.conf /data/apache2/sites-enabled/

	# Move needed certificates into place
	mv -f /opt/app/ssl/* /data/apache2/ssl

	# Disable the default website
	rm /data/apache2/sites-enabled/000-default.conf

fi



#####
#
#  Edit files on the instance, check for proper environment
#
#####
if [ ! -f /etc/php5/apache2/build ]; then

	# Tweak Apache build
	sed -i 's|;include_path = ".:/usr/share/php"|include_path = ".:/usr/share/php:/data/pear"|g' /etc/php5/apache2/php.ini
	sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini

	# Update the PHP.ini file, enable <? ?> tags and quiet logging.
	sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
	sed -i 's|;session.save_path = "/var/lib/php5"|session.save_path = "/tmp"|g' /etc/php5/apache2/php.ini
	sed -i 's|#ServerRoot "\/etc\/apache2"|ServerRoot "\/data\/apache2"|g' /etc/apache2/apache2.conf

	# Increase upload file limitations
	sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 1000M|g' /etc/php5/apache2/php.ini
	sed -i 's|post_max_size = 8M|post_max_size = 1000M|g' /etc/php5/apache2/php.ini

	# Allow the container to continuously update it's time
	echo "ntpdate ntp.ubuntu.com" > /etc/cron.daily/ntpdate && chmod 755 /etc/cron.daily/ntpdate

	# Add imagick extension
	echo "extension=imagick.so" >> /etc/php5/apache2/php.ini

	# Add build file to remove duplicate script execution
	echo 1 > /etc/php5/apache2/build

	if [[ ! -z "${NODE_ENVIRONMENT}" ]]; then

			if [ "$NODE_ENVIRONMENT" == 'dev' ]; then
					# Tweak Apache build
					sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=0 \nIS_DEV=0 \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php5/apache2/php.ini
					# Update the PHP.ini file, enable <? ?> tags and quiet logging.
					sed -i "s/error_reporting = .*$/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
			fi


			if [ "$NODE_ENVIRONMENT" == 'production' ]; then
					# Tweak Apache build
					sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=1 \nIS_DEV=0 \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php5/apache2/php.ini
					# Update the PHP.ini file, enable <? ?> tags and quiet logging.
					sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
			fi

	else
			# $NODE_ENVIRONMENT is not set on docker creation
			echo "env NODE_ENVIRONMENT is not set."
	fi
fi


if [[ ! -z "${LOG_TOKEN}" ]]; then
		# $LOG_TOKEN is not set on docker creation
		echo "env LOG_TOKEN is not set."
fi


# Postfix uses smart hosts in cluster to relay email
postconf -e "relayhost = [post-office.htmlgraphic.com]:25"
postconf -e "smtp_sasl_password_maps = static:${SASL_USER}:${SASL_PASS}"
postconf -e "inet_protocols = ipv4"

# Postfix is not using /etc/resolv.conf is because it is running inside a chroot jail, needs its own copy.
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
# mailname should match the system hostname
cp /etc/hostname /etc/mailname

# These are required when postfix runs chrooted
#
[[ -z $(ls /var/spool/postfix/etc) ]] && {
	for n in hosts localtime nsswitch.conf resolv.conf services
	do
			cp /etc/$n /var/spool/postfix/etc
	done
}

# These also need setgid to stop 'postfix check' worrying.
#
[[ -z $(find /usr/sbin/ -name postqueue -o -name postdrop -perm -2555) ]] && \
	chmod g+s /usr/sbin/post{drop,queue}


# Display system credentials for build testing
#
OutputLog


# Spin everything up
#
/usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
