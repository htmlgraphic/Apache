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
	@echo "     make local        - Create a data container for $(NAME) and run $(NAME)"
	@echo "     make run          - Run $(NAME) container"
	@echo "     make start        - Start $(NAME) container"
	@echo "     make stop         - Stop $(NAME) container"
	@echo "     make restart      - Stop and start $(NAME) container"
	@echo "     make remove       - Stop and remove $(NAME) container"
	@echo "     make state        - View state $(NAME) container"
	@echo "     make logs         - View logs in real time"

build:
	docker build --rm -t $(IMAGE_NAME) 5.5/

run:
	@echo "Creating data container for $(NAME)..."
	#docker run -i -t --name data -v /var/lib/mysql busybox /bin/sh
	@echo "Run $(NAME)..."
	docker run -d -p 3306:3306 --volumes-from data --name $(NAME) $(IMAGE_NAME)

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