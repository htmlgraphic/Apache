# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysql htmlgraphic/mysql 5.6/
build:
	docker build --rm -t htmlgraphic/mysql 5.6/
local:
	docker rm -f mysql && docker run --privileged -d -p 3306:3306 -v ~/Dropbox/SITES/Docker:/var/lib --name mysql htmlgraphic/mysql 5.6/
	# The local share folder needs permissions updated 'chmod 777' so mysql files can be written