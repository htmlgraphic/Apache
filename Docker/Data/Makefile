# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run --privileged -p ${COREOS_PUBLIC_IPV4}:5422:22 --name www-data htmlgraphic/www-data
build:
	docker build --rm -t htmlgraphic/www-data .