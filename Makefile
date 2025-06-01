# Makefile for Docker build, test, and run workflow
# By Jason Gegere <jason@htmlgraphic.com>

# Variables
IMAGE_NAME := htmlgraphic/apache
TAG := 2.1.0
REGISTRY := docker.io
CONTAINER_NAME := apache
ENV_FILE := .env
PLATFORM := linux/arm64
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
all: env help

# Help menu
help:
	@echo ""
	@echo "-- Help Menu for $(IMAGE_NAME):$(TAG)"
	@echo ""
	@echo "     make build        - Build Image"
	@echo "     make clean        - Remove images and prune system"
	@echo "     make env          - Create and list .env variables"
	@echo "     make logs         - View logs"
	@echo "     make push         - Push $(IMAGE_NAME):$(TAG) to public Docker repo"
	@echo "     make run          - Run docker-compose and create local environment"
	@echo "     make start        - Start the EXISTING $(CONTAINER_NAME) container"
	@echo "     make state        - View state of $(CONTAINER_NAME) container"
	@echo "     make stop         - Stop running containers"
	@echo "     make test         - Test components in existing $(CONTAINER_NAME) container"

# Create .env if missing
env:
	@[ ! -f $(ENV_FILE) ] && echo "	.env file does not exist, copying template\n" && cp .env.example $(ENV_FILE) || echo "	.env file exists\n"
	@echo "The following environment variables exist:"
	@echo $(shell sed 's/=.*//' $(ENV_FILE))
	@echo ''

# Build the Docker image
build:
	@echo "Building Docker image $(IMAGE_NAME):$(TAG)..."
	@if [ -n "$$(docker images -q $(IMAGE_NAME):$(TAG))" ]; then \
		echo "Image $(IMAGE_NAME):$(TAG) already exists."; \
		printf "Do you want to rebuild the image? (y/N): "; \
		read confirm; \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			echo "Rebuilding Docker image $(IMAGE_NAME):$(TAG)..."; \
			docker build --no-cache --platform $(PLATFORM) -t $(IMAGE_NAME):$(TAG) .; \
		else \
			echo "Skipping build."; \
		fi; \
	else \
		echo "Image does not exist, building..."; \
		docker build --platform $(PLATFORM) -t $(IMAGE_NAME):$(TAG) .; \
	fi

# Test the existing container
test:
	@echo "Testing components in existing $(CONTAINER_NAME) container"
	@for i in $$(seq 1 30); do \
		CONTAINER_STATUS=$$(docker inspect --format='{{.State.Status}}' $(CONTAINER_NAME) 2>/dev/null || echo "not_found"); \
		if [ "$$CONTAINER_STATUS" = "running" ]; then \
			if docker exec $(CONTAINER_NAME) sh -c "[ -f /etc/supervisor/conf.d/services.conf ]" 2>/dev/null; then \
				if docker exec $(CONTAINER_NAME) sh -c "[ -S /var/run/supervisor.sock ]" 2>/dev/null; then \
					echo "Container and supervisor socket are ready"; \
					break; \
				else \
					echo "Waiting for supervisor socket ($$i/30)"; \
					sleep 2; \
				fi; \
			else \
				echo "Error: Supervisor configuration file /etc/supervisor/conf.d/services.conf not found"; \
				exit 1; \
			fi; \
		elif [ "$$CONTAINER_STATUS" = "restarting" ]; then \
			echo "Container is restarting, waiting ($$i/30)"; \
			sleep 2; \
		elif [ "$$CONTAINER_STATUS" = "not_found" ]; then \
			echo "Error: Container $(CONTAINER_NAME) is not running. Run 'make run' or 'make start' first."; \
			exit 1; \
		else \
			echo "Error: Container $(CONTAINER_NAME) is in unexpected state: $$CONTAINER_STATUS"; \
			exit 1; \
		fi; \
		if [ $$i -eq 30 ]; then \
			echo "Error: Container failed to stabilize or supervisor socket missing after 60 seconds"; \
			exit 1; \
		fi; \
	done
	@docker exec $(CONTAINER_NAME) apache2ctl configtest || { echo "apache2 config test failed"; exit 1; }
	@docker exec $(CONTAINER_NAME) supervisorctl -c /etc/supervisor/conf.d/services.conf status | grep -E 'cron.*RUNNING|postfix.*RUNNING|rsyslog.*RUNNING' | wc -l | grep -q 3 || { echo "supervisorctl status test failed: not all processes are RUNNING"; docker exec $(CONTAINER_NAME) supervisorctl -c /etc/supervisor/conf.d/services.conf status; exit 1; }
	@docker exec $(CONTAINER_NAME) composer --version || { echo "composer test failed"; exit 1; }
	@if [ "$(NODE_ENVIRONMENT)" = "dev" ]; then \
		docker exec $(CONTAINER_NAME) git --version || { echo "git test failed"; exit 1; }; \
		docker exec $(CONTAINER_NAME) vim --version || { echo "vim test failed"; exit 1; }; \
		docker exec $(CONTAINER_NAME) ping -V || { echo "ping test failed"; exit 1; }; \
		docker exec $(CONTAINER_NAME) wget --version || { echo "wget test failed"; exit 1; }; \
	fi
	@docker exec $(CONTAINER_NAME) mysql --version || { echo "mysql test failed"; exit 1; }
	@docker exec $(CONTAINER_NAME) php -m | grep redis || { echo "php redis module test failed"; exit 1; }
	@docker exec $(CONTAINER_NAME) dpkg -l | grep -E 'mailutils|locales' || { echo "dpkg test failed"; exit 1; }

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
