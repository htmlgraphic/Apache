# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysqld htmlgraphic/mysqld
build:
	docker build --rm -t htmlgraphic/mysqld .
local:
	docker run -d --volumes-from www-data --name mysqld htmlgraphic/mysqld