# Build a container via the command "make build"
# By Jason Gegere <jason@htmlgraphic.com>

all:: build

run:
	docker run -d --volumes-from www-data --name mysql htmlgraphic/mysql 5.6/
build:
	docker build --rm -t htmlgraphic/mysql 5.6/
local:
	docker run -d -p 3306:3306 -v /Users/gegere/Dropbox/SITES/Docker/db:/var/lib/mysql --name mysql htmlgraphic/mysql
	# The local share folder needs permissions updated 'chmod 777' so mysql dirs/files can be written, update permissions and rerun build
rm:
	docker rm -f mysql