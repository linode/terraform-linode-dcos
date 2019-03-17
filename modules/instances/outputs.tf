output "private_ip_address" {
  depends_on = ["linode_instance.instance.*"]
  value      = "${linode_instance.instance.*.private_ip_address}"
}

output "ip_address" {
  depends_on = ["linode_instance.instance.*"]
  value      = "${linode_instance.instance.*.ip_address}"
}

output "id" {
  depends_on = ["linode_instance.instance.*"]
  value      = "${linode_instance.instance.*.id}"
}
