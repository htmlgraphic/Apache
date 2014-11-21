# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

build:
	docker build --rm -t htmlgraphic/www-data .
run:
	docker run --privileged -d -p ${COREOS_PUBLIC_IPV4}:5422:22 -e HOSTNAME=data.htmlgraphic.com --name www-data htmlgraphic/www-data1
local:
	docker run --privileged -d -p 5422:22 -e HOSTNAME=data.htmlgraphic.com --name www-data htmlgraphic/www-data1
push:
	docker push htmlgraphic/www-data