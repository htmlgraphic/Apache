docker build -t htmlgraphic/mysql .
docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=U7eWsrqETxy2V htmlgraphic/mysql


#CONNECT TO MYSQL VIA BASH
docker run -it --rm --link mysql:mysql htmlgraphic/mysql bash -c 'mysql -h $MYSQL_PORT_3306_TCP_ADDR'







docker run -pd 3306:3306 --volumes-from dbdata -v /Users/gegere/Dropbox/SITES:/var/www/html --name mysql 7b8aa46407cc



