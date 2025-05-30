#!/bin/bash

# Logging function
OutputLog() {
    echo "=> Adding environmental variables:"
    echo "	NODE_ENVIRONMENT: ${NODE_ENVIRONMENT:-not set}"
    echo "	BUILD_ENV: ${BUILD_ENV:-not set}"
    echo "	LOG_TOKEN: ${LOG_TOKEN:-not set}"
    echo "	MYSQL_USER: ${MYSQL_USER:-not set}"
    echo "	NODE_ENVIRONMENT: ${NODE_ENVIRONMENT}"
    if [[ -z "${LOG_TOKEN}" ]]; then
        echo "	env LOG_TOKEN is not set."
    else
        echo "	Log Key: ${LOG_TOKEN}"
    fi
    echo "	Postfix Outgoing SMTP (${SMTP_HOST}): ${SASL_USER}:${SASL_PASS}"
}

# Logging setup
if [[ -n "${LOG_TOKEN}" ]]; then
    cat <<EOF > /etc/rsyslog.d/logentries.conf
\$template Logentries,"${LOG_TOKEN} %HOSTNAME% %syslogtag%%msg%\n"
*.* @@api.logentries.com:10000;Logentries
EOF
fi

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
if [ ! -f /etc/php/8.3/build ]; then
    if [[ -n "${NODE_ENVIRONMENT}" ]]; then
        if [ "$NODE_ENVIRONMENT" = "dev" ]; then
            echo -e "\nIS_LIVE=0\nIS_DEV=1\nNODE_ENVIRONMENT=dev\n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld" >> /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.3/apache2/php.ini || echo "error_reporting = E_ALL" >> /etc/php/8.3/apache2/php.ini
            sed -i 's|log_errors_max_len = .*|log_errors_max_len = 0|' /etc/php/8.3/apache2/php.ini || echo "log_errors_max_len = 0" >> /etc/php/8.3/apache2/php.ini
        elif [ "$NODE_ENVIRONMENT" = "production" ]; then
            echo -e "\nIS_LIVE=1\nIS_DEV=0\nNODE_ENVIRONMENT=production\n;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld" >> /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/' /etc/php/8.3/apache2/php.ini || echo "error_reporting = E_ERROR | E_WARNING | E_PARSE" >> /etc/php/8.3/apache2/php.ini
        fi
    fi
    echo 1 > /etc/php/8.3/build
fi

# Postfix runtime setup
if [[ -n "${SMTP_HOST}" && -n "${SASL_USER}" && -n "${SASL_PASS}" ]]; then
    postconf -e "relayhost=[${SMTP_HOST}]:587" \
        "smtp_sasl_password_maps=static:${SASL_USER}:${SASL_PASS}"
else
    echo "SMTP configuration incomplete, skipping postfix setup"
    exit 0
fi
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf 2>/dev/null || true
for n in hosts localtime nsswitch.conf resolv.conf services; do
    cp /etc/$n /var/spool/postfix/etc 2>/dev/null || true
done
chmod g+s /usr/sbin/post{drop,queue} 2>/dev/null || true

# Log environment
OutputLog

# Export environment variables
env | grep NODE_ENVIRONMENT >> /etc/environment

# Start supervisord for other services
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

# Start Apache in foreground
exec /usr/sbin/apache2ctl -D FOREGROUND
