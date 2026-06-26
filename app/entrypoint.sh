#!/bin/bash

# Logging function
OutputLog() {
    echo "=> Adding environmental variables:"
    echo "	NODE_ENVIRONMENT: ${NODE_ENVIRONMENT:-not set}"
    echo "	BUILD_ENV: ${BUILD_ENV:-not set}"
    echo "	LOG_TOKEN: $([ -n "${LOG_TOKEN}" ] && echo "set" || echo "not set")"
    echo "	MYSQL_USER: ${MYSQL_USER:-not set}"
    if [[ -z "${LOG_TOKEN}" ]]; then
	echo "	env LOG_TOKEN is not set."
    else
	echo "	Log Key: set"
    fi
    echo "	Postfix Outgoing SMTP (${SMTP_HOST:-not set}): $([ -n "${SASL_USER}" ] && echo "configured" || echo "not configured")"
}

# Clean up stale PIDs and sockets
echo "DEBUG: Cleaning up stale PIDs and sockets"
rm -f /var/run/apache2.pid /var/run/supervisord.pid /var/run/supervisor.sock /var/run/apache2/*.lock
if ps aux | grep -q '[a]pache2'; then
    echo "DEBUG: Found running Apache2 processes, stopping them"
    /usr/sbin/apache2ctl stop 2>/dev/null || true
    sleep 2
fi
if ps aux | grep -q '[s]upervisord'; then
    echo "DEBUG: Found running supervisord, stopping it"
    killall supervisord 2>/dev/null || true
    sleep 2
fi

# Create runtime directories
for dir in /run /var/log/supervisor /data/apache2/logs /data/apache2/sites-enabled /data/apache2/ssl /data/www/public_html /var/run/supervisor; do
    if [ ! -d "$dir" ]; then
        echo "DEBUG: Creating $dir/"
        mkdir -p "$dir"
    fi
    chown www-data:www-data "$dir"
    chmod 755 "$dir"
done

# Ensure log files are created
touch /var/log/supervisor/supervisord.log /var/log/supervisor/apache2.err.log /var/log/supervisor/apache2.out.log \
      /var/log/supervisor/postfix.err.log /var/log/supervisor/postfix.out.log /var/log/mail.log /var/log/syslog
chown www-data:www-data /var/log/supervisor/* /data/apache2/logs/*
chown syslog:syslog /var/log/mail.log /var/log/syslog
chmod 664 /var/log/supervisor/* /var/log/mail.log /var/log/syslog /data/apache2/logs/*

# Configure rsyslog
cat <<EOF > /etc/rsyslog.conf
$ModLoad imuxsock
$ModLoad imklog
$IncludeConfig /etc/rsyslog.d/*.conf
EOF
echo "*.* /var/log/syslog" > /etc/rsyslog.d/00-fallback.conf
echo "mail.* -/var/log/mail.log" > /etc/rsyslog.d/50-mail.conf
chmod 644 /etc/rsyslog.d/*.conf

# Move files if directories exist
if [ -d /data/www/public_html ]; then
    mv /opt/app/*.png /data/www/public_html/ 2>/dev/null || true
    mv /opt/app/*.php /data/www/public_html/ 2>/dev/null || true
fi
echo "DEBUG: Moving sample.conf to /data/apache2/sites-enabled/"
ls -la /opt/app/sample.conf 2>/dev/null || echo "No sample.conf found in /opt/app/"
mv /opt/app/sample.conf /data/apache2/sites-enabled/ 2>/dev/null || true
rm -f /data/apache2/sites-enabled/.DS_Store
echo "DEBUG: Contents of /data/apache2/sites-enabled/:"
ls -la /data/apache2/sites-enabled/

# Generate self-signed SSL certificate
echo "DEBUG: Generating self-signed SSL certificate for localhost"
rm -f /data/apache2/ssl/ssl-cert-snakeoil.*
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /data/apache2/ssl/ssl-cert-snakeoil.key \
    -out /data/apache2/ssl/ssl-cert-snakeoil.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:127.0.0.1" \
    -addext "basicConstraints=CA:FALSE"
chown www-data:www-data /data/apache2/ssl/*
chmod 600 /data/apache2/ssl/*
echo "DEBUG: Contents of /data/apache2/ssl/:"
ls -la /data/apache2/ssl/

# Ensure Apache2 PID file in config
echo "PidFile /var/run/apache2.pid" > /etc/apache2/conf-available/pid.conf
a2enconf pid 2>/dev/null || true

# PHP environment tweaks
if [ ! -f /etc/php/8.3/build ]; then
    if [[ -n "${NODE_ENVIRONMENT}" ]]; then
        if [ "$NODE_ENVIRONMENT" = "dev" ]; then
            echo -e "\nIS_LIVE=0\nIS_DEV=1\nNODE_ENVIRONMENT=dev" >> /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.3/apache2/php.ini || echo "error_reporting = E_ALL" >> /etc/php/8.3/apache2/php.ini
            sed -i 's|log_errors_max_len = .*|log_errors_max_len = 0|' /etc/php/8.3/apache2/php.ini || echo "log_errors_max_len = 0" >> /etc/php/8.3/apache2/php.ini
        elif [ "$NODE_ENVIRONMENT" = "production" ]; then
            echo -e "\nIS_LIVE=1\nIS_DEV=0\nNODE_ENVIRONMENT=production" >> /etc/php/8.3/apache2/php.ini
            sed -i 's/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/' /etc/php/8.3/apache2/php.ini || echo "error_reporting = E_ERROR | E_WARNING | E_PARSE" >> /etc/php/8.3/apache2/php.ini
        fi
    fi
    echo 1 > /etc/php/8.3/build
fi

# Verify and fix PHP CLI settings
echo "DEBUG: Verifying PHP CLI settings"
if ! grep -q 'max_execution_time = 300' /etc/php/8.3/cli/php.ini; then
    echo "DEBUG: Fixing max_execution_time in CLI php.ini"
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/8.3/cli/php.ini || echo "max_execution_time = 300" >> /etc/php/8.3/cli/php.ini
fi
if ! grep -q 'max_input_time = 300' /etc/php/8.3/cli/php.ini; then
    echo "DEBUG: Fixing max_input_time in CLI php.ini"
    sed -i 's/max_input_time = .*/max_input_time = 300/' /etc/php/8.3/cli/php.ini || echo "max_input_time = 300" >> /etc/php/8.3/cli/php.ini
fi

# Postfix runtime setup
if [[ -n "${SMTP_HOST}" && -n "${SASL_USER}" && -n "${SASL_PASS}" ]]; then
    echo "DEBUG: Configuring Postfix with SMTP_HOST=${SMTP_HOST}"
    printf '[%s]:587 %s:%s\n' "${SMTP_HOST}" "${SASL_USER}" "${SASL_PASS}" > /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd.db
    postconf -e "relayhost=[${SMTP_HOST}]:587" \
	"smtp_sasl_auth_enable=yes" \
	"smtp_sasl_security_options=noanonymous" \
	"smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd" \
	"smtp_tls_security_level=encrypt" \
	"smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt" \
	"compatibility_level=3.6"
    cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf 2>/dev/null || true
    for n in hosts localtime nsswitch.conf resolv.conf services; do
        cp /etc/$n /var/spool/postfix/etc 2>/dev/null || true
    done
    chmod g+s /usr/sbin/post{drop,queue} 2>/dev/null || true
else
    echo "SMTP configuration incomplete, skipping postfix setup"
fi

# Log environment
OutputLog

# Export environment variables
env | grep NODE_ENVIRONMENT >> /etc/environment

# Create supervisord configuration
cat <<EOF > /etc/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700
chown=www-data:www-data

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[program:apache2]
command=/usr/sbin/apache2 -DFOREGROUND -DNO_DETACH
autostart=true
autorestart=true
user=root
startsecs=15
startretries=5
stopwaitsecs=10
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/supervisor/apache2.err.log
stdout_logfile=/var/log/supervisor/apache2.out.log
environment=APACHE_RUN_USER="www-data",APACHE_RUN_GROUP="www-data",APACHE_PID_FILE="/var/run/apache2.pid"
stopsignal=TERM

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

# Debug Apache2 startup
echo "DEBUG: Ensuring no stale Apache2 PID or lock files"
rm -f /var/run/apache2.pid /var/run/apache2/*.lock
ls -l /var/run/apache2/ 2>/dev/null || echo "No Apache2 PID/lock directory"
echo "DEBUG: Checking port usage"
netstat -tulnp | grep -E ':80|:443' || echo "No processes using ports 80/443"
echo "DEBUG: Checking Apache2 configuration"
apache2ctl configtest || { echo "ERROR: Apache2 config test failed"; cat /data/apache2/logs/error_log; exit 1; }
echo "DEBUG: Verifying SSL certificates"
ls -l /data/apache2/ssl/ssl-cert-snakeoil.* || echo "WARNING: SSL certificates missing"
echo "DEBUG: Checking /data/www/public_html permissions"
stat /data/www/public_html || echo "ERROR: /data/www/public_html not accessible"
echo "DEBUG: Supervisord config contents:"
cat /etc/supervisord.conf
echo "DEBUG: Checking supervisord socket"
ls -l /var/run/supervisor.sock 2>/dev/null || echo "No supervisord socket yet"
echo "DEBUG: Checking for running Apache2 processes"
ps aux | grep '[a]pache2' || echo "No Apache2 processes running"

# Start supervisord
echo "DEBUG: Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
