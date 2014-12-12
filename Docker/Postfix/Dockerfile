FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
RUN apt-get update && \
    sudo apt-get -yq install \
        vim \
        curl \
        mailutils \
        language-pack-en

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    supervisor \
    rsyslog \
    postfix

#Remove cache package list information
RUN rm -rf /var/lib/apt/lists/*


# SUPERVISOR
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/

# POSTFIX
RUN cp /etc/hostname /etc/mailname

ADD preseed.txt .
RUN debconf-set-selections preseed.txt && rm preseed.txt


ADD virtual /etc/postfix/virtual
RUN sudo postmap /etc/postfix/virtual


# Note that EXPOSE only works for inter-container links. It doesn't make ports accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 25


ADD run.sh .
RUN chmod 755 /run.sh
CMD /run.sh