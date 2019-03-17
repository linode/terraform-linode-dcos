output "master_public_ips" {
  value = "${concat(module.nodes_master.ip_address)}"
}
