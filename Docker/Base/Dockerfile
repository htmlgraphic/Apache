FROM ubuntu:trusty
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

# Install packages then remove cache package list information
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq install \
        vim \
        curl \
        mailutils \
        language-pack-en \
        git && rm -rf /var/lib/apt/lists/*

# POSTFIX
RUN update-locale LANG=en_US.UTF-8