output "agent-ip" {
  value = "${join(",", linode_instance.dcos_agent.*.ip_address)}"
}

output "agent-public-ip" {
  value = "${join(",", linode_instance.dcos_public_agent.*.ip_address)}"
}

output "master-ip" {
  value = "${join(",", linode_instance.dcos_master.*.ip_address)}"
}

output "bootstrap-ip" {
  value = "${linode_instance.dcos_bootstrap.ip_address}"
}

output "Use this link to access DCOS" {
  value = "http://${linode_instance.dcos_master.0.ip_address}/"
}
