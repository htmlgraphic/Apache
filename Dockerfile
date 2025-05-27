FROM ubuntu:22.04

# Metadata
LABEL org.label-schema.name="Apache Docker" \
      org.label-schema.description="Docker container running Apache on Ubuntu with Composer, Laravel, TDD via CircleCI" \
      org.label-schema.url="https://htmlgraphic.com" \
      org.label-schema.vcs-url="https://github.com/htmlgraphic/Apache" \
      org.label-schema.vendor="HTMLgraphic, LLC" \
      org.label-schema.schema-version="1.0"

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Locales
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# Install required packages
RUN apt-get install -y \
        software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update && apt-get install -y \
    apache2 \
    cron \
    curl \
    ghostscript \
    git \
    iputils-ping \
    language-pack-en \
    libapache2-mod-php8.2 \
    libbson-1.0 \
    libgs-dev \
    libmcrypt-dev \
    libsasl2-modules \
    libmongoc-1.0-0 \
    mailutils \
    mysql-client \
    pkg-config \
    php8.2 \
    php8.2-bz2 \
    php8.2-cli \
    php8.2-curl \
    php8.2-fpm \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-dev \
    php-pear \
    postfix \
    p7zip-full \
    rsyslog \
    supervisor \
    unzip \
    vim \
    wget \
    xfonts-75dpi \
    xfonts-base \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set PHP CLI default version to 8.2
RUN update-alternatives --install /usr/bin/php php /usr/bin/php8.2 100 \
    && update-alternatives --install /usr/bin/php-config php-config /usr/bin/php-config8.2 100 \
    && update-alternatives --install /usr/bin/phpize phpize /usr/bin/phpize8.2 100

# Install and configure PECL extensions
RUN timeout 30 pecl channel-update pecl.php.net || true
RUN pecl install mcrypt-1.0.7
RUN pecl install redis

# Enable Apache mods
RUN a2enmod userdir rewrite ssl

# Copy app files
COPY ./app /opt/app
COPY ./tests /opt/tests

# Supervisor setup
RUN chmod -R 755 /opt/* \
    && mkdir -p /var/log/supervisor \
    && cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf

# Composer v2 installation
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Set working directory to the app
WORKDIR /opt/app

# Install dependencies after copying app source
RUN php -v \
    && which php \
    && composer self-update --2 \
    && composer validate \
    && composer update --no-interaction --prefer-dist


# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install wkhtmltox (adjust .deb path if needed for your architecture)
RUN dpkg -i /opt/app/wkhtmltox_0.12.6.1-2.jammy_arm64.deb || apt-get install -f -y

# Extract unit test framework
RUN tar xf /opt/tests/shunit2-2.1.7.tar.gz -C /opt/tests/

# Volumes
VOLUME ["/backup", "/data", "/etc/letsencrypt"]

# Expose HTTP/HTTPS
EXPOSE 80 443

# Entrypoint
CMD ["/opt/app/run.sh"]
