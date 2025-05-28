FROM php:8.3-apache

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
RUN mkdir -p /etc/php/8.3/mods-available /etc/php/8.3/apache2/conf.d /etc/php/8.3/cli/conf.d \
    && pecl install mcrypt-1.0.7 redis \
    && echo "extension=mcrypt.so" > /etc/php/8.3/mods-available/mcrypt.ini \
    && echo "extension=redis.so" > /etc/php/8.3/mods-available/redis.ini \
    && ln -s /etc/php/8.3/mods-available/mcrypt.ini /etc/php/8.3/apache2/conf.d/20-mcrypt.ini \
    && ln -s /etc/php/8.3/mods-available/redis.ini /etc/php/8.3/apache2/conf.d/20-redis.ini \
    && ln -s /etc/php/8.3/mods-available/mcrypt.ini /etc/php/8.3/cli/conf.d/20-mcrypt.ini \
    && ln -s /etc/php/8.3/mods-available/redis.ini /etc/php/8.3/cli/conf.d/20-redis.ini

# Copy Composer with pinned version and verify checksum
COPY --from=composer:2.8.9 /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer \
    && echo "8e8829ec2b97fcb05158236984bc252bef902e7b8ff65555a1eeda4ec13fb82b /usr/local/bin/composer" | sha256sum -c -

# Copy app and install dependencies
WORKDIR /var/www/html
COPY ./app /opt/app
RUN chmod +x /opt/app/postfix.sh

# Supervisor setup
RUN mkdir -p /var/log/supervisor \
    && cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf \
    && chmod 644 /etc/supervisor/conf.d/supervisord.conf

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

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
