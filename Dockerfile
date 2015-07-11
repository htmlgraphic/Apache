FROM htmlgraphic/base
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install packages then remove cache package list information
RUN apt-get update && apt-get -yq install openssh-client \
	apache2 \
	libapache2-mod-php5 \
	php5-mcrypt \
	php5-mysql \
	php5-gd \
	php5-curl \
	php-pear \
	php-apc

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install supervisor \
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


# APACHE
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Update root user
RUN chmod 755 /root && mkdir -p /root/.ssh


# Clearing and setting authorized ssh keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbKBlYPbK29pUUwtwRIIjwCtZNujOUb77qHIeohOMk+O8z0gEIgkUwVI3x91AlbhctgpQor3IIeFITwGgIKVo33WW64HI9Nfr2vGx9EAfl9CL9cfDj9M9u4EFOn8NkD/TQMH4d1Fslt59eyl4fSV62d98zJ8goJwrolXM5NlS3hss8FtXhN6bNM0V5nliPUrv/1//3ZoZ5p0inOI1xWNHcMEILGllG+yqaknH9yIk880WoCYZuR7q2ddE6mxrBeJFiyryW5nhsxmXfHnsDVGiLh1C3hltEXzZ0Bdj11jhJfgIcuKU1iUFZg3kKVjRAvrteBQA328s5+UJswV+NWFiH hosting@htmlgraphic.com' >> /root/.ssh/authorized_keys

# PEAR Package needed for a web app
RUN pear install HTML_QuickForm

# Enable Apache mods.
RUN a2enmod php5 && a2enmod suexec && a2enmod userdir && a2enmod rewrite && a2enmod ssl && php5enmod mcrypt

# Install PHPUnit
RUN curl -O https://phar.phpunit.de/phpunit.phar | bash && chmod +x phpunit.phar && mv phpunit.phar /usr/local/bin/phpunit

# Manually set the apache environment variables in order to get apache to work immediately.
ENV APACHE_RUN_USER=www-data \
	APACHE_RUN_GROUP=www-data \
	APACHE_LOG_DIR=/var/log/apache2 \
	APACHE_LOCK_DIR=/var/lock/apache2 \
	APACHE_PID_FILE=/var/run/apache2.pid \
	NODE_ENVIRONMENT=$NODE_ENVIRONMENT


# Add VOLUMEs to allow backup of config and databases
VOLUME  ["/data"]

# Note that EXPOSE only works for inter-container links. It doesn't make ports
# accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 80 443


CMD ["/opt/app/run.sh"]
