# terraform-linode-dcos

Mesosphere DC/OS Terraform module for Linode

## DC/OS Installer

This repo holds [Terraform](https://www.terraform.io/) scripts to create a 1, 3, or 5 master DCOS cluster for use with the [Linode](https://www.linode.com) [Terraform Provider](https://www.terraform.io/docs/providers/linode/).

### Network Security

With this method, the network is open by default. Because of this, network security is a concern and should be addressed as soon as possible by the administrator.

## Usage

### Linode API Token

Before running the project you'll have to create an access token for Terraform to connect to the Linode API.
Using the token and your access key, create the `LINODE_TOKEN` environment variable:

```bash
read -sp "Linode Token: " LINODE_TOKEN # Enter your Linode Token (it will be hidden)
export LINODE_TOKEN
```

This variable will need to be supplied to every Terraform `apply`, `plan`, and `destroy` command using `-var linode_token=$LINODE_TOKEN` unless a `terraform.tfvars` file is created with this secret token.

### Install

Clone or download repo.

Copy `sample.terraform.tfvars` to `terraform.tfvars` and insert your variables.

To use the default configuration, which expects `linode-key.pub` in the run directory:

```
ssh-keygen -t rsa -N "" -f linode-key
```

Run `terraform apply`

## Theory of Operation:

This script will start the infrastructure machines (bootstrap and masters),
then collect their IPs to build an installer package on the bootstrap machine
with a static master list. All masters wait for an installation script to be
generated on the localhost, then receive that script. This script, in turn,
pings the bootstrap machine whilst waiting for the web server to come online
and serve the install script itself.

When the install script is generated, the bootstrap completes and un-blocks
the cadre of agent nodes, which are  cut loose to provision metal and
eventually install software.
