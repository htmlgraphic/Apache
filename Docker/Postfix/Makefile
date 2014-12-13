# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

NAME = postfix
IMAGE_REPO = htmlgraphic
IMAGE_NAME = $(IMAGE_REPO)/$(NAME)
HOSTNAME = post-office.htmlgraphic.com
DOMAIN = htmlgraphic.com
USER = XXXX
PASS = XXXX

all:: help


help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "     make build        - Build the postfix image"
	@echo "     make run          - Run postfix container"
	@echo "     make start        - Start postfix container"
	@echo "     make stop         - Stop postfix container"
	@echo "     make restart      - Stop and start postfix container"
	@echo "     make purge        - Stop and remove postfix container"
	@echo "     make state        - View state postfix container"
	@echo "     make logs         - View logs in real time"

build:
	@echo "Build postfix..."
	docker build -t $(IMAGE_NAME) .

run:
	@echo "Run postfix..."
	docker run -d -p 25:25 --name $(NAME) -e USER=USER -e PASS=PASS -e HOSTNAME=HOSTNAME $(IMAGE_NAME)

start:
	@echo "Starting postfix..."
	docker start $(NAME) > /dev/null

stop:
	@echo "Stopping postfix..."
	docker stop $(NAME) > /dev/null

restart: stop start

remove: stop
	@echo "Removing postfix..."
	docker rm $(NAME) > /dev/null

state:
	docker ps -a | grep $(NAME)

logs:
	@echo "Build postfix..."
	docker logs -f postfix