docker build -t htmlgraphic/apache .

docker run -pd 80:80 --link mysql:mysql -v /Users/gegere/Dropbox/SITES:/var/www/html --name apache htmlgraphic/apache