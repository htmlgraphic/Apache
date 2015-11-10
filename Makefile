# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

VERSION 			= 1.2.5
NAME 				= apache
IMAGE_REPO 	= htmlgraphic
IMAGE_NAME 	= $(IMAGE_REPO)/$(NAME)
DOMAIN 			= htmlgraphic.com

all:: help


help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "     make build		- Build image $(IMAGE_NAME):$(VERSION)"
	@echo "     make push		- Push $(IMAGE_NAME):$(VERSION) to public docker repo"
	@echo "     make run		- Run docker-compose and create local development environment"
	@echo "     make start		- Start the EXISTING $(NAME) container"
	@echo "     make stop		- Stop local environment build"
	@echo "     make restart	- Stop and start $(NAME) container"
	@echo "     make rm		- Stop and remove $(NAME) container"
	@echo "     make state		- View state $(NAME) container"
	@echo "     make logs		- View logs in real time"

build:
	docker build --rm --no-cache -t $(IMAGE_NAME):$(VERSION) .
	docker build --rm --no-cache -t $(IMAGE_NAME):latest .

push:
	@echo "note: If the repository is set as an automatted build you will NOT be able to push"
	docker push $(IMAGE_NAME):$(VERSION)

run:
	docker-compose -f docker-compose.local.yml up -d

start:
	@echo "Starting $(NAME)..."
	docker start $(NAME) > /dev/null

stop:
	@echo "Stopping local environment setup"
	docker-compose stop

restart:	stop start

rm:
	@echo "Removing $(NAME) and $(NAME)_db_1"
	docker rm -f $(NAME)
	docker rm -f $(NAME)_db_1

state:
	docker ps -a | grep $(NAME)

logs:
	@echo "Build $(NAME)..."
	docker logs -f $(NAME)
