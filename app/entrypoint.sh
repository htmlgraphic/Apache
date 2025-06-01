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

# # Logging setup
# if [[ -n "${LOG_TOKEN}" ]]; then
#     cat <<EOF > /etc/rsyslog.d/logentries.conf
# \$template Logentries,"${LOG_TOKEN} %HOSTNAME% %syslogtag%%msg%\n"
# *.* @@api.logentries.com:10000;Logentries
# EOF
# fi

# Create runtime directories
for dir in /run /var/log /var/log/supervisor /data/apache2/logs /data/apache2/sites-enabled /data/apache2/ssl /data/www/public_html /var/run/supervisor; do
    if [ ! -d "$dir" ]; then
        echo "DEBUG: Creating $dir/"
        mkdir -p "$dir"
    fi
    chown www-data:www-data "$dir"
    chmod 755 "$dir"
done

# Ensure log files are created
touch /var/log/supervisor/supervisord.log /var/log/supervisor/crond.log /var/log/supervisor/crond.err \
      /var/log/supervisor/rsyslog.log /var/log/supervisor/rsyslog.err /var/log/postfix.log \
      /var/log/supervisor/postfix.err /var/log/mail.log /var/log/syslog /var/log/kern.log /var/log/messages
chown syslog:syslog /var/log/supervisor/* /var/log/postfix.log /var/log/mail.log /var/log/syslog /var/log/kern.log /var/log/messages
chmod 664 /var/log/supervisor/* /var/log/postfix.log /var/log/mail.log /var/log/syslog /var/log/kern.log /var/log/messages

# Configure rsyslog
cat <<EOF > /etc/rsyslog.conf
\$ModLoad imuxsock
\$ModLoad imklog
\$IncludeConfig /etc/rsyslog.d/*.conf
EOF
echo "*.* /var/log/messages" > /etc/rsyslog.d/00-fallback.conf
echo "kern.* /var/log/kern.log" > /etc/rsyslog.d/50-kern.conf
echo "mail.* -/var/log/mail.log" > /etc/rsyslog.d/50-mail.conf
chmod 644 /etc/rsyslog.d/*.conf

# Move files if directories exist
if [ -d /data/www/public_html ]; then
    mv /opt/app/*.png /data/www/public_html/ 2>/dev/null || true
    mv /opt/app/*.php /data/www/public_html/ 2>/dev/null || true
fi
echo "DEBUG: Moving .conf files from /opt/app/ to /data/apache2/sites-enabled/"
ls -la /opt/app/*.conf 2>/dev/null || echo "No .conf files found in /opt/app/"
mv /opt/app/*.conf /data/apache2/sites-enabled/ 2>/dev/null || true
echo "DEBUG: Contents of /data/apache2/sites-enabled/:"
ls -la /data/apache2/sites-enabled/

# Generate self-signed SSL certificate if none exists
if [ -z "$(ls -A /data/apache2/ssl)" ]; then
    echo "DEBUG: Generating self-signed SSL certificate"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /data/apache2/ssl/ssl-cert-snakeoil.key \
        -out /data/apache2/ssl/ssl-cert-snakeoil.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
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
        "smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt" \
        "compatibility_level=3.6"
    echo "DEBUG: Postfix configuration completed"
else
    echo "SMTP configuration incomplete, skipping postfix setup"
fi
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf 2>/dev/null || true
for n in hosts localtime nsswitch.conf resolv.conf services; do
    cp /etc/$n /var/spool/postfix/etc 2>/dev/null || true
done
chmod g+s /usr/sbin/post{drop,queue} 2>/dev/null || true

# Configure rsyslog for mail logs
echo "mail.* -/var/log/mail.log" > /etc/rsyslog.d/50-mail.conf
chmod 644 /etc/rsyslog.d/50-mail.conf

# Log environment
OutputLog

# Export environment variables
env | grep NODE_ENVIRONMENT >> /etc/environment

# Check for supervisord config file
SUPERVISORD_CONF="/etc/supervisor/conf.d/services.conf"
if [ ! -f "$SUPERVISORD_CONF" ]; then
    echo "DEBUG: /etc/supervisor/conf.d/services.conf not found, checking /app/supervisord"
    if [ -f "/app/supervisord" ]; then
        echo "DEBUG: Copying /app/supervisord to /etc/supervisor/conf.d/services.conf"
        cp /app/supervisord /etc/supervisor/conf.d/services.conf
    elif [ -f "/app/supervisord.conf" ]; then
        echo "DEBUG: Copying /app/supervisord.conf to /etc/supervisor/conf.d/services.conf"
        cp /app/supervisord.conf /etc/supervisor/conf.d/services.conf
    else
        echo "ERROR: Supervisord config file not found at /etc/supervisor/conf.d/services.conf, /app/supervisord, or /app/supervisord.conf"
        exit 1
    fi
fi
echo "DEBUG: Using supervisord config at $SUPERVISORD_CONF"
ls -l "$SUPERVISORD_CONF"

# Ensure supervisord socket directory exists
mkdir -p /var/run/supervisor
chown www-data:www-data /var/run/supervisor
chmod 755 /var/run/supervisor

# Start supervisord
echo "DEBUG: Starting supervisord..."
/usr/bin/supervisord -c "$SUPERVISORD_CONF" &
SUPERVISORD_PID=$!
sleep 15
if ! ps -p $SUPERVISORD_PID > /dev/null; then
    echo "ERROR: supervisord failed to start, but continuing"
    cat /var/log/supervisor/supervisord.log
    # tail -f /dev/null
fi
echo "DEBUG: supervisord started with PID $SUPERVISORD_PID"

# Check for supervisord socket
if [ ! -S /var/run/supervisor.sock ]; then
    echo "ERROR: Supervisord socket /var/run/supervisor.sock missing, but continuing"
    cat /var/log/supervisor/supervisord.log
    # tail -f /dev/null
fi
echo "DEBUG: Supervisord socket /var/run/supervisor.sock created"

# Check supervisord status
echo "DEBUG: Checking supervisord status..."
/usr/bin/supervisorctl -c "$SUPERVISORD_CONF" status || {
    echo "ERROR: Failed to run supervisorctl status, but continuing"
    cat /var/log/supervisor/supervisord.log
    # tail -f /dev/null
}

# Start Apache in foreground
echo "DEBUG: Starting Apache..."
/usr/sbin/apache2ctl -D FOREGROUND || {
    echo "ERROR: Apache failed to start"
    apache2ctl configtest
    tail -f /dev/null
}
