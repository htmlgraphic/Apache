FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
RUN apt-get update && \
    sudo apt-get -yq install \
        vim \
        curl \
        mailutils\
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-gd \
        php5-curl \
        php-pear \
        php-apc

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install \
    supervisor \
    rsyslog \
    postfix

#Remove cache package list information
RUN rm -rf /var/lib/apt/lists/*


# SUPERVISOR
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/

# POSTFIX
RUN update-locale LANG=en_US.UTF-8
RUN cp /etc/hostname /etc/mailname

# APACHE
RUN sed -i 's|[PHP]|[PHP] \n IS_LIVE=1 \n IS_DEV=1; \n ;The IS_DEV is set for testing outside of DEV environments ie: test.domain.tld|g' /etc/php5/apache2/php.ini

RUN sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable apache mods.
RUN a2enmod php5
RUN a2enmod rewrite
 
# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
RUN sed -i 's|;session.save_path = "/var/lib/php5"|session.save_path = "/tmp"|g' /etc/php5/apache2/php.ini
RUN sed -i 's|"\/var\/log\/apache2\/error.log"|"\/data\/apache2\/error.log"|g' /etc/php5/apache2/php.ini

RUN sed -i 's|#ServerRoot "\/etc\/apache2"|ServerRoot "\/data\/apache2"|g' /etc/apache2/apache2.conf

# Manually set the apache environment variables in order to get apache to work immediately.
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

ADD apache-config.conf /opt/apache-config.conf

# Add coming page to root apache dir
ADD ./apache-config.conf /opt/apache-config.conf

# Add coming page to root apache dir
ADD ./index.php /opt/temp.php
RUN chmod 755 /opt/temp.php

# On server process
ADD ./run.sh /opt/run.sh
RUN chmod 755 /opt/run.sh


# Note that EXPOSE only works for inter-container links. It doesn't make ports accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 80


CMD ["/opt/run.sh"]