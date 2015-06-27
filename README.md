[![Build Status](https://api.shippable.com/projects/54cf015b5ab6cc13528a7b6a/badge?branchName=master)](https://app.shippable.com/projects/54cf015b5ab6cc13528a7b6a/builds/latest) [![Circle CI](https://circleci.com/gh/htmlgraphic/Apache/tree/master.svg?style=svg&circle-token=6f8463477c38cc56c01834f54deaaac355916654)](https://circleci.com/gh/htmlgraphic/Apache/tree/master)


##Quick Start
```bash
	$ git clone https://github.com/htmlgraphic/Apache.git && cd Apache
	$ make
	$ make build
	$ make run
```

##Apache Docker

Apache is a great web service. This repo will give you a turn key, fully functional build of a Docker container for use in production or your dev environment.

---

If you found this repo you are probably looking into Docker or already have knowledge as to what Docker can help you with. In this repo you will find a number of complete Dockerfile builds used in **development** and **production** environments. Listed below are the types of systems available and an explanation of each file. 

###Repo Breakdown
* [**CoreOS**](https://github.com/htmlgraphic/CoreOS) - Scripts used for the loading of services into Fleet managing Docker containers on CoreOS
* [**Docker**](https://github.com/htmlgraphic/Docker) - Build scripts the creation of my different types of servers. 


#####Test Driven Development
Consistent testing is important when making any edits, large or small. By using test driven development you can save a great deal of time making sure no buggy code makes it into production environments. This build uses CircleCI and Shippable to test the final build.

**[CircleCI](https://circleci.com/gh/htmlgraphic/Postfix)** - Test the Dockerfile process, can the container be built the correctly? Verify the build process with a number of tests. Currently with this service no code can be tested on the running container. Data can be echo and available grepping the output via `docker logs | grep value`

[![Circle CI](https://circleci.com/gh/htmlgraphic/Apache/tree/master.svg?style=svg&circle-token=6f8463477c38cc56c01834f54deaaac355916654)](https://circleci.com/gh/htmlgraphic/Apache/tree/master)

**[Shippable](https://shippable.com)** - Run tests on the actual built container. These tests ensure the scripts have been setup properly and the service can start with parameters defined. If any test(s) fail the system should be reviewed closer.

[![Build Status](https://api.shippable.com/projects/54cf015b5ab6cc13528a7b6a/badge?branchName=develop)](https://app.shippable.com/projects/54cf015b5ab6cc13528a7b6a/builds/latest)


---

* To use [CircleCI](https://circleci.com/gh/htmlgraphic/Docker) review the `circle.yml` file. 
* To use [Shippable](http://shippable.com) review the `shippable.yml` file. This service will use a `circle.yml` file configuration but for the unique features provided by **Shippable** it is best to use the deadicated `shippable.yml` file. This service will fully test the creation of your container and can push the complete image to your private Docker repo if you desire.

---


#####Apache Web Server - Instance Breakdown
* **.dockerignore** - Files that should be ignored during the build process - [best practices](https://docs.docker.com/articles/dockerfile_best-practices/#use-a-dockerignore-file)
* **app/apache-config.conf** - The default configuration used by Apache
* **app/index.php** - Default page displayed via Apache, type in the IP address of the running container and this page should load
* **app/mac-permissions.sh** - Run manually on container to match uid / gid permissions of local docker container to Mac OS X
* **app/postfix-local-setup.sh** - Script ran manually on container to direct email to a gated email relay server, no emails are sent out to actual inboxes
* **app/postfix.sh** - Used by *supervisord.conf* to start Postfix
* **app/run.sh** - Setup apache, move around conf files, start process on container
* **app/sample.conf** - A copy of this fill will exist within `/data/apache2/sites-enabled` duplicate to host various domains
* **app/supervisord.conf** - Supervisor is a client / server system that allows its users to monitor and control a number of processes on UNIX-like operating systems
* **tests/build_tests.sh** - Build processes
* **.dockerignore** - Files that should be ignored during the build process - [best practices](https://docs.docker.com/articles/dockerfile_best-practices/#use-a-dockerignore-file)
* **circle.yml** - CircleCI configuration
* **Dockerfile** - Uses a basefile build to help speed up the docker container build process
* **Makefile** - A helpful file used to streamline the creation of containers
* **shippable.yml** - Shippable configuration
