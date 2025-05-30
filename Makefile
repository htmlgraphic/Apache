# Makefile for Docker build, test, and run workflow
# By Jason Gegere <jason@htmlgraphic.com>

# Variables
IMAGE_NAME := htmlgraphic/apache
TAG := 2.1.0
REGISTRY := docker.io
CONTAINER_NAME := apache
ENV_FILE := .env
PLATFORM := linux/amd64
COMPOSE_DEV := docker compose -f docker-compose.local.yml
COMPOSE_PROD := docker compose -f docker-compose.yml
NODE_ENV := $(shell grep -E '^NODE_ENVIRONMENT=' $(ENV_FILE) | cut -d '=' -f 2-)

# Load environment variables from .env
ifneq (,$(wildcard $(ENV_FILE)))
	include $(ENV_FILE)
	export
endif

# Default environment
NODE_ENVIRONMENT ?= dev

.PHONY: all help env build test run start stop state logs push clean

# Default target
all: build test run

# Help menu
help:
	@echo ""
	@echo "-- Help Menu for $(IMAGE_NAME):$(TAG)"
	@echo ""
	@echo "     make build        - Build Image"
	@echo "     make test         - Test components in Image"
	@echo "     make push         - Push $(IMAGE_NAME):$(TAG) to public Docker repo"
	@echo "     make run          - Run docker-compose and create local environment"
	@echo "     make start        - Start the EXISTING $(CONTAINER_NAME) container"
	@echo "     make stop         - Stop running containers"
	@echo "     make state        - View state of $(CONTAINER_NAME) container"
	@echo "     make logs         - View logs"
	@echo "     make env          - Create and list .env variables"
	@echo "     make clean        - Remove images and prune system"

# Create .env if missing
env:
	@[ ! -f $(ENV_FILE) ] && echo "	.env file does not exist, copying template\n" && cp .env.example $(ENV_FILE) || echo "	.env file exists\n"
	@echo "The following environment variables exist:"
	@echo $(shell sed 's/=.*//' $(ENV_FILE))
	@echo ''

# Build the Docker image
build:
	@make env
	@echo "Building Docker image with NODE_ENVIRONMENT=$(NODE_ENVIRONMENT) for platform $(PLATFORM)"
	docker build --no-cache \
		--platform $(PLATFORM) \
		--build-arg BUILD_ENV=$(NODE_ENVIRONMENT) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-t $(IMAGE_NAME):$(TAG) \
		-t $(IMAGE_NAME):latest .

# Test the Docker image
test:
	@echo "Testing components in $(IMAGE_NAME):$(TAG)"
	@docker run --rm $(IMAGE_NAME):$(TAG) composer --version
	@if [ "$(NODE_ENVIRONMENT)" = "dev" ]; then \
		docker run --rm $(IMAGE_NAME):$(TAG) git --version; \
		docker run --rm $(IMAGE_NAME):$(TAG) vim --version; \
		docker run --rm $(IMAGE_NAME):$(TAG) ping -V; \
		docker run --rm $(IMAGE_NAME):$(TAG) wget --version; \
	fi
	@docker run --rm $(IMAGE_NAME):$(TAG) mysql --version
	@docker run --rm $(IMAGE_NAME):$(TAG) php -m | grep -E 'mcrypt|redis'
	@docker run --rm $(IMAGE_NAME):$(TAG) dpkg -l | grep -E 'mailutils|locales'

# Run the containers
run:
	@make env
	@echo "Setting environment variables...\n"
	@echo "Checking initial directory structure\n"
	@if [ "$(NODE_ENVIRONMENT)" = "dev" ]; then \
		if [ ! -d "~/SITES/docker" ]; then \
			echo "	Creating project folders\n" && mkdir -p ~/SITES/docker && chmod 777 ~/SITES/docker; \
		fi \
	fi
	@echo "\033[1mRun the following on the MySQL container to setup a GLOBAL admin:\033[00m\n"
	@echo "	THE PASSWORD FOR \033[1m$(MYSQL_USER)\033[00m IS \033[1m$(MYSQL_PASSWORD)\033[00m;"
	@echo ''
	@echo "	docker exec -it $(CONTAINER_NAME)_db /bin/bash\n \
		mysql -p '$(MYSQL_ROOT_PASSWORD)'\n \
		GRANT ALL PRIVILEGES ON *.* TO '$(MYSQL_USER)'@'%' WITH GRANT OPTION;\n"
	$(COMPOSE_DEV) up -d --remove-orphans

# Start (alias for run)
start: run

# Stop and remove containers
stop:
	@echo "Stopping containers"
	$(COMPOSE_DEV) down --remove-orphans

# View container state
state:
	@docker ps -a | grep $(CONTAINER_NAME)

# View container logs
logs:
	@echo "Viewing logs for $(CONTAINER_NAME)"
	@if [ "$(NODE_ENVIRONMENT)" = "dev" ]; then \
		docker logs $(CONTAINER_NAME); \
		docker logs db; \
	else \
		docker logs $(CONTAINER_NAME)-web-1; \
		docker logs $(CONTAINER_NAME)-db-1; \
	fi

# Push the image to the registry
push:
	@echo "Pushing $(IMAGE_NAME):$(TAG) to $(REGISTRY)"
	@echo "Note: If the repository is an automated build, you may not be able to push"
	docker tag $(IMAGE_NAME):$(TAG) $(REGISTRY)/$(IMAGE_NAME):$(TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(TAG)

# Clean up images and cache
clean:
	@echo "Cleaning up Docker images and cache"
	docker rmi $(IMAGE_NAME):$(TAG) || true
	docker rmi $(IMAGE_NAME):latest || true
	docker system prune -f
