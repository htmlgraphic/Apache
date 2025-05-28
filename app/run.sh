#!/bin/bash

OutputLog() {
    echo "=> Adding environmental variables:"
    echo "	NODE_ENVIRONMENT: ${NODE_ENVIRONMENT}"
    if [[ -z "${LOG_TOKEN}" ]]; then
        echo "	env LOG_TOKEN is not set."
    else
        echo "	Log Key: ${LOG_TOKEN}"
    fi
    echo "	Postfix Outgoing SMTP (${SMTP_HOST}): ${SASL_USER}:${SASL_PASS}"
}

# Logging setup
cat <<EOF > /etc/rsyslog.d/logentries.conf
\$template Logentries,"${LOG_TOKEN} %HOSTNAME% %syslogtag%%msg%\n"
*.* @@api.logentries.com:10000;Logentries
EOF

# Move files if directories exist
if [ -d /data/www/public_html ]; then
    mv /opt/app/*.png /data/www/public_html/ 2>/dev/null || true
    mv /opt/app/*.php /data/www/public_html/ 2>/dev/null || true
fi

if [ -d /data/apache2 ]; then
    mv /opt/app/*.conf /data/apache2/sites-enabled/ 2>/dev/null || true
    mv -f /opt/app/ssl/* /data/apache2/ssl/ 2>/dev/null || true
fi

# PHP environment tweaks
if [ ! -f /etc/php/8.3/apache2/build ]; then
    if [[ -n "${NODE_ENVIRONMENT}" ]]; then
        if [ "$NODE_ENVIRONMENT" == 'dev' ]; then
            sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=0 \nIS_DEV=1 \nNODE_ENVIRONMENT=dev \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.3/apache2/php.ini
            sed -i 's|log_errors_max_len = 1024|log_errors_max_len = 0|g' /etc/php/8.3/apache2/php.ini
        elif [ "$NODE_ENVIRONMENT" == 'production' ]; then
            sed -i 's|\[PHP\]|\[PHP\] \nIS_LIVE=1 \nIS_DEV=0 \nNODE_ENVIRONMENT=production \n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/' /etc/php/8.3/apache2/php.ini
        fi
    fi
    echo 1 > /etc/php/8.3/apache2/build
fi

# Postfix setup
postconf -e "compatibility_level=2" \
    "myhostname=dev-build.htmlgraphic.com" \
    "mail_spool_directory=/var/spool/mail/" \
    "mydestination=localhost.localdomain localhost" \
    "relayhost=[${SMTP_HOST}]:587" \
    "smtp_sasl_auth_enable=yes" \
    "smtp_sasl_password_maps=static:${SASL_USER}:${SASL_PASS}" \
    "smtp_sasl_security_options=noanonymous" \
    "smtp_sasl_tls_security_options=noanonymous" \
    "smtp_tls_security_level=encrypt" \
    "header_size_limit=4096000" \
    "inet_protocols=ipv4"
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
cp /etc/hostname /etc/mailname
for n in hosts localtime nsswitch.conf resolv.conf services; do
    cp /etc/$n /var/spool/postfix/etc 2>/dev/null || true
done
chmod g+s /usr/sbin/post{drop,queue} 2>/dev/null || true

# Log environment
OutputLog

# Export environment variables
env | grep NODE_ENVIRONMENT >> /etc/environment

# Execute CMD
exec "$@"
