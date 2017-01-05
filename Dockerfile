FROM htmlgraphic/ssh:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install packages then remove cache package list information
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -yq install python-software-properties software-properties-common \
	openssh-client \
	apache2 \
	php7.0 \
	libapache2-mod-php7.0 \
	mysql-client \
	php-apcu \
	php-imagick \
	php7.0-fpm \
	php7.0-zip \
	php7.0-mysql \
	php7.0-curl \
	php7.0-gd \
	php7.0-json \
	php7.0-mcrypt \
	php7.0-mbstring \
	php7.0-opcache \
	php7.0-xml \
	libmagickwand-dev \
	supervisor \
	rsyslog \
	postfix && apt-get clean && rm -rf /var/lib/apt/lists/*

# POSTFIX
RUN update-locale LANG=en_US.UTF-8

# Copy files to build app, add coming page to root apache dir, include self
# signed SHA256 certs, unit tests to check over the setup
RUN mkdir -p /opt
COPY ./app /opt/app
COPY ./tests /opt/tests

# Unit tests run via build_tests.sh
RUN curl -L "https://github.com/aetheric/shunit2/archive/2.1.6.tar.gz" | tar zx -C /opt/tests/

# SUPERVISOR
RUN chmod -R 755 /opt/* && \
	mkdir -p /var/log/supervisor && \
	cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf

# APACHE
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# LARAVEL
RUN composer global require "laravel/installer"

# Enable Apache mods.
RUN a2enmod userdir && a2enmod rewrite && a2enmod ssl

# Environment variables contained within build container.
ENV TERM=xterm \
	APACHE_RUN_USER=www-data \
	APACHE_RUN_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2 \
	APACHE_LOCK_DIR=/var/lock/apache2 \
	APACHE_PID_FILE=/var/run/apache2.pid \
	NODE_ENVIRONMENT=$NODE_ENVIRONMENT \
	SMTP_HOST=$SMTP_HOST \
	SASL_USER=$SASL_USER \
	SASL_PASS=$SASL_PASS \
	PATH="~/.composer/vendor/bin:$PATH" \
	LOG_TOKEN=$LOG_TOKEN \
	AUTHORIZED_KEYS=$AUTHORIZED_KEYS

# Build-time metadata as defined at http://label-schema.org
    ARG BUILD_DATE
    ARG VCS_REF
    ARG VERSION
    LABEL org.label-schema.build-date=$BUILD_DATE \
          org.label-schema.name="Apache Docker" \
          org.label-schema.description="Docker container running Apache running on Ubuntu, Composer, Lavavel, TDD via Shippable & CircleCI" \
          org.label-schema.url="https://htmlgraphic.com" \
          org.label-schema.vcs-ref=$VCS_REF \
          org.label-schema.vcs-url="https://github.com/htmlgraphic/Apache" \
          org.label-schema.vendor="HTMLgraphic, LLC" \
          org.label-schema.version=$VERSION \
          org.label-schema.schema-version="1.0"

# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/data"]

# Note that EXPOSE only works for inter-container links. It doesn't make ports
# accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 80 443


CMD ["/opt/app/run.sh"]
