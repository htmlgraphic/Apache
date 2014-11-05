
#DATA CONTAINER
docker run -v /var/www/public_html --name www-data htmlgraphic/www-data



docker run -d --volumes-from dbdata --name db2 IMAGE_ID