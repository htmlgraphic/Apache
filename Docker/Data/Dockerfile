FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    sudo apt-get -yq install \
        openssh-server \
        git \
        fail2ban \
        iptables-persistent \
        vim


RUN echo 10.132.191.193 mysql >> /etc/hosts

# Prepping fail2ban
RUN sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
RUN sed -i "s/destemail = root@localhost/destemail = hosting@htmlgraphic.com/" /etc/fail2ban/jail.local
RUN sed -i "s/maxretry = 6/maxretry = 3/" /etc/fail2ban/jail.local


# Prepping openssh
RUN mkdir /var/run/sshd
RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config
RUN sed -i "s/LogLevel INFO/LogLevel VERBOSE/" /etc/ssh/sshd_config

# Adding htmlgraphic user
RUN adduser --system htmlgraphic
RUN mkdir -p /home/htmlgraphic/.ssh

# Clearing and setting authorized ssh keys
RUN echo '' > /home/htmlgraphic/.ssh/authorized_keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbKBlYPbK29pUUwtwRIIjwCtZNujOUb77qHIeohOMk+O8z0gEIgkUwVI3x91AlbhctgpQor3IIeFITwGgIKVo33WW64HI9Nfr2vGx9EAfl9CL9cfDj9M9u4EFOn8NkD/TQMH4d1Fslt59eyl4fSV62d98zJ8goJwrolXM5NlS3hss8FtXhN6bNM0V5nliPUrv/1//3ZoZ5p0inOI1xWNHcMEILGllG+yqaknH9yIk880WoCYZuR7q2ddE6mxrBeJFiyryW5nhsxmXfHnsDVGiLh1C3hltEXzZ0Bdj11jhJfgIcuKU1iUFZg3kKVjRAvrteBQA328s5+UJswV+NWFiH hosting@htmlgraphic.com' >> /home/htmlgraphic/.ssh/authorized_keys

# Updating shell to bash
RUN sed -i s#/home/htmlgraphic:/bin/false#/home/htmlgraphic:/bin/bash# /etc/passwd

# System wide version of .bashrc
RUN chmod 755 /etc/bash.bashrc

# Updatng root user
RUN mkdir -p /root/.ssh

# Clearing and setting authorized ssh keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbKBlYPbK29pUUwtwRIIjwCtZNujOUb77qHIeohOMk+O8z0gEIgkUwVI3x91AlbhctgpQor3IIeFITwGgIKVo33WW64HI9Nfr2vGx9EAfl9CL9cfDj9M9u4EFOn8NkD/TQMH4d1Fslt59eyl4fSV62d98zJ8goJwrolXM5NlS3hss8FtXhN6bNM0V5nliPUrv/1//3ZoZ5p0inOI1xWNHcMEILGllG+yqaknH9yIk880WoCYZuR7q2ddE6mxrBeJFiyryW5nhsxmXfHnsDVGiLh1C3hltEXzZ0Bdj11jhJfgIcuKU1iUFZg3kKVjRAvrteBQA328s5+UJswV+NWFiH hosting@htmlgraphic.com' >> /root/.ssh/authorized_keys


# Define mountable directories.
VOLUME [ "/data", "/var/lib/mysql", "/var/spool/cron/crontabs" ]

# Expose ports.
EXPOSE 22

# These processes will need to be run manually and the image commited to the repo
ADD htmlgraphic.sh /etc/htmlgraphic.sh
RUN sudo chmod 755 /etc/htmlgraphic.sh

RUN /bin/sh /etc/htmlgraphic.sh

CMD ["/usr/sbin/sshd", "-D"]