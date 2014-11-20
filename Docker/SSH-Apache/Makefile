# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d -p 80:80 --link mysqld:mysql --volumes-from www-data --name ssh-apache htmlgraphic/ssh-apache
build:
	docker build --rm -t htmlgraphic/ssh-apache .