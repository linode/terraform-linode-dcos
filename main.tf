resource "linode_instance" "bootstrap" {
  type            = "${var.instance_type}"
  region          = "${var.region}"
  image           = "${var.instance_image}"
  private_ip      = "true"
  authorized_keys = ["${chomp(file(var.ssh_public_key))}"]
}

module "dcos-bootstrap" {
  source                 = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip   = "${linode_instance.bootstrap.private_ip_address}"
  dcos_public_agent_list = "\n - ${join("\n - ", linode_instance.agent_public.*.private_ip)}"
  dcos_master_list       = "\n - ${join("\n - ", linode_instance.master.*.private_ip)}"
  dcos_install_mode      = "${var.state}"
  dcos_version           = "${var.dcos_version}"
  dcos_skip_checks       = "${var.dcos_skip_checks}"
  role                   = "dcos-bootstrap"
}

resource "null_resource" "bootstrap" {
  triggers {
    cluster_instance_ids = "${linode_instance.bootstrap.id}"
    dcos_version         = "${var.dcos_version}"
    num_of_masters       = "${var.num_of_masters}"
  }

  connection {
    host = "${linode_instance.bootstrap.ip_address}"
    user = "root"
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

resource "linode_instance" "agent_public" {
  type            = "${var.instance_type}"
  region          = "${var.region}"
  image           = "${var.instance_image}"
  private_ip      = "true"
  authorized_keys = ["${chomp(file(var.ssh_public_key))}"]
  count           = "${var.num_of_public_agents}"
}

module "dcos-mesos-agent-public" {
  source               = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip = "${linode_instance.bootstrap.private_ip_address}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-agent-public"
}

# Execute generated script on agent
resource "null_resource" "agent" {
  triggers {
    cluster_instance_ids       = "${null_resource.bootstrap.id}"
    current_linode_instance_id = "${linode_instance.agent_public.*.id[count.index]}"
  }

  connection {
    host = "${element(linode_instance.agent_public.*.public_ip, count.index)}"
    user = "root"
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
      "until $(curl --output /dev/null --silent --head --fail http://${linode_instance.bootstrap.private_ip_address}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done",
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

resource "linode_instance" "master" {
  type            = "${var.instance_type}"
  region          = "${var.region}"
  image           = "${var.instance_image}"
  private_ip      = "true"
  authorized_keys = ["${chomp(file(var.ssh_public_key))}"]
  count           = "${var.num_of_masters}"
}

# Create DCOS Mesos Master Scripts to execute
module "dcos-mesos-master" {
  source               = "dcos-terraform/dcos-core/template"
  bootstrap_private_ip = "${linode_instance.bootstrap.private_ip_address}"
  dcos_install_mode    = "${var.state}"
  dcos_version         = "${var.dcos_version}"
  dcos_skip_checks     = "${var.dcos_skip_checks}"
  role                 = "dcos-mesos-master"
}

resource "null_resource" "master" {
  triggers {
    cluster_instance_ids       = "${null_resource.bootstrap.id}"
    current_linode_instance_id = "${linode_instance.master.*.id[count.index]}"
  }

  connection {
    host = "${element(linode_instance.master.*.public_ip, count.index)}"
    user = "root"
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
      "until $(curl --output /dev/null --silent --head --fail http://${linode_instance.bootstrap.private_ip_address}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done",
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
