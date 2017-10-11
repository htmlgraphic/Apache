# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

VERSION 	= 1.7.0
NAME 		= apache
IMAGE_REPO 	= htmlgraphic
IMAGE_NAME 	= $(IMAGE_REPO)/$(NAME)
DOMAIN 		= htmlgraphic.com

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
	docker build \
        --build-arg VCS_REF=`git rev-parse --short HEAD` \
        --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
        --rm -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):envoyer .

push:
	@echo "note: If the repository is set as an automatted build you will NOT be able to push"
	docker push $(IMAGE_NAME):$(VERSION)

run:
	[ ! -f .env ] && echo '.env file does not exist, copy env template' && cp .env.example .env || echo "env file exists"
	@echo "# Upon initial setup run the following on the MySQL system:"
	@echo ""
	@echo "mysql -p <MYSQL_ROOT_PASSWORD>"
	@echo "GRANT ALL PRIVILEGES ON * . * TO 'admin'@'%' with grant option;"
	@echo ""
	docker-compose -f docker-compose.local.yml up -d

start: run

stop:
	@echo "Stopping local environment setup"
	docker-compose stop

restart:	stop start

rm:
	@echo "# As a precautionary measure containers are specifally referenced to not destroy DB data"
	@echo "Removing $(NAME)_web_1 and $(NAME)_db_1"
	docker rm -f $(NAME)_web_1
	docker rm -f $(NAME)_db_1

state:
	docker ps -a | grep $(NAME)_web_1

logs:
	@echo "Build $(NAME)..."
	docker logs -f $(NAME)_web_1
