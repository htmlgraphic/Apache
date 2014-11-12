run:
    docker run --privileged -p ${COREOS_PUBLIC_IPV4}:5422:22 --name www-data htmlgraphic/www-data
build:
    docker build --rm -t htmlgraphic/www-data .

#docker run -d --volumes-from dbdata --name db2 IMAGE_ID