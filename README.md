[![Build Status](https://api.shippable.com/projects/548b5d23d46935d5fbc01275/badge?branchName=master)](https://app.shippable.com/projects/548b5d23d46935d5fbc01275/builds/latest) [![Docker Build Status](https://circleci.com/gh/htmlgraphic/Docker/tree/develop.svg?style=svg&circle-token=b51ac0eded585009395fde219719b0c86f5320d2)](https://circleci.com/gh/htmlgraphic/Docker/tree/master)

##Quick Start
```bash
    $ git clone https://github.com/htmlgraphic/Docker.git && cd Docker
    $ cd Docker/Apache
    $ make
    $ make build
```

If you found this repo you are probably looking into Docker or already have knowledge as to what Docker can help you with. In this repo you will find a number of complete Dockerfile builds used in **development** and **production** environments. Listed below are the types of systems available and an explanation of each file. 

* Docker is a containerization system that utilized LXC known as Linux containers, uses kernel names pacing a cgroups in order to isolate processes.
* Docker containers can run side-by-side with other containers, but act as an individual server.

###Repo Breakdown
* [**CoreOS**](https://github.com/htmlgraphic/CoreOS) - Scripts used for the loading of services into Fleet managing Docker containers on CoreOS
* [**Docker**](https://github.com/htmlgraphic/Docker) - Build scripts the creation of my different types of servers. 


#####Apache Web Server
* **.dockerignore** - Files that should be ignored during the build process
* **apache-config.conf** - The default configuration used by Apache
* **Dockerfile** - Uses a basefile build to help speed up the docker container build process
* **index.php** - Default page displayed via Apache, type in the IP address of the running container and this page should load
* **mac-permissions.sh** - Run manually on container to match uid / gid permissions of local docker container to Mac OS X
* **Makefile** - A helpful file used to streamline the creation of containers
* **postfix-local-setup.sh** - Script ran manually on container to direct email to a gated email relay server, no emails are sent out to actual inboxes
* **postfix.sh** - Used by *supervisord.conf* to start Postfix
* **run.sh** - Setup apache, move around conf files, start process on container
* **sample.conf** - Move and edit this file into `/data/apache2/sites-enabled` to host the various domains you need to host
* **supervisord.conf** - Supervisor is a client/server system that allows its users to monitor and control a number of processes on UNIX-like operating systems

#####Base Container
* A base container used by other builds to make the creation process faster

#####Data Container
* Files and data for Apache is stored here 

#####[Postfix Mail Server](https://github.com/htmlgraphic/Postfix)
* [Github Repo](https://github.com/htmlgraphic/Postfix)

#####MySQL server
* `make build`
* `make run` create a stateless data container and start a MySQL instance storing data on the simple **Busybox** data container


##Build Tests
As you continue to build more containers and extend functions, a very useful tool is using a *test driven development* solution. This repo is setup to use [CircleCI](https://circleci.com/gh/htmlgraphic/Docker) and have numerous tests set within `circle.yml`. It is very good to know that your built containers pass all the tests you define before setup in production.


