# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d -p 80:80 --link mysqld:mysqld --name apache htmlgraphic/apache
build:
	docker build --rm -t htmlgraphic/apache .