FROM ubuntu:latest
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get -yq install \
        openssh-server \
        git

# Setting openssh
RUN mkdir /var/run/sshd
RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

# Adding git user
RUN adduser --system git
RUN mkdir -p /home/git/.ssh

# Clearing and setting authorized ssh keys
RUN echo '' > /home/git/.ssh/authorized_keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCbKBlYPbK29pUUwtwRIIjwCtZNujOUb77qHIeohOMk+O8z0gEIgkUwVI3x91AlbhctgpQor3IIeFITwGgIKVo33WW64HI9Nfr2vGx9EAfl9CL9cfDj9M9u4EFOn8NkD/TQMH4d1Fslt59eyl4fSV62d98zJ8goJwrolXM5NlS3hss8FtXhN6bNM0V5nliPUrv/1//3ZoZ5p0inOI1xWNHcMEILGllG+yqaknH9yIk880WoCYZuR7q2ddE6mxrBeJFiyryW5nhsxmXfHnsDVGiLh1C3hltEXzZ0Bdj11jhJfgIcuKU1iUFZg3kKVjRAvrteBQA328s5+UJswV+NWFiH htmlgraphic@htmlgraphic.local' >> /home/git/.ssh/authorized_keys

# Updating shell to bash
RUN sed -i s#/home/git:/bin/false#/home/git:/bin/bash# /etc/passwd

# Define mountable directories.
VOLUME ["/var/www/public_html"]

# Expose ports.
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]