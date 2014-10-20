## Prerequisites

Before starting a system, this is how your system should be set up:

* Install [VirtualBox 4.3.10](https://www.virtualbox.org/wiki/Downloads)
* Install [Vagrant](http://www.vagrantup.com/downloads.html)



## Web or MySQL Deployment

* Copy the vagrant-sample.yml files to vagrant.yml and fill in the Digital Ocean personal token
* Use `vagrant up hgWeb --provider digital_ocean` to deploy and `fab production bootstrap` to provision the nodes.



## Configuration

* Configure your Digital Ocean token, ssh key name, and key file in the vagrant.yml file (sample in vagrant-sample.yml)

* `vagrant-sample.yaml`



## Working with the Virtual Machine

```bash
# Start the VM  
vagrant up <system name> --provider digital_ocean

# SSH in to the VM
vagrant ssh <system name>

# Reprovisioning (e.g. after updating this repository)
vagrant provision <system name>

# Reprovisioning without a full apt-get update
vagrant provision --provision-with puppet

# Updating your hosts file (If there is no IP for vagrant.local)
vagrant up <system name>

# Suspending (sleeping) the VM
# Note that this doesn't remove the hosts entry
vagrant suspend <system name>

# Halting (shutting down) the VM
vagrant halt <system name>

# Destroying the VM (if your VM is completely broken)
vagrant destroy <system name>
```


