FROM dockerfile/ubuntu
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

#
# MySQL Dockerfile
# https://github.com/dockerfile/mysql
#

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -y install \
        mysql-client \
        mysql-server \
        git \
        vim

# Install MySQL.
RUN \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf


ADD ./startup.sh /opt/startup.sh

# Enabling this will expose mysql on a random host port. It's recommended to avoid this. Other containers on the same host can use the service without it.
#EXPOSE 3306

CMD ["/bin/bash", "/opt/startup.sh"]