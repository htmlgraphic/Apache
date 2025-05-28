# Specify platform explicitly
FROM --platform=linux/arm64 php:8.3-apache

# Define build argument for environment (dev or production)
ARG BUILD_ENV=production

LABEL org.label-schema.name="Apache Docker" \
      org.label-schema.description="Docker container running Apache with Composer, TDD" \
      org.label-schema.url="https://htmlgraphic.com" \
      org.label-schema.vcs-url="https://github.com/htmlgraphic/Apache" \
      org.label-schema.vendor="HTMLgraphic, LLC" \
      org.label-schema.schema-version="1.0"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install dependencies
RUN apt-get update && apt-get install -y \
      cron \
      curl \
      ghostscript \
      libbson-1.0 \
      libgs-dev \
      libmcrypt-dev \
      libmongoc-1.0-0 \
      mariadb-client \
      postfix \
      rsyslog \
      supervisor \
      unzip \
      mailutils \
      locales \
      $(if [ "$BUILD_ENV" = "dev" ]; then echo "git vim iputils-ping wget"; fi) \
      && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
      && locale-gen \
      && apt-get autoremove -y \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite ssl

# Install PECL extensions
RUN mkdir -p /usr/local/etc/php/conf.d \
    && pecl install mcrypt-1.0.7 redis \
    && echo "extension=mcrypt.so" > /usr/local/etc/php/conf.d/mcrypt.ini \
    && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

# Copy Composer
COPY --from=composer:2.8.9 /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer \
    && echo "8e8829ec2b97fcb05158236984bc252bef902e7b8ff65555a1eeda4ec13fb82b /usr/local/bin/composer" | sha256sum -c -

# Copy app and scripts
WORKDIR /var/www/html
COPY ./app /opt/app
RUN chmod +x /opt/app/postfix.sh /opt/app/entrypoint.sh

# Supervisor setup
RUN mkdir -p /var/log/supervisor \
    && cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf \
    && chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Create PHP configuration
RUN mkdir -p /usr/local/etc/php \
    && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i 's|;include_path = ".:/usr/share/php"|include_path = ".:/usr/share/php:/data/pear"|g' /usr/local/etc/php/php.ini \
    && sed -i 's/variables_order.*/variables_order = "EGPCS"/g' /usr/local/etc/php/php.ini \
    && sed -i 's|;error_log = php_errors.log|error_log = /data/apache2/logs/error_log|g' /usr/local/etc/php/php.ini \
    && sed -i 's|short_open_tag = Off|short_open_tag = On|g' /usr/local/etc/php/php.ini \
    && sed -i 's|;session.save_path = "/var/lib/php5"|session.save_path = "/tmp"|g' /usr/local/etc/php/php.ini \
    && sed -i 's|session.gc_probability = 0|session.gc_probability = 1|g' /usr/local/etc/php/php.ini \
    && sed -i 's|max_execution_time = 30|max_execution_time = 300|g' /usr/local/etc/php/php.ini \
    && sed -i 's|memory_limit = 128M|memory_limit = -1|g' /usr/local/etc/php/php.ini \
    && sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 1000M|g' /usr/local/etc/php/php.ini \
    && sed -i 's|post_max_size = 8M|post_max_size = 1000M|g' /usr/local/etc/php/php.ini \
    && sed -i 's|max_input_time = 60|max_input_time = 300|g' /usr/local/etc/php/php.ini

# Static setup from run.sh
RUN mkdir -p /data/www/public_html /data/apache2/{logs,ssl,sites-enabled} /data/pear \
    && touch /data/pear/empty \
    && chmod 700 /etc/apache2/* \
    && echo "ServerName localhost" > /etc/apache2/conf-enabled/servername.conf \
    && rm /etc/apache2/sites-enabled/000-default.conf \
    && sed -i 's|IncludeOptional sites-enabled\/\*.conf|IncludeOptional /data/apache2/sites-enabled/*.conf|' /etc/apache2/apache2.conf \
    && echo "<IfModule mpm_event_module>\nStartServers 3\nMinSpareThreads 25\nMaxSpareThreads 75\nThreadLimit 64\nThreadsPerChild 25\nMaxRequestWorkers 30\nMaxConnectionsPerChild 1000\n</IfModule>" >> /etc/apache2/apache2.conf

# Postfix static setup
RUN postconf -e "compatibility_level=2" "myhostname=dev-build.htmlgraphic.com" \
    "mail_spool_directory=/var/spool/mail/" "mydestination=localhost.localdomain localhost" \
    "smtp_sasl_auth_enable=yes" "smtp_sasl_security_options=noanonymous" \
    "smtp_sasl_tls_security_options=noanonymous" "smtp_tls_security_level=encrypt" \
    "header_size_limit=4096000" "inet_protocols=ipv4" \
    && cp /etc/hostname /etc/mailname

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Volumes and ports
VOLUME ["/backup", "/data", "/etc/letsencrypt"]
EXPOSE 80 443

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f https://localhost/ || exit 1

# Entrypoint and command
ENTRYPOINT ["/opt/app/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
