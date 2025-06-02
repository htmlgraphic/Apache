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

# Clean up stale PIDs and processes
echo "DEBUG: Cleaning up stale PIDs and processes"
rm -f /var/run/apache2/apache2.pid /var/run/supervisord.pid /var/run/supervisor.sock
pkill -9 apache2 2>/dev/null || true
pkill -9 supervisord 2>/dev/null || true

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
$ModLoad imuxsock
$ModLoad imklog
$IncludeConfig /etc/rsyslog.d/*.conf
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
echo "DEBUG: Moving sample.conf from /opt/app/ to /data/apache2/sites-enabled/"
ls -la /opt/app/sample.conf 2>/dev/null || echo "No sample.conf found in /opt/app/"
mv /opt/app/sample.conf /data/apache2/sites-enabled/ 2>/dev/null || true
# Clean up .DS_Store files
rm -f /data/apache2/sites-enabled/.DS_Store
echo "DEBUG: Contents of /data/apache2/sites-enabled/:"
ls -la /data/apache2/sites-enabled/

# Generate self-signed SSL certificate
echo "DEBUG: Generating self-signed SSL certificate for domain.com"
rm -f /data/apache2/ssl/ssl-cert-snakeoil.*
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /data/apache2/ssl/ssl-cert-snakeoil.key \
    -out /data/apache2/ssl/ssl-cert-snakeoil.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=domain.com" \
    -addext "subjectAltName=DNS:domain.com,DNS:www.domain.com" \
    -addext "basicConstraints=CA:FALSE"
chown www-data:www-data /data/apache2/ssl/*
chmod 600 /data/apache2/ssl/*
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

# Verify and fix PHP CLI settings
echo "DEBUG: Verifying PHP CLI settings"
grep -E 'max_execution_time|max_input_time' /etc/php/8.3/cli/php.ini
if ! grep -q 'max_execution_time = 300' /etc/php/8.3/cli/php.ini; then
    echo "DEBUG: Fixing max_execution_time in CLI php.ini"
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.3/cli/php.ini || echo "max_execution_time = 300" >> /etc/php/8.3/cli/php.ini
fi
if ! grep -q 'max_input_time = 300' /etc/php/8.3/cli/php.ini; then
    echo "DEBUG: Fixing max_input_time in CLI php.ini"
    sed -i 's/max_input_time = .*/max_input_time = 300/' /etc/php/8.3/cli/php.ini || echo "max_input_time = 300" >> /etc/php/8.3/cli/php.ini
fi
echo "DEBUG: Post-fix PHP CLI settings"
grep -E 'max_execution_time|max_input_time' /etc/php/8.3/cli/php.ini

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

# Ensure supervisord socket directory exists
mkdir -p /var/run/supervisor
chown www-data:www-data /var/run/supervisor
chmod 755 /var/run/supervisor

# Create supervisord configuration
echo "DEBUG: Creating supervisord configuration"
cat <<EOF > /etc/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
loglevel=debug

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700
chown=www-data:www-data

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:apache2]
command=/usr/sbin/apache2ctl -D FOREGROUND
autostart=true
autorestart=true
user=root
startsecs=10
startretries=3
stopwaitsecs=10
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/supervisor/apache2.err.log
stdout_logfile=/var/log/supervisor/apache2.out.log

[program:postfix]
command=/usr/sbin/postfix start-fg
autostart=true
autorestart=true
user=root
startsecs=10
startretries=3
stopwaitsecs=10
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/supervisor/postfix.err.log
stdout_logfile=/var/log/supervisor/postfix.out.log
EOF
chmod 644 /etc/supervisord.conf

# Verify supervisord config
SUPERVISORD_CONF="/etc/supervisord.conf"
echo "DEBUG: Verifying supervisord config at $SUPERVISORD_CONF"
if [ -f "$SUPERVISORD_CONF" ]; then
    ls -l "$SUPERVISORD_CONF"
    cat "$SUPERVISORD_CONF"
else
    echo "ERROR: Supervisord config $SUPERVISORD_CONF not found"
    exit 1
fi

# Test Apache configuration
echo "DEBUG: Testing Apache configuration"
/usr/sbin/apache2ctl configtest || {
    echo "ERROR: Apache configuration test failed"
    cat /var/log/apache2/error.log
    exit 1
}

# Start supervisord with error trapping
echo "DEBUG: Starting supervisord..."
set -e
exec /usr/bin/supervisord -c "$SUPERVISORD_CONF" || {
    echo "ERROR: Supervisord failed to start"
    cat /var/log/supervisor/supervisord.log
    exit 1
}
