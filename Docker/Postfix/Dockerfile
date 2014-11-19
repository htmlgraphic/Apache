FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    sudo apt-get -yq install \
        vim \
        curl \
        postfix \
        mailutils

run apt-get install -q -y language-pack-en
run update-locale LANG=en_US.UTF-8

ADD preseed.txt .
RUN debconf-set-selections preseed.txt && rm preseed.txt

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    supervisor rsyslog postfix
ADD supervisord.conf /etc/supervisor/conf.d/

EXPOSE 25


ADD start.sh .
RUN chmod 755 /start.sh
CMD /start.sh