# Base Image
FROM ubuntu:24.04

# Metadata
LABEL org.label-schema.name="Apache Docker" \
      org.label-schema.description="Docker container running Apache on Ubuntu with Composer, Laravel, TDD via Shippable & CircleCI" \
      org.label-schema.url="https://htmlgraphic.com" \
      org.label-schema.vcs-url="https://github.com/htmlgraphic/Apache" \
      org.label-schema.vendor="HTMLgraphic, LLC" \
      org.label-schema.schema-version="1.0"

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    OS_LOCALE="en_US.UTF-8" \
    LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2

# Install libssl1.1 for ARM64 and initial dependencies
RUN apt-get update && apt-get install -y \
        curl \
        wget && \
    wget -qO /tmp/libssl1.1.deb http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_arm64.deb && \
    dpkg -i /tmp/libssl1.1.deb && \
    rm -f /tmp/libssl1.1.deb && \
    apt-get install -y \
        locales \
        software-properties-common \
        libmcrypt-dev && \
    locale-gen ${OS_LOCALE}

# Add PHP PPA and install additional dependencies
RUN add-apt-repository -y ppa:ondrej/php && \
    apt-get update && apt-get install -y \
        curl \
        unzip \
        p7zip-full \
        apache2 \
        libsasl2-modules \
        libapache2-mod-php8.3 \
        php-pear \
        php8.3 \
        php8.3-cli \
        php8.3-bz2 \
        php8.3-curl \
        php8.3-mbstring \
        php8.3-intl \
        php8.3-fpm \
        php8.3-dev \
        php8.3-xml \
        php8.3-common \
        php8.3-redis \
        libxml2-dev \
        libssl-dev \
        zlib1g-dev \
        git \
        cron \
        ghostscript \
        mailutils \
        iputils-ping \
        mysql-client \
        libgs-dev \
        imagemagick \
        php8.3-imagick \
        libmagickwand-dev \
        language-pack-en \
        supervisor \
        rsyslog \
        vim \
        postfix \
        netcat-openbsd \
        dnsutils \
        python3 \
        gyp \
        wkhtmltopdf \
        fontconfig \
        libjpeg-turbo8 \
        xfonts-75dpi \
        xfonts-base && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Mcrypt Extension
RUN pecl install mcrypt && \
    echo "extension=mcrypt.so" > /etc/php/8.3/mods-available/mcrypt.ini && \
    ln -s /etc/php/8.3/mods-available/mcrypt.ini /etc/php/8.3/apache2/conf.d/20-mcrypt.ini && \
    ln -s /etc/php/8.3/mods-available/mcrypt.ini /etc/php/8.3/cli/conf.d/20-mcrypt.ini

# Configure Redis Extension (already installed via php8.3-redis)
RUN echo "extension=redis.so" > /etc/php/8.3/mods-available/redis.ini && \
    ln -s /etc/php/8.3/mods-available/redis.ini /etc/php/8.3/apache2/conf.d/20-redis.ini && \
    ln -s /etc/php/8.3/mods-available/redis.ini /etc/php/8.3/cli/conf.d/20-redis.ini

# Enable Apache Modules
RUN a2enmod userdir rewrite ssl

# Apache Configuration
RUN mkdir -p /data/apache2/{logs,ssl,sites-enabled} && \
    a2ensite default-ssl && \
    echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && \
    a2enconf servername && \
    sed -i 's|IncludeOptional sites-enabled/\*.conf|IncludeOptional /data/apache2/sites-enabled/*.conf|' /etc/apache2/apache2.conf && \
    echo "<IfModule mpm_event_module>\nStartServers 2\nMinSpareThreads 25\nMaxSpareThreads 75\nThreadLimit 64\nThreadsPerChild 25\nMaxRequestWorkers 150\nMaxConnectionsPerChild 0\n</IfModule>" >> /etc/apache2/apache2.conf && \
    echo "<VirtualHost *:80>\nServerName localhost\nDocumentRoot /var/www/html\nErrorLog \${APACHE_LOG_DIR}/error.log\nCustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>" > /data/apache2/sites-enabled/000-default.conf && \
    echo "<VirtualHost *:443>\nServerName localhost\nDocumentRoot /var/www/html\nErrorLog \${APACHE_LOG_DIR}/error.log\nCustomLog \${APACHE_LOG_DIR}/access.log combined\nSSLEngine on\nSSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem\nSSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key\n</VirtualHost>" > /data/apache2/sites-enabled/default-ssl.conf

# Postfix Configuration
RUN postconf -e "compatibility_level=2" \
    "myhostname=localhost.localdomain" \
    "mail_spool_directory=/var/spool/mail/" \
    "mydestination=localhost.localdomain localhost" \
    "smtp_sasl_auth_enable=yes" \
    "smtp_sasl_security_options=noanonymous" \
    "smtp_sasl_tls_security_options=noanonymous" \
    "smtp_tls_security_level=may" \
    "header_size_limit=4096000" \
    "inet_protocols=ipv4" && \
    cp /etc/hostname /etc/mailname

# Install wkhtmltox
RUN wget -qO /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.noble_arm64.deb || \
    echo "wkhtmltox not available for ARM64, skipping" && \
    if [ -f /tmp/wkhtmltox.deb ]; then \
        dpkg -i /tmp/wkhtmltox.deb || (apt-get update && apt-get install -f -y); \
        rm -f /tmp/wkhtmltox.deb; \
    fi

# Copy Application Files
COPY ./app /opt/app
COPY ./tests /opt/tests
COPY ./app/supervisord /etc/supervisor/conf.d/services.conf
COPY ./tests/php_modules /opt/tests/php_modules
COPY ./tests/cli_php_modules /opt/tests/cli_php_modules
RUN chmod -R 755 /opt/* && \
    chmod +x /opt/app/entrypoint.sh && \
    chmod 644 /etc/supervisor/conf.d/services.conf && \
    chmod 644 /opt/tests/php_modules /opt/tests/cli_php_modules

# PHP Configuration
RUN cp /etc/php/8.3/apache2/php.ini /etc/php/8.3/apache2/php.ini.bak && \
    sed -i 's|;include_path = ".:/usr/share/php"|include_path = ".:/usr/share/php:/data/pear"|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|short_open_tag = Off|short_open_tag = On|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|max_execution_time = 30|max_execution_time = 300|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|memory_limit = 128M|memory_limit = -1|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 1000M|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|post_max_size = 8M|post_max_size = 1000M|' /etc/php/8.3/apache2/php.ini && \
    sed -i 's|max_input_time = 60|max_input_time = 300|' /etc/php/8.3/apache2/php.ini

# Composer Installation
COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer && \
    composer global require "laravel/installer" "vlucas/phpdotenv"

# Install WP-CLI
RUN wget -qO /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Unit Tests
RUN tar xf /opt/tests/shunit2-2.1.7.tar.gz -C /opt/tests/ && \
    chmod +x /opt/tests/build_tests.sh

# Permissions
RUN mkdir -p /data/www/public_html /data/pear /root/project/container-build && \
    chown -R www-data:www-data /var/www/html /root/project/container-build && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \;

# Ensure Supervisord Config
RUN echo "[supervisord]\nnodaemon=true\nlogfile=/var/log/supervisor/supervisord.log\npidfile=/var/run/supervisord.pid\n" > /etc/supervisor/supervisord.conf

# Environment Variables from .env
COPY .env /opt/.env
RUN echo "export SASL_USER=$(grep SASL_USER /opt/.env | cut -d '=' -f2)" >> /etc/environment && \
    echo "export SASL_PASS=$(grep SASL_PASS /opt/.env | cut -d '=' -f2)" >> /etc/environment && \
    echo "export LOG_TOKEN=$(grep LOG_TOKEN /opt/.env | cut -d '=' -f2)" >> /etc/environment && \
    echo "export NODE_ENVIRONMENT=$(grep NODE_ENVIRONMENT /opt/.env | cut -d '=' -f2)" >> /etc/environment

# Volumes, Ports, Healthcheck
VOLUME ["/backup", "/data", "/etc/letsencrypt"]
EXPOSE 80 443
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1

# Entrypoint
ENTRYPOINT ["/opt/app/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
