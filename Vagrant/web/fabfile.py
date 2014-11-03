"""
This Fabfile contains the bootstrap and deploy methods plus related
subroutines required to deploy with the Mail Checkup service.

`bootstrap` and `deploy` are executed as the command line ``fab`` program
and takes care of setting up a new system, installing required libraries
or programs, setting up the server, and deploying the newest version of the
website from github.

`fab environment action`

Available Environments:     Available Actions:
dev                         bootstrap:  Sets up system by installing programs,
production                              runs deploy afterwards
staging                     deploy:     uploads conf/ files and gets newest code
                                        from github
                            get_database:will get the database rip from that
                                        server and store it in conf/
                            put_templates:will upload the newest templates from
                                          the conf/ directory

Useful commands:
`fab dev bootstrap` : after running vagrant up, this will install MailCheckup
                      locally
`fab dev deploy` : this should be used to update to the newest version of the
                   website locally
`fab production deploy` : deploys the newest version of the website LIVE

The other callables defined in this module are internal only.
"""

from __future__ import with_statement
from fabric.contrib.files import exists, append, upload_template
from fabric.contrib.project import rsync_project
from fabric.colors import white, blue, red
from fabric.api import env, run as _run, sudo, local, put, cd, settings, hide, prompt, get
from fabric.utils import puts
from pprint import pprint

import time
import os

#environment variables shared
#env.ssh_config_path = 'conf/ssh_config'
#env.use_ssh_config = True
env.forward_agent = True
env.debug = False
env.db_root_password = None
env.templates = {}
env.colors = True

def config_templates():
    env.templates = {
    # "apache": {
    #     "local_path": "conf/vhosts.conf",
    #     "remote_directory": "/etc/apache2/sites-available/",
    #     "remote_path": "/etc/apache2/sites-available/%s.conf" % env.project_name,
    # },
    "php": {
        "local_path": "conf/php.ini",
        "remote_directory": "/etc/php5/apache2/",
        "remote_path": "/etc/php5/apache2/php.ini",
    },
    # "cron": {
    #     "local_path": "conf/crontab",
    #     "remote_directory": "/etc/cron.d/",
    #     "remote_path": "/etc/cron.d/%s" % env.project_name,
    #     "owner": "root",
    #     "mode": "600",
    # },
    # "sslcert": {
    #     "local_path": "conf/www.mailcheckup.com/ssl.crt",
    #     "remote_directory": "/etc/apache2/ssl.crt/",
    #     "remote_path": "/etc/apache2/ssl.crt/www.mailcheckup.com.crt",
    # },
    # "sslkey": {
    #     "local_path": "conf/www.mailcheckup.com/ssl.key",
    #     "remote_directory": "/etc/apache2/ssl.key/",
    #     "remote_path": "/etc/apache2/ssl.key/www.mailcheckup.com.crt",
    # },
}

def dev():
    vagrant_config = get_vagrant_parameters('dev')
    env.name = 'development'
    env.user = vagrant_config['User']
    env.domain = 'localhost'
    env.hosts = ['%s:%s' % (vagrant_config['HostName'],
                    vagrant_config['Port'])]
    env.key_filename = vagrant_config['IdentityFile']
    env.debug = True
    # env.project_directory = '/home/%s/%s' % (env.user, env.project_name)
    # env.project_root = '/home/%s' % env.user
    env.is_live = 0
    config_templates()


def production():
    vagrant_config = get_vagrant_parameters('hgWeb')
    env.name = 'production'
    env.user = vagrant_config['User']
    env.domain = 'mailcheckup.com'
    env.hosts = ['%s:%s' % (vagrant_config['HostName'],
                    vagrant_config['Port'])]
    env.key_filename = vagrant_config['IdentityFile']
    # env.project_directory = '/home/%s/%s' % (env.user, env.project_name)
    # env.project_root = '/home/%s' % env.user
    env.is_live = 1
    config_templates()


def staging():
    vagrant_config = get_vagrant_parameters('web')
    env.name = 'staging'
    env.user = vagrant_config['User']
    env.domain = 'staging.mailcheckup.com'
    env.hosts = ['staging.mailcheckup.com']
    env.key_filename = vagrant_config['IdentityFile']
    # env.project_directory = '/home/%s/%s' % (env.user, env.project_name)
    # env.project_root = '/home/%s' % env.user
    env.is_live = 0
    config_templates()


def get_ssh_param(params, key):
    import re
    return filter(lambda s: re.search(r'^%s' % key, s), params)[0].split()[1]


def apt(packages):
    return sudo("apt-get install -y -q " + packages)


def run(command, show=True):
    with hide("running"):
        return _run(command)


def bootstrap():
    """
    Runs once
    """

    append("~/.bash_profile", "alias vi=vim")
    append("~/.bash_profile", "alias l=ls")
    append("~/.bash_profile", "alias ll='ls -al'")
    append("~/.bash_profile", "export VAGRANT_ROOT=/vagrant/deploy")

    sudo("apt-get update")

    #install vim to help edit files faster
    apt("vim")

    #install apc prerequisites
    apt("make libpcre3 libpcre3-dev re2c")

    #install python 2.6 (needed for google sitemaps, remove for now)
    #apt("python2.6")

    #install_dependencies and lamp
    apt("tasksel rsync")
    apt("apache2 php5 libapache2-mod-php5 php5-mcrypt libapache2-mod-auth-mysql \
            php5-mysql")

    apt("php-apc")

    #install curl, used for Composer
    apt("curl")

    sudo("a2enmod php5")
    sudo("a2enmod rewrite")
    sudo("a2enmod headers")
    sudo("a2enmod expires")

    #ensure apache is started at this point
    start_server()

    apt("php-pear php5-dev php5-curl")

    #run this AFTER we install apache, or the following error will happen
    #apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1 for ServerName
    sudo('''sh -c "echo 'ServerName MailCheckup.com' > /etc/apache2/conf-available/servername.conf"''')
    #sudo('sh -c \047echo \042ServerName mailcheckup.com\042 > /etc/apache2/httpd.conf\047') # alternate method

    #install git
    apt("git-core")



    print(white("If you have an authentication error occurs connecting to git, run $ ssh-add"))

    # #check key to see if it exists, only generate new key if one isnt already made.
    # if not exists("%s/.ssh/id_rsa" % env.project_root):
    #     print(white("Trying to run automatically, please enter your desired password when prompted."))
    #     local("ssh-add")

    deploy()



def deploy():
    #UPDATE the server with the newest updates from github.

    print(white("Creating environment %s" % env.name))

    # #make sure logs directory exists
    # if not exists("%s/application/logs/" % env.project_directory):
    #     with cd("%s/application" % env.project_directory):
    #         sudo("mkdir logs")
    #
    # #ensure everything is writable in the logs dir
    # with cd("%s/application/" % env.project_directory):
    #     sudo("chown www-data:www-data -R logs")
    #     sudo("chmod 777 -R logs")

    #install curl, used with composer
    apt("curl")

    sudo("curl -sS https://getcomposer.org/installer | php")
    sudo("mv composer.phar /usr/local/bin/composer")

    put_templates()


    # if not exists("%s/log" % env.project_directory):
    #     with cd("%s" % env.project_directory):
    #         sudo("mkdir log")
    #
    # if not exists("%s/log/error_log" % env.project_directory):
    #     with cd("%s/log" % env.project_directory):
    #         sudo("touch error_log")

    #make sure we have ssl enabled
    sudo('a2enmod ssl')

    #make sure correct apache symlinks are created
    #and proper deploy config is loaded
    # sudo('a2ensite %s.conf' % env.project_name)

    #disable the default website
    sudo('a2dissite 000-default')

    #set the 'ServerName' directive globally
    sudo('a2enconf servername')

    #ensure the crontab is enabled
    # sudo('crontab -u %s /etc/cron.d/%s' % (env.user, env.project_name))

    restart_server()


def start_server():
    #starts apache and mysql
    try:
        sudo("apache2ctl -k start", pty=False)
    except:
        pass


def stop_server():
    #stops apache and mysql
    try:
        sudo("apache2ctl -k stop", pty=False)
    except:
        pass


def restart_server():
    #this command will restart apache if it is running, and start it if it is not running
    sudo("apache2ctl -k restart", pty=False) #running this command after the system is up causes an issue, since the "service apache2 start" command does not work in this script, can we check if apache is running and skip


def get_vagrant_parameters(box):
    """
    Parse vagrant's ssh-config for given key's value
    This is helpful when dealing with multiple vagrant instances.
    """
    result = local('vagrant ssh-config ' + box, capture=True)
    conf = {}
    for line in iter(result.splitlines()):
        parts = line.split()
        conf[parts[0]] = ' '.join(parts[1:])

    return conf


def put_templates():
    for name in get_templates():
        upload_environment_templates(name)


def get_templates():
    """
    Injects environment variables into config templates
    """
    injected = {}
    for name, data in env.templates.items():
        injected[name] = dict([(k, v % env) for k, v in data.items()])
    return injected


def upload_environment_templates(name):
    print(blue("Uploading template: %s" % name))

    template = get_templates()[name]
    local_path = template["local_path"]
    remote_directory = template["remote_directory"]
    remote_path = template["remote_path"]
    owner = template.get("owner")
    mode = template.get("mode")

    if not exists("%s" % remote_directory):
        sudo("mkdir -p %s" % remote_directory)

    upload_template(local_path, remote_path, env, use_sudo=True, backup=False)
    if owner:
        sudo("chown %s %s" % (owner, remote_path))
    if mode:
        sudo("chmod %s %s" % (mode, remote_path))

    print(blue("Uploaded template: %s" % name))

def add_user(user=None):
    if not exists("%s" % env.project_root):
        sudo('useradd %s -s /bin/bash -m' % env.user)
        sudo('echo "%s ALL=(ALL) ALL" >> /etc/sudoers' % env.user)
        password = ''.join(random.choice(string.ascii_uppercase + string.digits) for x in range(8))
        sudo('echo "%s:%s" | chpasswd' % (env.user, password))
        print(red("Password for %s is %s" % (env.user, password)))


def _get_root_password():
    """Ask root password only once if needed"""
    if env.db_root_password is None:
        env.db_root_password = prompt('Please enter MySQL root password:')
    return env.db_root_password

def create_sitemap():
    run('python /etc/rc.d/google_sitemaps/sitemap_gen.py --config=%s/config.xml' % env.project_directory)
