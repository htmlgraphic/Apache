FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
RUN DEBIAN_FRONTEND noninteractive apt-get update && apt-get -yq install \
        openssh-server \
        git \
        fail2ban \
        iptables-persistent \
        vim \ 
        xinetd \
        telnetd

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y install \
    supervisor \
    rsyslog \
    postfix
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/


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



# These processes will need to be run manually and the image commited to the repo.
ADD run.sh /opt/run.sh
RUN sudo chmod 755 /opt/run.sh


# Note that EXPOSE only works for inter-container links. It doesn't make ports accessible from the host. To expose port(s) to the host, at runtime, use the -p flag.
EXPOSE 22


CMD ["/opt/run.sh"]