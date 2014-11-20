FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
RUN apt-get update && \
    sudo apt-get -yq install \
        vim \
        curl \
        mailutils

RUN apt-get install -q -y language-pack-en
RUN update-locale LANG=en_US.UTF-8

RUN echo post-office > /etc/mailname

ADD preseed.txt .
RUN debconf-set-selections preseed.txt && rm preseed.txt

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    supervisor \
    rsyslog \
    postfix
ADD supervisord.conf /etc/supervisor/conf.d/


ADD virtual /etc/postfix/virtual
RUN sudo postmap /etc/postfix/virtual

EXPOSE 25


ADD run.sh .
RUN chmod 755 /run.sh
CMD /run.sh