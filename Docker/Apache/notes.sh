docker build -t htmlgraphic/apache .

docker run -pd 80:80 -v /Users/gegere/Dropbox/SITES:/var/www/html --name apache 98bc68337f5a