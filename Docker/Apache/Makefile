# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d -p 80:80 -p 443:443 -p 5422:22 --name apache htmlgraphic/apache
build:
	docker build --rm -t htmlgraphic/apache .
local:
	docker run -d -p 80:80 -p 443:443 --link mysql:mysql -v ~/Dropbox/SITES/docker:/data --name apache htmlgraphic/apache
rm:
	docker rm -f apache	
link:
	docker run -d -p 80:80 -p 443:443 --link mysqld:mysql --volumes-from www-data1 --name apache htmlgraphic/apache
