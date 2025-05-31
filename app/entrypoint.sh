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
if [ ! -d /data/apache2/sites-enabled ]; then
    echo "DEBUG: Creating /data/apache2/sites-enabled/"
    mkdir -p /data/apache2/sites-enabled
fi
echo "DEBUG: Moving .conf files from /opt/app/ to /data/apache2/sites-enabled/"
ls -la /opt/app/*.conf 2>/dev/null || echo "No .conf files found in /opt/app/"
mv /opt/app/*.conf /data/apache2/sites-enabled/ 2>/dev/null || true
echo "DEBUG: Contents of /data/apache2/sites-enabled/:"
ls -la /data/apache2/sites-enabled/

# Generate self-signed SSL certificate if none exists
if [ ! -d /data/apache2/ssl ] || [ -z "$(ls -A /data/apache2/ssl)" ]; then
    echo "DEBUG: Generating self-signed SSL certificate"
    mkdir -p /data/apache2/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /data/apache2/ssl/ssl-cert-snakeoil.key \
        -out /data/apache2/ssl/ssl-cert-snakeoil.pem \
        -subj "/C=US/ST=CO/L=Boulder/O=HTMLgraphic/CN=localhost"
    chown www-data:www-data /data/apache2/ssl/*
    chmod 600 /data/apache2/ssl/*
fi
mv -f /opt/app/ssl/* /data/apache2/ssl/ 2>/dev/null || true
echo "DEBUG: Contents of /data/apache2/ssl/:"
ls -la /data/apache2/ssl/

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

# Debug SMTP variables
echo "DEBUG: SMTP_HOST=${SMTP_HOST:-not set}"
echo "DEBUG: SASL_USER=${SASL_USER:-not set}"
echo "DEBUG: SASL_PASS=${SASL_PASS:-not set}"

# Postfix runtime setup
if [[ -n "${SMTP_HOST}" && -n "${SASL_USER}" && -n "${SASL_PASS}" ]]; then
    echo "DEBUG: Configuring Postfix with SMTP_HOST=${SMTP_HOST}"
    postconf -e "relayhost=[${SMTP_HOST}]:587" \
        "smtp_sasl_auth_enable=yes" \
        "smtp_sasl_security_options=noanonymous" \
        "smtp_sasl_password_maps=static:${SASL_USER}:${SASL_PASS}" \
        "smtp_tls_security_level=encrypt" \
        "smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt"
    echo "DEBUG: Postfix configuration completed"
else
    echo "SMTP configuration incomplete, skipping postfix setup"
fi
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf 2>/dev/null || true
for n in hosts localtime nsswitch.conf resolv.conf services; do
    cp /etc/$n /var/spool/postfix/etc 2>/dev/null || true
done
chmod g+s /usr/sbin/post{drop,queue} 2>/dev/null || true

# Set up Supervisor log directory
mkdir -p /var/log/supervisor
chown www-data:www-data /var/log/supervisor
chmod 755 /var/log/supervisor

# Configure rsyslog for mail logs
echo "mail.* -/var/log/mail.log" > /etc/rsyslog.d/50-mail.conf
chmod 644 /etc/rsyslog.d/50-mail.conf

# Log environment
OutputLog

# Export environment variables
env | grep NODE_ENVIRONMENT >> /etc/environment

# Start supervisord for other services
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

# Start Apache in foreground
exec /usr/sbin/apache2ctl -D FOREGROUND
