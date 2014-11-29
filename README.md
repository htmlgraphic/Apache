# OPS: A modular web app deployment helper
OPS is a collection of CoreOS and Docker files to simplify the deployment of multiple web services.

## Creating a cluster
Creating nodes for the CoreOS cluster is as simple as running the `CoreOS/create_node.sh` script.
* Before running the script, be sure to set the DO_TOKEN environment variable and the SSH key ID in the script as well as the discovery ID in `cloud-config.yml`.
* New discovery URLs can be generated at https://discovery.etcd.io/new.
* Be sure not to change anything in between each time you run `create_node.sh`

## Accessing the cluster
You may now verify that the cluster has clustered by SSHing into a node.
* SSH into a node as the core user with the -A flag (to forward the SSH agent): `ssh -A core@<node_public_ip>`
* On the node, run `fleetctl list-machines` to verify that the nodes have discovered each other.

It may also be preferred to install fleetctl on your local machine and connect remotely:
* Run `ssh-add` to ensure your SSH key is added to the ssh agent
* Run `fleetctl --tunnel=<node_public_ip> list-machines`
* You may set the `FLEETCTL_TUNNEL` environment variable to skip setting the `--tunnel` flag

## Deploying apps
It's important that the unit files (*.service) is accessible to the fleetctl command. If the files are on your local computer, use a tunneled fleetctl connection to load the unit files.

* Upload the service file with `fleetctl submit name.service`
* List unit files with `fleetctl list-unit-files`
* Finally, start the units with `fleetctl start name.service`
