#!/bin/sh

# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

SHELL = /bin/sh

include .env # .env file needs to created for this to work properly

TAG 		= 1.8.2
CONTAINER 	= apache
IMAGE_REPO 	= htmlgraphic
IMAGE_NAME 	= $(IMAGE_REPO)/$(CONTAINER)
NODE_ENV=$(shell grep NODE_ENVIRONMENT .env | cut -d '=' -f 2-)


ifeq ($(NODE_ENV),dev)
	COMPOSE_FILE = docker-compose.local.yml
else
	COMPOSE_FILE = docker-compose.yml
endif


all:: help


help:
	@echo ""
	@echo "-- Help Menu for $(IMAGE_NAME):$(TAG)"
	@echo ""
	@echo "     make build		- Build Image"
	@echo "     make push		- Push $(IMAGE_NAME):$(TAG) to public Docker repo"
	@echo "     make run		- Run docker-compose and create local development environment"
	@echo "     make start		- Start the EXISTING $(CONTAINER) container"
	@echo "     make stop		- Stop running containers"
	@echo "     make rm		- Stop and remove $(CONTAINER) container"
	@echo "     make state		- View state $(CONTAINER) container"
	@echo "     make logs		- View logs"


env:
	@[ ! -f .env ] && echo "	.env file does not exist, copy env template \n" && cp .env.example .env || echo "	env file exists \n"
	@echo "The following environment varibles exist:"
	@echo $(shell sed 's/=.*//' .env)
	@echo ''


build:
	@make env
	docker build --no-cache \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		--rm -t $(IMAGE_NAME):$(TAG) -t $(IMAGE_NAME):latest .

push:
	@echo "note: If the repository is set as an automatted build you will NOT be able to push"
	docker push $(IMAGE_NAME):$(TAG)

run:
	@echo 'Setting environment varibles...'
	@make env
	@echo "Checking... initial directory structure \n"
	@if [ $(NODE_ENV) == 'dev' ]; then \
		if [ ! -d "~/SITES/docker" ]; then \
			echo "	Creating project folders \n" && sudo mkdir -p ~/SITES && sudo mkdir -p ~/SITES/docker; fi \
	fi
	@echo 'Run the following on the MySQL system, this will setup a GLOBAL admin:'
	@echo ''
	@echo "	docker exec -it apache_db /bin/bash \n \
		mysql -p$(MYSQL_ROOT_PASSWORD) \n \
		GRANT ALL PRIVILEGES ON * . * TO '$(MYSQL_USER)'@'%' with grant option; \n"

	@echo "	THE PASSWORD FOR $(MYSQL_USER) IS $(MYSQL_PASSWORD); \n"
	docker-compose -f $(COMPOSE_FILE) up -d


start: run

stop:
	@echo "Stopping local environment setup"
	docker-compose stop

rm:
	@echo "make rm - containers are specifically referenced, as to not destroy ANY persistent data"
	@echo "Removing $(CONTAINER) and $(CONTAINER)_db"
	docker rm -f $(CONTAINER)
	docker rm -f $(CONTAINER)_db
	docker rm -f $(CONTAINER)_phpmyadmin

state:
	docker ps -a | grep $(CONTAINER)

logs:
	@echo "Build $(CONTAINER)..."
	docker logs -f $(CONTAINER)
