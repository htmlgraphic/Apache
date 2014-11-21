# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

build:
	docker build --rm -t htmlgraphic/www-data .
run:
	docker run --privileged -p ${COREOS_PUBLIC_IPV4}:5422:22 --name www-data htmlgraphic/www-data
local:
	docker run --privileged -p 5422:22 -d --name www-data htmlgraphic/www-data
push:
	docker push htmlgraphic/www-data