# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d -p 25:25 --name postfix -e USER=XXXX -e PASS=XXXX -e HOSTNAME=post-office.htmlgraphic.com htmlgraphic/postfix
build:
	docker build --rm -t htmlgraphic/postfix .
rm:
	docker rm -f postfix