FROM ubuntu:22.04

# Metadata as defined at http://label-schema.org
LABEL org.label-schema.name="Apache Docker" \
      org.label-schema.description="Docker container running Apache on Ubuntu with Composer, Laravel, TDD via CircleCI" \
      org.label-schema.url="https://htmlgraphic.com" \
      org.label-schema.vcs-url="https://github.com/htmlgraphic/Apache" \
      org.label-schema.vendor="HTMLgraphic, LLC" \
      org.label-schema.schema-version="1.0"

# Set non-interactive environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    OS_LOCALE="en_US.UTF-8" \
    LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE}

# Update and install locales
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}

# Install required packages and add repositories
RUN apt-get install -y \
        software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
        xfonts-75dpi \
        xfonts-base \
        python3.8 \
        curl \
        unzip \
        p7zip-full \
        apache2 \
        libsasl2-modules \
        libmcrypt-dev \
        libapache2-mod-php8.3 \
        php-pear \
        php8.3 \
        php8.3-cli \
        php8.3-bz2 \
        php8.3-curl \
        php8.3-mbstring \
        php8.3-intl \
        php8.3-fpm \
        php-dev \
        git \
        cron \
        ghostscript \
        mailutils \
        iputils-ping \
        mysql-client \
        libgs-dev \
        imagemagick \
        php-imagick \
        libmagickwand-dev \
        language-pack-en \
        supervisor \
        rsyslog \
        vim \
        wget \
        postfix \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install and configure pecl extensions
RUN pecl channel-update pecl.php.net \
    && pecl install mcrypt-1.0.7 \
    && pecl install redis -y

# Enable Apache mods.
RUN a2enmod userdir rewrite ssl

# Copy files to build app, initial web configs, coming soon page ...
COPY ./app /opt/app
COPY ./tests /opt/tests

# Supervisor setup
RUN chmod -R 755 /opt/* \
    && mkdir -p /var/log/supervisor \
    && cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf

# Composer v2 installation
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN composer self-update --2 \
    && composer global require "laravel/installer" \
    && composer global require "vlucas/phpdotenv"

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install wkhtmltox for HTML to PDF conversion
RUN dpkg -i /opt/app/wkhtmltox_0.12.6.1-2.jammy_arm64.deb \
    && apt-get install -f \
    && wkhtmltopdf --version

# Unit tests run via build_tests.sh
RUN tar xf /opt/tests/shunit2-2.1.7.tar.gz -C /opt/tests/

# Volumes for persistent data
VOLUME ["/backup", "/data", "/etc/letsencrypt"]

# Expose ports
EXPOSE 80 443

# Entrypoint command
CMD ["/opt/app/run.sh"]
