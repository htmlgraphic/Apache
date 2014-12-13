# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

NAME = mysql
IMAGE_REPO = htmlgraphic
IMAGE_NAME = $(IMAGE_REPO)/$(NAME)
DOMAIN = htmlgraphic.com

all:: help


help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "     make build        - Build the $(NAME) image"
	@echo "     make run          - Run $(NAME) container"
	@echo "     make start        - Start $(NAME) container"
	@echo "     make stop         - Stop $(NAME) container"
	@echo "     make restart      - Stop and start $(NAME) container"
	@echo "     make purge        - Stop and remove $(NAME) container"
	@echo "     make state        - View state $(NAME) container"
	@echo "     make logs         - View logs in real time"

run:
	docker run -d --volumes-from www-data --name mysql htmlgraphic/mysql 5.5/
build:
	docker build --rm -t htmlgraphic/mysql 5.5/
local:
	docker run -d -p 3306:3306 --volumes-from data --name mysql htmlgraphic/mysql
rm:
	docker rm -f mysql
data:
	docker run -i -t --name data -v /var/lib/mysql busybox /bin/sh