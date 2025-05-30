# Stage 1: Build mod_pagespeed
FROM php:8.3-apache-bullseye AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies with retries
RUN for i in {1..3}; do \
    apt-get update && apt-get install -y --no-install-recommends \
        apache2-dev \
        g++ \
        python2 \
        git \
        gperf \
        make \
        devscripts \
        fakeroot \
        zlib1g-dev \
        uuid-dev \
        libcurl4-openssl-dev \
        libpng-dev \
        libjpeg-dev \
        python2-dev \
        wget \
        && apt-get clean && rm -rf /var/lib/apt/lists/* && break \
        || (echo "Retrying apt-get ($i/3)"; sleep 5); \
    done; exit 0 || { echo "Error: Failed to install dependencies"; exit 1; } && \
    wget -q https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
    python2 get-pip.py && \
    python2 -m pip install --upgrade pip && \
    python2 -m pip install --force-reinstall six && \
    python2 -m pip show six || { echo "pip show six failed"; exit 1; } && \
    rm get-pip.py

# Debug Python 2 environment
RUN ln -s /usr/bin/python2 /usr/bin/python && \
    python2 -c "import sys; print('Python version:', sys.version); print('sys.path:', sys.path)" && \
    python2 -c "import site; print('site-packages:', site.getsitepackages())" && \
    python2 -m pip --version && \
    python2 -c "import six; print('six version:', six.__version__)" || { echo "six import failed"; exit 1; } && \
    python2 -c "from six.moves import collections_abc; print('six.moves imported')" || { echo "six.moves import failed"; exit 1; }

# Clone repositories
RUN mkdir -p /root/bin && \
    cd /root/bin && \
    for i in 1 2 3; do git clone https://chromium.googlesource.com/chromium/tools/depot_tools && break || sleep 5; done && \
    for i in 1 2 3; do git clone https://chromium.googlesource.com/external/gyp && break || sleep 5; done && \
    export PATH="$PATH:/root/bin/depot_tools" && \
    export PYTHONPATH="/usr/lib/python2.7/dist-packages:/usr/local/lib/python2.7/dist-packages" && \
    ls -l /root/bin/gyp/gyp_main.py || { echo "Cannot list directory: /root/bin/gyp/gyp_main.py does not exist."; exit 1; } && \
    python2 /root/bin/gyp/gyp_main.py --version || echo "gyp version failed" && \
    git clone https://github.com/apache/incubator-pagespeed-mod /tmp/mod_pagespeed && \
    cd /tmp/mod_pagespeed && \
    git checkout v1.13.35.2 && \
    git submodule update --init --recursive && \
    test -f build/mod_pagespeed.gyp || { echo "Error: build/mod_pagespeed.gyp does not exist."; exit 1; } && \
    ls -l build/mod_pagespeed.gyp && \
    git log -1 --pretty=%H

# Build mod_pagespeed with GLIBC patch
RUN cd /tmp/mod_pagespeed && \
    sed -i -r 's/sys_siglist\[signum\]/strsignal(signum)/g' third_party/apr/src/threadproc/unix/signals.c && \
    export PATH="$PATH:/root/bin/depot_tools" && \
    export PYTHONPATH="/usr/lib/python2.7/dist-packages:/usr/local/lib/python2.7/dist-packages" && \
    python2 /root/bin/gyp/gyp_main.py --depth=. build/mod_pagespeed.gyp -D use_system_libs=1 && \
    make -j$(nproc) BUILDTYPE=Release V=1 mod_pagespeed && \
    mkdir -p /mod_pagespeed_out && \
    cp out/Release/mod_pagespeed.so /mod_pagespeed_out/ && \
    cp out/Release/mod_pagespeed_ap24.so /mod_pagespeed_out/

# Stage 2: Final image
FROM php:8.3-apache-bullseye

# Define build argument for environment (dev or production)
ARG BUILD_ENV=dev

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

# Install runtime dependencies with retries
RUN for i in {1..3}; do \
    apt-get update && apt-get install -y --no-install-recommends \
        fontconfig \
        libjpeg62-turbo \
        libssl1.1 \
        xfonts-75dpi \
        xfonts-base \
        cron \
        curl \
        ghostscript \
        libbson-1.0-0 \
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
        libxrender1 \
        libfontconfig1 \
        $(if [ "$BUILD_ENV" = "dev" ]; then echo "git vim iputils-ping"; fi) \
        wget \
        && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
        && locale-gen \
        && apt-get autoremove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* && break \
        || (echo "Retrying apt-get ($i/3)"; sleep 5); \
    done; exit 0 || { echo "Error: Failed to install dependencies"; exit 1; }

# Enable Apache modules
RUN a2enmod rewrite ssl

# Configure Apache
RUN a2ensite default-ssl \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install PECL extensions
RUN pecl install mcrypt-1.0.7 redis \
    && docker-php-ext-enable mcrypt redis

# Install wkhtmltox for arm64
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        wget -O /opt/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb; \
    elif [ "$ARCH" = "arm64" ]; then \
        wget -O /opt/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_arm64.deb; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    dpkg -i /opt/wkhtmltox.deb || (apt-get update && apt-get install -f -y) \
    && rm /opt/wkhtmltox.deb

# Copy mod_pagespeed from builder
COPY --from=builder /mod_pagespeed_out/mod_pagespeed.so /usr/lib/apache2/modules/mod_pagespeed.so
COPY --from=builder /mod_pagespeed_out/mod_pagespeed_ap24.so /usr/lib/apache2/modules/mod_pagespeed_ap24.so
RUN mkdir -p /var/cache/mod_pagespeed /var/log/pagespeed && \
    chown nobody:www-data /var/cache/mod_pagespeed /var/log/pagespeed && \
    chmod 755 /var/cache/mod_pagespeed /var/log/pagespeed && \
    echo "LoadModule pagespeed_module /usr/lib/apache2/modules/mod_pagespeed_ap24.so" > /etc/apache2/mods-available/pagespeed.load && \
    a2enmod pagespeed

# Copy Composer
COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer \
    && echo "8e8829ec2b97fcb05158236984bc252bef902e7b8ff65555a1eeda4ec13fb82b /usr/local/bin/composer" | sha256sum -c -

# Copy app and scripts
WORKDIR /var/www/html
COPY ./app /opt/app
COPY ./tests /opt/tests
RUN chmod +x /opt/app/postfix.sh /opt/app/entrypoint.sh

# Supervisor setup
RUN mkdir -p /var/log/supervisor \
    && cp /opt/app/supervisord.conf /etc/supervisor/conf.d/supervisord.conf \
    && chmod 644 /etc/supervisor/conf.d/supervisord.conf

# Create PHP configuration
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i 's|;include_path = ".:/usr/share/php"|include_path = ".:/usr/share/php:/data/pear"|g' /usr/local/etc/php/php.ini \
    && sed -i 's|variables_order.*/variables_order = "EGPCS"/g' /usr/local/etc/php/php.ini \
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

# Install Composer dependencies
RUN composer global require "laravel/installer" "vlucas/phpdotenv"

# Install WP-CLI
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Unit tests
RUN tar xf /opt/tests/shunit2-2.1.7.tar.gz -C /opt/tests/

# Volumes and ports
VOLUME ["/backup", "/data", "/etc/letsencrypt"]
EXPOSE 80 443

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f https://localhost/ || exit 1

# Entrypoint and command
ENTRYPOINT ["/opt/app/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
