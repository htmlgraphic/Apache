# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

NAME = apache
IMAGE_REPO = htmlgraphic
IMAGE_NAME = $(IMAGE_REPO)/$(NAME)
DOMAIN = htmlgraphic.com

all:: help


help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "     make build        - Build the $(NAME) image"
	@echo "     make local        - Local development, link to local system and run $(NAME)"
	@echo "     make link         - Link $(NAME) container to MySQL and Data container"
	@echo "     make run          - Run $(NAME) container"
	@echo "     make start        - Start the EXISTING $(NAME) container"
	@echo "     make stop         - Stop $(NAME) container"
	@echo "     make restart      - Stop and start $(NAME) container"
	@echo "     make remove       - Stop and remove $(NAME) container"
	@echo "     make state        - View state $(NAME) container"
	@echo "     make logs         - View logs in real time"

build:
	docker build --rm -t $(IMAGE_NAME) .

local:
	docker run -d -p 80:80 -p 443:443 --link mysql:mysql -v ~/Dropbox/SITES/docker:/data --name $(NAME) $(IMAGE_NAME)

link:
	docker run -d -p 80:80 -p 443:443 --link mysqld:mysql --volumes-from www-data1 --name $(NAME) $(IMAGE_NAME)

run:
	docker run -d --restart=always -p 80:80 -p 443:443 -p 5422:22 --name $(NAME) $(IMAGE_NAME)

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