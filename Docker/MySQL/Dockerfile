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

#Remove cache package list information
RUN rm -rf /var/lib/apt/lists/*

# Install MySQL.
RUN \
  rm -rf /var/lib/apt/lists/* && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf


ADD ./startup.sh /opt/startup.sh


# Note that EXPOSE only works for inter-container links. It doesn't make ports accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 3306

CMD ["/bin/bash", "/opt/startup.sh"]