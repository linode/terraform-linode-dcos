output "master_public_ips" {
  value = "${concat(linode_instance.master.*.ip_address)}"
}
