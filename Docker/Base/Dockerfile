FROM ubuntu:trusty
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install base packages
RUN apt-get update && apt-get -yq install \
        vim \
        curl \
        mailutils \
        language-pack-en \
        git

#Remove cache package list information
RUN rm -rf /var/lib/apt/lists/*

# POSTFIX
RUN update-locale LANG=en_US.UTF-8