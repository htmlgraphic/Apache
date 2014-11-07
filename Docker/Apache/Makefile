run:
    docker run -p 80:80 --link mysql:mysql --volumes-from www-data -v /home:/data/var/public_html --name apache htmlgraphic/apache
build:
    docker build -t htmlgraphic/apache .