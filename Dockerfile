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
    LC_ALL=${OS_LOCALE}

# Update and Install Locales
RUN apt-get update && apt-get install -y locales && \
    locale-gen ${OS_LOCALE} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Required Packages
RUN apt-get update && apt-get install -y \
        software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && \
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
        wget \
        postfix && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install and Configure PECL Extensions
RUN pecl channel-update pecl.php.net && \
    (pecl install mcrypt-1.0.7 || true) && \
    pecl install redis && \
    echo "extension=mcrypt.so" > /etc/php/8.3/mods-available/mcrypt.ini && \
    echo "extension=redis.so" > /etc/php/8.3/mods-available/redis.ini && \
    phpenmod mcrypt redis

# Enable Apache Modules
RUN a2enmod userdir rewrite ssl

# Apache Configuration
RUN a2ensite default-ssl && \
    echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && \
    a2enconf servername && \
    rm -f /etc/apache2/sites-enabled/* && \
    mkdir -p /data/apache2/{logs,ssl,sites-enabled} && \
    sed -i 's|IncludeOptional sites-enabled/\*.conf|IncludeOptional /data/apache2/sites-enabled/*.conf|' /etc/apache2/apache2.conf && \
    echo "<IfModule mpm_event_module>\nStartServers 2\nMinSpareThreads 25\nMaxSpareThreads 75\nThreadLimit 64\nThreadsPerChild 25\nMaxRequestWorkers 150\nMaxConnectionsPerChild 0\n</IfModule>" >> /etc/apache2/apache2.conf

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

# Install mod_pagespeed
RUN wget -O /tmp/mod-pagespeed.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && \
    dpkg -i /tmp/mod-pagespeed.deb || (apt-get update && apt-get install -f -y) && \
    rm /tmp/mod-pagespeed.deb && \
    mkdir -p /var/cache/mod_pagespeed /var/log/pagespeed && \
    chown nobody:www-data /var/cache/mod_pagespeed /var/log/pagespeed && \
    chmod 755 /var/cache/mod_pagespeed /var/log/pagespeed

# Install wkhtmltox
RUN wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.noble_amd64.deb && \
    dpkg -i /tmp/wkhtmltox.deb || (apt-get update && apt-get install -f -y) && \
    rm /tmp/wkhtmltox.deb

# Copy Application Files
COPY ./app /opt/app
COPY ./tests /opt/tests
RUN chmod -R 755 /opt/* && \
    chmod +x /opt/app/entrypoint.sh

# Supervisor Setup
RUN mkdir -p /var/log/supervisor && \
    cp /opt/app/supervisord.conf /etc/supervisor/conf.d/supervisord.conf && \
    chmod 644 /etc/supervisor/conf.d/supervisord.conf

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
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Unit Tests
RUN tar xf /opt/tests/shunit2-2.1.7.tar.gz -C /opt/tests/

# Permissions
RUN mkdir -p /data/www/public_html /data/pear && \
    chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \;

# Volumes, Ports, Healthcheck
VOLUME ["/backup", "/data", "/etc/letsencrypt"]
EXPOSE 80 443
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1

# Entrypoint
ENTRYPOINT ["/opt/app/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
