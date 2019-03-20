provider "linode" {
  token = "${var.linode_token}"
}

data "linode_profile" "profile" {}

data "template_file" "config" {
  template = "${file("${path.module}/config.yaml.tpl")}"

  vars {
    cluster_name = "${var.dcos_cluster_name}"
    bootstrap    = "${linode_instance.dcos_bootstrap.private_ip_address}"
    master_ips   = "${jsonencode(linode_instance.dcos_master.*.private_ip_address)}"
  }
}

data "template_file" "installer" {
  template = "${file("${path.module}/installer.sh.tpl")}"

  vars {
    bootstrap = "${linode_instance.dcos_bootstrap.private_ip_address}"
  }
}

resource "linode_instance" "dcos_bootstrap" {
  label = "${format("${var.dcos_cluster_name}-bootstrap-%02d", count.index)}"

  image            = "linode/containerlinux"
  type             = "${var.boot_type}"
  authorized_keys  = ["${chomp(file(var.dcos_ssh_public_key_path))}"]
  region           = "${var.region}"
  private_ip       = true
  authorized_users = ["${data.linode_profile.profile.username}"]

  connection {
    user        = "core"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/linode-network.sh"
    destination = "/tmp/linode-network.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop update-engine",
      "mkdir $HOME/genconf",
      "chmod +x /tmp/linode-network.sh && sudo /tmp/linode-network.sh ${self.private_ip_address} ${self.label}",
      "wget -q -O dcos_generate_config.sh -P $HOME ${var.dcos_installer_url}",
    ]
  }

  provisioner "file" {
    content = <<EOS
#!/bin/sh
echo ${self.private_ip_address}
EOS

    destination = "$HOME/genconf/ip-detect"
  }

  provisioner "remote-exec" {
    inline = "chmod +x $HOME/genconf/ip-detect"
  }
}

resource "null_resource" "dcos_bootstrap" {
  connection {
    user        = "core"
    host        = "${linode_instance.dcos_bootstrap.ip_address}"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    content     = "${data.template_file.config.rendered}"
    destination = "$HOME/genconf/config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash $HOME/dcos_generate_config.sh",
      "docker run -d -p 4040:80 -v $HOME/genconf/serve:/usr/share/nginx/html:ro nginx 2>/dev/null",
      "docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 --name=dcos_int_zk jplock/zookeeper 2>/dev/null",
    ]
  }
}

resource "null_resource" "dcos_bootstrap_updates" {
  depends_on = ["null_resource.dcos_public_agent", "null_resource.dcos_agent"]

  connection {
    user        = "core"
    host        = "${linode_instance.dcos_bootstrap.ip_address}"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start update-engine",
    ]
  }
}

resource "linode_instance" "dcos_master" {
  label = "${format("${var.dcos_cluster_name}-master-%02d", count.index)}"
  image = "linode/containerlinux"
  type  = "${var.master_type}"

  count            = "${var.dcos_master_count}"
  authorized_keys  = ["${chomp(file(var.dcos_ssh_public_key_path))}"]
  region           = "${var.region}"
  private_ip       = true
  authorized_users = ["${data.linode_profile.profile.username}"]

  connection {
    user        = "core"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/linode-network.sh"
    destination = "/tmp/linode-network.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop update-engine",
      "chmod +x /tmp/linode-network.sh && sudo /tmp/linode-network.sh ${self.private_ip_address} ${self.label}",
    ]
  }
}

resource "null_resource" "dcos_master" {
  count = "${var.dcos_master_count}"

  connection {
    user        = "core"
    host        = "${element(linode_instance.dcos_master.*.ip_address, count.index)}"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    content     = "${data.template_file.installer.rendered}"
    destination = "/tmp/installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installer.sh && bash /tmp/installer.sh master",
      "sudo systemctl start update-engine",
    ]
  }
}

resource "linode_instance" "dcos_agent" {
  label            = "${format("${var.dcos_cluster_name}-agent-%02d", count.index)}"
  image            = "linode/containerlinux"
  type             = "${var.agent_type}"
  count            = "${var.dcos_agent_count}"
  authorized_keys  = ["${chomp(file(var.dcos_ssh_public_key_path))}"]
  region           = "${var.region}"
  private_ip       = true
  authorized_users = ["${data.linode_profile.profile.username}"]

  connection {
    user        = "core"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/linode-network.sh"
    destination = "/tmp/linode-network.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop update-engine",
      "chmod +x /tmp/linode-network.sh && sudo /tmp/linode-network.sh ${self.private_ip_address} ${self.label}",
    ]
  }
}

resource "null_resource" "dcos_agent" {
  count      = "${var.dcos_agent_count}"
  depends_on = ["null_resource.dcos_bootstrap"]

  connection {
    user        = "core"
    host        = "${element(linode_instance.dcos_agent.*.ip_address, count.index)}"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    content     = "${data.template_file.installer.rendered}"
    destination = "/tmp/installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installer.sh && bash /tmp/installer.sh slave",
      "sudo systemctl start update-engine",
    ]
  }
}

resource "linode_instance" "dcos_public_agent" {
  label            = "${format("${var.dcos_cluster_name}-public-agent-%02d", count.index)}"
  image            = "linode/containerlinux"
  type             = "${var.agent_type}"
  count            = "${var.dcos_public_agent_count}"
  authorized_keys  = ["${chomp(file(var.dcos_ssh_public_key_path))}"]
  region           = "${var.region}"
  private_ip       = true
  authorized_users = ["${data.linode_profile.profile.username}"]

  connection {
    user        = "core"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    source      = "${path.module}/linode-network.sh"
    destination = "/tmp/linode-network.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop update-engine",
      "chmod +x /tmp/linode-network.sh && sudo /tmp/linode-network.sh ${self.private_ip_address} ${self.label}",
    ]
  }
}

resource "null_resource" "dcos_public_agent" {
  count      = "${var.dcos_public_agent_count}"
  depends_on = ["null_resource.dcos_bootstrap"]

  connection {
    user        = "core"
    host        = "${element(linode_instance.dcos_public_agent.*.ip_address, count.index)}"
    private_key = "${file(var.dcos_ssh_key_path)}"
  }

  provisioner "file" {
    content     = "${data.template_file.installer.rendered}"
    destination = "/tmp/installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/installer.sh && bash /tmp/installer.sh slave_public",
      "sudo systemctl start update-engine",
    ]
  }
}
