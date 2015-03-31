# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

NAME = apache
IMAGE_REPO = htmlgraphic
VERSION = 1.1.0
IMAGE_NAME = $(IMAGE_REPO)/$(NAME)
DOMAIN = htmlgraphic.com

all:: help


help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "     make build        - Build image $(IMAGE_NAME)"
	@echo "     make push         - Push $(IMAGE_NAME) to public docker repo"
	@echo "     make local        - Link $(NAME) to MySQL, access local system files and run $(NAME)"
	@echo "     make link         - Link $(NAME) to MySQL and run $(NAME)"
	@echo "     make run          - Run $(NAME) container"
	@echo "     make start        - Start the EXISTING $(NAME) container"
	@echo "     make stop         - Stop $(NAME) container"
	@echo "     make restart      - Stop and start $(NAME) container"
	@echo "     make remove       - Stop and remove $(NAME) container"
	@echo "     make state        - View state $(NAME) container"
	@echo "     make logs         - View logs in real time"

build:
	docker build --rm -t $(IMAGE_NAME):$(VERSION) .

push:
	docker push $(IMAGE_NAME)

local:
	docker run -d -p 80:80 -p 443:443 -e NODE_ENVIRONMENT="local" --link mysql:mysql -v ~/Dropbox/SITES/docker:/data --name $(NAME) $(IMAGE_NAME):$(VERSION)

link:
	docker run -d -p 80:80 -p 443:443 -e NODE_ENVIRONMENT="production" --link mysqld:mysql --volumes-from www-data1 --name $(NAME) $(IMAGE_NAME):$(VERSION)

run:
	docker run -d -p 80:80 -p 443:443 -e NODE_ENVIRONMENT="production" --restart=always --name $(NAME) $(IMAGE_NAME):$(VERSION)

start:
	@echo "Starting $(NAME)..."
	docker start $(NAME) > /dev/null

stop:
	@echo "Stopping $(NAME)..."
	docker stop $(NAME) > /dev/null

restart: stop start

remove: stop
	@echo "Removing $(NAME)..."
	docker rm $(NAME) > /dev/null

state:
	docker ps -a | grep $(NAME)

logs:
	@echo "Build $(NAME)..."
	docker logs -f $(NAME)