##Apache Docker

This repo will give you a turn key Docker container build for use in production OR local development. The setup includes an Apache web service, linked MySQL instance and a data container volume.


If you found this repo you are probably looking into Docker or already have knowledge as to what Docker can help you with. In this repo you will find a number of complete Dockerfile builds used in **development** and **production** environments. Listed below is an explanation of each file

---

####Apache Web Server - Build Breakdown
* **app/apache-config.conf** - Default configuration used by Apache
* **app/index.php** - Default web page, enter the IP address `docker-machine ls` to load this page.
* **app/mac-permissions.sh** - Run manually on container to match uid / gid permissions of local docker container to Mac OS X
* **app/postfix-local-setup.sh** - Run manually on container to direct email to a gated email relay server, no emails are sent out to actual inboxes
* **app/postfix.sh** - Used by *supervisord.conf* to start Postfix
* **app/run.sh** - Setup apache, conf files, and start process on container
* **app/sample.conf** - located within `/data/apache2/sites-enabled` duplicate / modify to host others domains
* **app/supervisord.conf** - Supervisor is a client / server system which monitors and controls a number of processes on UNIX-like operating systems
* **.dockerignore** - Files that should be ignored during the build process - [best practice](https://docs.docker.com/articles/dockerfile_best-practices/#use-a-dockerignore-file)
* **.env.example** - Rename file to `.env` for local environment variables used within build
* **circle.yml** - CircleCI conf
* **docker-compose.\*** - (various composer files for local and production builds) [more info](https://docs.docker.com/docker-cloud/apps/deploy-to-cloud-btn/)
* **Dockerfile** - Uses a basefile build to help speed up the docker container build process
* **Makefile** - A helpful file used to streamline build commands
* **shippable.yml** - Shippable conf
* **tests/build_tests.sh** - Build test processes



---

[![](https://badge.imagelayers.io/htmlgraphic/apache:latest.svg)](https://imagelayers.io/?images=htmlgraphic/apache:latest 'Get your own badge on imagelayers.io') Visualize Docker images and the layers that compose them.

---

##Docker Compose

Launch the **Apache** instance locally and setup a local MySQL database container for persistant database data, the goal is to create a easy to use development environment. Type `make` for more build options

```bash
	$ git clone https://github.com/htmlgraphic/Apache.git && cd Apache
	$ make run
```

---

[![Deploy to Docker Cloud](https://files.cloud.docker.com/images/deploy-to-dockercloud.svg)](https://cloud.docker.com/stack/deploy/)


---

##Test Driven Development

**[CircleCI](https://circleci.com/gh/htmlgraphic/Apache)** - Test **production** and **dev** Docker builds, can the container be built the without error? Verify each build process using docker-compose. Code can be tested using ```lxc-attach / docker inspect``` inside the running container.

[![Circle CI](https://circleci.com/gh/htmlgraphic/Apache/tree/develop.svg?style=svg)](https://circleci.com/gh/htmlgraphic/Apache/tree/develop)

Using **CircleCI** review the `circle.yml` file. 

---

**[Shippable](https://shippable.com)** - Test **production** and **dev** Docker builds, can the container be built the without error? The ```/tests/build_tests.sh``` file ensures the can run with parameters defined. Shippable allows the use of [matrix environment variables](http://docs.shippable.com/ci_configure/#using-environment-variables) reducing build time and offer a more robust tests. If any test(s) fail the system should be reviewed closer.

[![Run Status](https://api.shippable.com/projects/54cf015b5ab6cc13528a7b6a/badge?branch=develop)](https://app.shippable.com/projects/54cf015b5ab6cc13528a7b6a)

Using **Shippable** review the `shippable.yml` file. This continuous integration service will fully test the creation of your container and can push the complete image to your private Docker repo if you desire.
