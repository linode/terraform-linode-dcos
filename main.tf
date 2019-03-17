//
//  BOOTSTRAP NODE
//
module "node_bootstrap" {
  source         = "./modules/instances"
  node_type      = "${var.instance_type}"
  region         = "${var.region}"
  private_ip     = "true"
  ssh_public_key = "${var.ssh_public_key}"
  label_prefix   = "dcos"
  node_class     = "bootstrap"
  node_count     = "1"

  // tags            = ["dcos", "bootstrap"]
}

locals {
  detect_ip = <<EOS
#!/bin/sh
ip -4 -o a show dev eth0 | awk '/\ 192.168/ {split($4,a,"/"); print a[1] }'
EOS
  detect_ip_public = <<EOS
#!/bin/sh
ip -4 -o a show dev eth0 | awk '! /\ 192.168/ {split($4,a,"/"); print a[1] }'
EOS
}

module "dcos-bootstrap" {
  source                         = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip           = "${module.node_bootstrap.private_ip_address[0]}"
  dcos_public_agent_list         = "\n - ${join("\n - ", module.nodes_agent_public.private_ip_address)}"
  dcos_master_list               = "\n - ${join("\n - ", module.nodes_master.private_ip_address)}"
  dcos_install_mode              = "${var.state}"
  dcos_version                   = "${var.dcos_version}"
  dcos_skip_checks               = "${var.dcos_skip_checks}"
  dcos_master_discovery          = "static"
  dcos_exhibitor_storage_backend = "static"
  dcos_cluster_name              = "${terraform.workspace}"

  role = "dcos-bootstrap"
}

resource "null_resource" "bootstrap" {
  triggers {
    cluster_instance_ids = "${module.node_bootstrap.id[0]}"
    dcos_version         = "${var.dcos_version}"
    num_of_masters       = "${var.num_of_masters}"
  }

  connection {
    host = "${module.node_bootstrap.ip_address[0]}"
    user = "${var.ssh_user}"
  }

  provisioner "file" {
     content = "${local.detect_ip}"
     destination = "/tmp/ip-detect"
  }

  provisioner "file" {
     content = "${local.detect_ip_public}"
     destination = "/tmp/ip-detect-public"
  }

  # Generate and upload bootstrap script to node
  provisioner "file" {
    content     = "${module.dcos-bootstrap.script}"
    destination = "run.sh"
  }

  # Install Bootstrap Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}

//
//  PUBLIC AGENT NODES
//
module "nodes_agent_public" {
  source         = "./modules/instances"
  node_type      = "${var.instance_type}"
  region         = "${var.region}"
  private_ip     = "true"
  ssh_public_key = "${var.ssh_public_key}"
  node_count     = "${var.num_of_public_agents}"
  label_prefix   = "dcos"
  node_class     = "agent_public"
}

module "dcos-mesos-agent-public" {
  source               = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip = "${module.node_bootstrap.private_ip_address[0]}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-agent-public"
}

# Execute generated script on agent
resource "null_resource" "agent" {
  triggers {
    cluster_instance_ids       = "${null_resource.bootstrap.id}"
    current_linode_instance_id = "${module.nodes_agent_public.id[count.index]}"
  }

  connection {
    host = "${element(module.nodes_agent_public.ip_address, count.index)}"
    user = "${var.ssh_user}"
  }

  count = "${var.num_of_public_agents}"

  # Generate and upload Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent-public.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${module.node_bootstrap.private_ip_address[0]}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done",
    ]
  }

  # Install Slave Node
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}

//
//  MASTER NODES
//
module "nodes_master" {
  source         = "./modules/instances"
  node_type      = "${var.instance_type}"
  region         = "${var.region}"
  private_ip     = "true"
  ssh_public_key = "${var.ssh_public_key}"
  node_count     = "${var.num_of_masters}"
  label_prefix   = "dcos"
  node_class     = "master"
}

# Create DCOS Mesos Master Scripts to execute
module "dcos-mesos-master" {
  source               = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip = "${module.node_bootstrap.private_ip_address[0]}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-master"
}

resource "null_resource" "master" {
  triggers {
    cluster_instance_ids       = "${null_resource.bootstrap.id}"
    current_linode_instance_id = "${module.nodes_master.id[count.index]}"
  }

  connection {
    host = "${element(module.nodes_master.ip_address, count.index)}"
    user = "${var.ssh_user}"
  }

  count = "${var.num_of_masters}"

  # Generate and upload Master script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-master.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${module.node_bootstrap.private_ip_address[0]}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done",
    ]
  }

  # Install Master Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}
