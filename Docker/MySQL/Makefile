# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysql htmlgraphic/mysql 5.5/
build:
	docker build --rm -t htmlgraphic/mysql 5.5/
local:
	docker run -d -p 3306:3306 --volumes-from data --name mysql htmlgraphic/mysql
rm:
	docker rm -f mysql
data:
	docker run -i -t -name data -v /var/lib/mysql busybox /bin/sh