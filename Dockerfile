FROM htmlgraphic/base
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install packages then remove cache package list information
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -yq install openssh-client \
	apache2 \
	wget \
	libapache2-mod-php5 \
	php5-mcrypt \
	php5-mysql \
	php5-gd \
	php5-curl \
	php-pear \
	php-apc \
	php5-dev \
	libmagickwand-dev \
	supervisor \
	rsyslog \
	postfix && apt-get clean && rm -rf /var/lib/apt/lists/*


# Copy files to build app, add coming page to root apache dir, include self
# signed SHA256 certs, unit tests to check over the setup
RUN mkdir -p /opt
COPY ./app /opt/app
COPY ./tests /opt/tests
RUN chmod -R 755 /opt/*


# SUPERVISOR
RUN mkdir -p /var/log/supervisor && cp /opt/app/supervisord /etc/supervisor/conf.d/supervisord.conf


# SSH
# Add public key for root access
RUN mkdir -p /root/.ssh
COPY ./authorized_keys /root/.ssh/authorized_keys


# APACHE
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# PEAR Package needed for a web app
RUN pear install HTML_QuickForm

# Install imagick into Apache
RUN pecl install imagick

# Enable Apache mods.
RUN a2enmod php5 && a2enmod suexec && a2enmod userdir && a2enmod rewrite && a2enmod ssl && php5enmod mcrypt

# Environment variables contained within build container.
ENV APACHE_RUN_USER=www-data \
	APACHE_RUN_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2 \
	APACHE_LOCK_DIR=/var/lock/apache2 \
	APACHE_PID_FILE=/var/run/apache2.pid \
	NODE_ENVIRONMENT=$NODE_ENVIRONMENT \
	USER=p08tf1X \
	PASS=p@ssw0Rd \
	LOG_TOKEN=$LOG_TOKEN


# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/data"]

# Note that EXPOSE only works for inter-container links. It doesn't make ports
# accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 80 443


CMD ["/opt/app/run.sh"]
