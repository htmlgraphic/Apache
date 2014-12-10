# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysqld htmlgraphic/mysqld 5.6/
build:
	docker build --rm -t htmlgraphic/mysqld 5.6/
local:
	docker rm -f mysqld && docker run --privileged -d -v ~/Dropbox/SITES/Docker:/var/lib --name mysqld htmlgraphic/mysqld 5.6/
	# The local share folder needs permissions updated 'chmod 777' so mysql files can be written