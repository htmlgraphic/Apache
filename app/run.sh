#!/bin/bash

OutputLog ()
{
	echo "=> Adding environmental variables:"
	echo "	NODE_ENVIRONMENT: ${NODE_ENVIRONMENT}"

	if [[ -z "${LOG_TOKEN}" ]]; then
		# $LOG_TOKEN is set on container creation
		echo "	env LOG_TOKEN is not set."
	else
		echo "	Log Key: ${LOG_TOKEN}"
	fi

	echo "	Postfix Outgoing SMTP (${SMTP_HOST}): ${SASL_USER}:${SASL_PASS}"
}





# output logs to logentries.com
cat <<EOF > /etc/rsyslog.d/logentries.conf
\$template Logentries,"${LOG_TOKEN} %HOSTNAME% %syslogtag%%msg%\n"

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
	mkdir -p /data/apache2/{logs,ssl,sites-enabled}

	# Create diectory for any pear libaries
	mkdir -p /data/pear
	touch /data/pear/empty

	# Strict permissions on Apache conf files
	cd /etc/apache2/ && chmod 700 *

	# Set the 'ServerName' directive globally
	echo ServerName localhost >> /etc/apache2/conf-enabled/servername.conf

	# Customizable Apache configuration file(s)
	mv /opt/app/*.conf /data/apache2/sites-enabled/

	# Move needed certificates into place
	mv -f /opt/app/ssl/* /data/apache2/ssl

	# Disable the default website
	rm /etc/apache2/sites-enabled/000-default.conf

fi



#####
#
#  Edit files on the container, improving preformance
#  Modify php.ini for each build
#  Check for proper environment
#  Route mail to SMTP queuing servers
#
#####
if [ ! -f /etc/php/7.3/apache2/build ]; then

	# Tweak Apache build
	sed -i 's|;include_path = ".:/usr/share/php"|include_path = ".:/usr/share/php:/data/pear"|g' /etc/php/7.3/apache2/php.ini
	sed -i 's/variables_order.*/variables_order = \"EGPCS\"/g' /etc/php/7.3/apache2/php.ini
	sed -i 's/IncludeOptional sites-enabled\/\*.conf/IncludeOptional \/data\/apache2\/sites-enabled\/*.conf/' /etc/apache2/apache2.conf
	sed -i 's|;error_log = php_errors.log|error_log = /data/apache2/logs/error_log|g' /etc/php/7.3/apache2/php.ini

	# Update the PHP.ini file, enable <? ?> tags and quiet logging.
	sed -i 's|short_open_tag = Off|short_open_tag = On|g' /etc/php/7.3/apache2/php.ini

	# Sessions & garbage collection
	sed -i 's|;session.save_path = "/var/lib/php5"|session.save_path = "/tmp"|g' /etc/php/7.3/apache2/php.ini
	sed -i 's|session.gc_probability = 0|session.gc_probability = 1|g' /etc/php/7.3/apache2/php.ini

	# Update Apache / PHP Config
	sed -i 's|max_execution_time = 30|max_execution_time = 300|g' /etc/php/7.3/apache2/php.ini
	sed -i 's|memory_limit = 128M|memory_limit = -1|g' /etc/php/7.3/apache2/php.ini
	sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 1000M|g' /etc/php/7.3/apache2/php.ini
	sed -i 's|post_max_size = 8M|post_max_size = 1000M|g' /etc/php/7.3/apache2/php.ini
	sed -i 's|max_input_time = 60|max_input_time = 300|g' /etc/php/7.3/apache2/php.ini
	
	# Update CLI Config
	sed -i 's|memory_limit = 128M|memory_limit = -1|g' /etc/php/7.3/cli/php.ini
	sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 1000M|g' /etc/php/7.3/cli/php.ini
	sed -i 's|post_max_size = 8M|post_max_size = 1000M|g' /etc/php/7.3/cli/php.ini


	# Add build file to remove duplicate script execution
	echo 1 > /etc/php/7.3/apache2/build

	if [[ -z "${NODE_ENVIRONMENT}" ]]; then
			# $NODE_ENVIRONMENT is set on container creation
			echo "	env NODE_ENVIRONMENT is not set, Apache is not configured correctly."
	else
		if [ "$NODE_ENVIRONMENT" == 'dev' ]; then
			# Tweak Apache build
			sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=0 \nIS_DEV=0 \nNODE_ENVIRONMENT=dev \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php/7.3/apache2/php.ini
			# Update the PHP.ini file, enable <? ?> tags and quiet logging.
			sed -i "s/error_reporting = .*$/error_reporting = E_ALL/" /etc/php/7.3/apache2/php.ini
		fi

		if [ "$NODE_ENVIRONMENT" == 'production' ]; then
			# Tweak Apache build
			sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=1 \nIS_DEV=0 \nNODE_ENVIRONMENT=production \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php/7.3/apache2/php.ini
			# Update the PHP.ini file, enable <? ?> tags and quiet logging.
			sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.3/apache2/php.ini
		fi

	fi
fi


# SSH - Add public key for root access
if [ "${AUTHORIZED_KEYS}" != "**None**" ]; then
	echo "=> Found authorized keys"
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh
	touch /root/.ssh/authorized_keys
	chmod 600 /root/.ssh/authorized_keys
	IFS=$'\n'
	arr=$(echo ${AUTHORIZED_KEYS} | tr "," "\n")
	for x in $arr
	do
		x=$(echo $x |sed -e 's/^ *//' -e 's/ *$//')
		cat /root/.ssh/authorized_keys | grep "$x" >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "=> Adding public key to /root/.ssh/authorized_keys: $x"
			echo "$x" >> /root/.ssh/authorized_keys
		fi
	done
fi

# Postfix uses a DEV test mail server which holds email(s) from being released into the REAL Internet
postconf -e "compatibility_level=2"
postconf -e "myhostname=dev-build.htmlgraphic.com"
postconf -e 'mail_spool_directory="/var/spool/mail/"'
postconf -e 'mydestination="localhost.localdomain localhost"'
postconf -e "mydomain=htmlgraphic.com"
postconf -e "relayhost=[${SMTP_HOST}]:587"
postconf -e "smtp_sasl_auth_enable=yes"
postconf -e "smtp_sasl_password_maps=static:${SASL_USER}:${SASL_PASS}"
postconf -e "smtp_sasl_security_options=noanonymous"
postconf -e "smtp_tls_security_level=encrypt"
postconf -e "header_size_limit=4096000"
postconf -e "inet_protocols=ipv4"

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
# http://stackoverflow.com/questions/34630571/docker-env-variables-not-set-while-log-via-shell
env | grep NODE_ENVIRONMENT >> /etc/environment && /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
#/bin/bash -c env | grep NODE_ENVIRONMENT >> /etc/environment && /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
