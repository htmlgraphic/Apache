# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysqld htmlgraphic/mysqld
build:
	docker build --rm -t htmlgraphic/mysqld .


#CONNECT TO MYSQL VIA BASH
#docker run -it --rm --link mysql:mysql htmlgraphic/mysql bash -c 'mysql -h $MYSQL_PORT_3306_TCP_ADDR'

#docker run -pd 3306:3306 --volumes-from dbdata -v /Users/gegere/Dropbox/SITES:/var/www/html --name mysql 7b8aa46407cc

