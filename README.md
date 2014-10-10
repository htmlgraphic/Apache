# OPS
A node-based web server deployment system with modular web and database nodes

## Configuration

* Configure your DigitalOcean token, ssh key name, and key file in the vagrant.yml file (sample in vagrant-sample.yml)

## Deployment

* Copy the vagrant-sample.yml files to vagrant.yml and fill in the DigitalOcean personal token
* Use `vagrant up hgWeb --provider digital_ocean` to deploy and `fab production bootstrap` to provision the nodes.
