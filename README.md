
## Apache Docker

[![Run Status](https://api.shippable.com/projects/54cf015b5ab6cc13528a7b6a/badge?branch=master)](https://app.shippable.com/projects/54cf015b5ab6cc13528a7b6a)
[![Circle CI](https://circleci.com/gh/htmlgraphic/Apache/tree/master.svg?style=svg)](https://circleci.com/gh/htmlgraphic/Apache/tree/master) 
[![](https://images.microbadger.com/badges/image/htmlgraphic/apache:latest.svg)](https://microbadger.com/images/htmlgraphic/apache:latest "Get your own image badge on microbadger.com")
[![Beerpay](https://beerpay.io/htmlgraphic/Apache/badge.svg?style=beer)](https://beerpay.io/htmlgraphic/Apache) [![Beerpay](https://beerpay.io/htmlgraphic/Apache/make-wish.svg?style=flat)](https://beerpay.io/htmlgraphic/Apache)


This repo will give you a turn key Docker container build for use in **production** OR **dev**. The setup includes an Apache web service, PHP 7.3, PHP Composer, linked [MySQL 5.7.28](https://hub.docker.com/_/mysql) instance and a data container volume.

Using containers offer a huge advantage when developing locally or in prodcution. Use this containers for development and deployment. Changing `NODE_ENVIRONMENT` within to `.env` to `dev` or `production` will offer a dynamic environment.

Listed below is an explanation of each file. [Ask a question!](https://github.com/htmlgraphic/Apache/issues/new)

#### Dependencies
- Docker [Download](https://hub.docker.com/search/?type=edition&offering=community)
- Git
- Make ([Windows](https://stackoverflow.com/questions/32127524/how-to-install-and-use-make-in-windows-8-1))

---

## Build Breakdown

```shell
Apache                       # → Root of Docker Build
├── app/                     # → App conf to manage application on container
│   ├── apache-config.conf   # → Default Apache config
│   ├── index.php            # → Default web page, enter the IP `docker-machine ls` to load this page.
│   ├── mac-permissions.sh   # → Run manually on container to match uid / gid permissions of local docker container to Mac OS X
│   ├── postfix.sh           # → Used by *supervisord.conf* to start Postfix
│   ├── run.sh               # → Setup apache, conf files, and start process on container
│   ├── sample.conf          # → located within `/data/apache2/sites-enabled` duplicate / modify to host others domains
│   └── supervisord          # → Supervisor is a client / server system which monitors and controls a number of processes on UNIX-like operating systems
├── .env.example             # → Rename file to `.env` for local environment variables used within build
├── .circleci/
│   └── config.yml           # → CircleCI 2.0 Config
├── docker-compose.local.yml # → Dev build 
├── docker-compose.yml       # → Production build
├── Dockerfile               # → Uses a basefile build to help speed up the docker container build process
├── Makefile                 # → Build command shortcuts
├── shippable.yml            # → Configuration for Shippable.com testing
└── tests/
	└── build_tests.sh       # → Build test processes
```
Docker Compose YML configuration guide [more info](https://docs.docker.com/docker-cloud/apps/deploy-to-cloud-btn/) 


## Quick Start

Launch the **Apache** instance locally and setup a local MySQL database container for persistant database data, the goal is to create a easy to use development environment. 

The **Apache** container the directory `/data` is shared to your local system via **Line 7** within `docker-container.local.yml` file

### Mac OS X / Linux

>	Type `make` for more build options:

```bash
> git clone https://github.com/htmlgraphic/Apache.git ~/Docker/Apache && cd ~/Docker/Apache
> cp .env.example .env
> make run 
```

### (non Make Windows)
```bash
> copy .env.example .env
> docker-compose -f docker-compose.local.yml up -d
```


## phpMyAdmin

Review MySQL access instructions upon `make run` command execution. Setup phpMyAdmin directly via command line. https://localhost:8080 

```bash
> docker run --name myadmin -d --link apache_db:db --net apache_default -p 8080:80 phpmyadmin/phpmyadmin
```

Login using the following creditial stored within the .env file: 

|username  |password  |
|--|--|
|root | `$MYSQL_ROOT_PASSWORD`
|`$MYSQL_PASSWORD`  |`$MYSQL_PASSWORD`  |




## Test Driven Development
These continuous integration services will fully test the creation of your container and can push the complete image to your private Docker repo if you desire.


**[CircleCI 2.0](https://circleci.com/gh/htmlgraphic/Apache)** - Test **production** and **dev** Docker builds, can the container be built the without error? Verify each build process using docker-compose. Code can be tested using ```lxc-attach / docker inspect``` inside the running container


---

**[Shippable](https://shippable.com)** - Test **production** and **dev** Docker builds, can the container be built the without error? The ```/tests/build_tests.sh``` file ensures the can run with parameters defined. Shippable allows the use of [matrix environment variables](http://docs.shippable.com/ci_configure/#using-environment-variables) reducing build time and offer a more robust tests. If any test(s) fail the system should be reviewed closer.


## Interacting with Containers:

List all running containers:

`docker ps`


List all containers (including stopped containers):

`docker ps -a`


Review og of a running container:

`docker logs [CONTAINER ID OR NAME]`


Follow the log of a running container:

`docker logs -f [CONTAINER ID OR NAME]`


Read the Apache log:

`docker exec [CONTAINER ID OR NAME] cat ./data/apache2/logs/access_log`


Follow the Apache log:

`docker exec [CONTAINER ID OR NAME] tail -f ./data/apache2/logs/access_log`


Follow the outgoing mail log:

`docker exec [CONTAINER ID OR NAME] tail -f ./var/log/mail.log`


Gain terminal access to a running container:

`docker exec -it [CONTAINER ID OR NAME] /bin/bash`


Restart a running container:

`docker restart [CONTAINER ID OR NAME]`


Stop and start a container in separate operations:

`docker stop [CONTAINER ID OR NAME]`

`docker start [CONTAINER ID OR NAME]`


## Teardown 
#### (Stop all running containers started by Docker Compose):

### Mac OS X / Linux
```bash
> make rm 
```

### (non Make Windows)
```bash
> docker-compose stop
```
