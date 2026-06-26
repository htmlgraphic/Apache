
## Apache Docker

![Circle CI](https://circleci.com/gh/htmlgraphic/Apache/tree/develop.svg?style=svg)

This repo provides a Dockerized Apache/PHP environment for **production** or **dev**. The current stack is based on Ubuntu 24.04, Apache 2.4, PHP 8.3, Composer 2, MariaDB 10.6, Postfix relay support, and a persistent data volume.

Using containers offers a consistent development and deployment target. Set `NODE_ENVIRONMENT` in `.env` to `dev` or `production` to adjust runtime behavior.

[Ask a question!](https://github.com/htmlgraphic/Apache/issues/new)


---

## Build Breakdown

```shell
Apache
├── app/                     # → App conf to manage application on container
│   ├── index.php            # → Default web page, enter the IP `docker-machine ls` to load this page.
│   ├── php_extensions.php   # → PHP extensions checklist
│   ├── mac-permissions.sh   # → Run manually on container to match uid / gid permissions of local docker container to Mac OS X
│   ├── postfix.sh           # → Used by *supervisord.conf* to start Postfix
│   ├── entrypoint.sh        # → Setup apache, conf files, and start process on container
│   ├── sample.conf          # → Located within `/data/apache2/sites-enabled` duplicate / modify to add domains
│   └── supervisord          # → Supervisor is a system which monitors and controls a number of processes
├── .env.example             # → Copy to `.env` for local runtime environment variables
├── .circleci/
│   └── config.yml           # → CircleCI 2.0 Config
├── docker-compose.local.yml # → Dev build 
├── docker-compose.yml       # → Production build
├── Dockerfile               # → Uses a basefile build to help speed up the docker container build process
├── Makefile                 # → Build command shortcuts
└── tests/
	├── build_tests.sh       # → Build test processes
	└── shunit2-2.1.7.tar.gz # → sh unit teesting
```


## Dependencies
- Docker [Download](https://hub.docker.com/search/?type=edition&offering=community)
- Git
- Make ([Windows](https://stackoverflow.com/questions/32127524/how-to-install-and-use-make-in-windows-8-1))

---

## Quick Start

Launch the **Apache** instance locally and set up a local MariaDB database container with persistent database data.

The **Apache** container shares `/data` with your local system through the bind mount in `docker-compose.local.yml`.

Docker Compose File Reference [more info](https://docs.docker.com/compose/compose-file/) 

Open `docker-compose.local.yml` and review the `web.volumes` path. This path links files from your local development environment into the container at `/data`.


### Mac OS X / Linux

>	Type `make` for more build options:

```bash
~ git clone https://github.com/htmlgraphic/Apache.git ~/Docker/Apache && cd ~/Docker/Apache
~ cp .env.example .env
~ make run 
```

Build a smaller production-oriented image without local dev tools:

```bash
make build INSTALL_DEV_TOOLS=false
```

### Windows

```bash
> git clone git@github.com:htmlgraphic/Apache.git ~/Docker/Apache; cd ~/Docker/Apache
> copy .env.example .env
> docker-compose -f docker-compose.local.yml up -d
```

> If Windows firewall rules block local testing, prefer adding explicit Docker/Desktop firewall rules instead of disabling the firewall globally.

```bash
> netsh advfirewall show currentprofile
```

---

## Security Notes

- `.env` is a runtime file and is intentionally excluded from Git and Docker build contexts.
- Do not put real credentials in `.env.example`; keep it limited to placeholders.
- Production MariaDB is only exposed on the Docker network by default. Apache can connect to the database as `db:3306`, but host port `3306` is not published.
- SMTP relay credentials are configured at container startup from environment variables and are not baked into the image.
- `LOG_TOKEN`, `SASL_PASS`, and database passwords should not be printed in CI or container logs.


---


### Google Cloud

Use the following command with Google Compute. This will create a [virtual machine instance](https://cloud.google.com/sdk/gcloud/reference/beta/compute/instances/create-with-container) running [COS](https://cloud.google.com/container-optimized-os/) (Container Operating System).


`.env.LIVE` will need to exist within the directory you execute the following command from:
```bash
gcloud compute instances create-with-container www0 --zone us-central1-b --tags=https-server,http-server --machine-type f1-micro --container-env-file .env.LIVE --container-image=docker.io/htmlgraphic/apache:envoyer
```

Need to update the container config? Use the following command, the `.env` will be redeploy with the updated configuration.
```bash
gcloud compute instances update-container www0 --zone us-central1-b --container-env-file .env.LIVE
```


Renew each domain manually to verify the certificate will be created succesfully. Each certificate will be valid for 90 days, there is a limit of certificates minted per ip address.


**LetsEncrypt Cert Renewal Process:**
```bash
docker run --rm --name temp_certbot \
	-v /var/data/letsencrypt:/etc/letsencrypt \
	-v /var/lib/letsencrypt:/var/lib/letsencrypt \
	-v /var/data:/data \
	certbot/certbot:v1.15.0 \
	certonly --webroot --agree-tos --renew-by-default \
	--server https://acme-v02.api.letsencrypt.org/directory \
	--text --email hosting@htmlgraphic.com \
	-w /data/www/XYZ/public_html -d example.com -d www.example.com
```

Set the following cron task, when host system is restarted, start instance will start on boot:
```bash
sudo su
crontab -e
@reboot (sleep 10s ; cd /root/Docker/Apache ; /usr/local/bin/docker-compose up -d )&
```


---


## phpMyAdmin

Review database access instructions upon `make run` command execution. Login using the credentials stored within the `.env` file:

|User  | Pass  |
|:--|--|
|root | `$MYSQL_ROOT_PASSWORD`
|`$MYSQL_USER`  |`$MYSQL_PASSWORD`  |


Set up phpMyAdmin directly via command line and access it using port `8080`:

```bash
> docker run --name myadmin -d --link db:mysql --net apache_app-network -p 8080:443 osixia/phpmyadmin:4.9.2
```


Using the configuration set within the `docker-compose.local.yml` PHPMyAdmin can be hosted using a valid certificate, the same certificate you might be using within the parent domain.

Under `volumes` there is a sharing of files between `host` and `container` this will allow PHPMyAdmin to use a valid certificate. Match up the following files: `cert.pem` `privkey.pem` `fullchain.pem`




## Test Driven Development
These continuous integration services will fully test the creation of your container and can push the complete image to your private Docker repo if you desire.


**[CircleCI 2.0](https://circleci.com/gh/htmlgraphic/Apache)** - Test **production** and **dev** Docker builds, can the container be built the without error? Verify each build process using docker-compose. Code can be tested using ```lxc-attach / docker inspect``` inside the running container


---


## Interacting with Containers:

List all running containers:

`docker ps`


List all containers (including stopped containers):

`docker ps -a`


Review logs of a running container:

`docker logs [CONTAINER ID OR NAME]`


Follow the logs of a running container:

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
> docker-compose down
```

### (non Make Windows)
```bash
> docker-compose stop
```
