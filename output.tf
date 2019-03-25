output "master_public_ips" {
  value = "${module.nodes_master.ip_address}"
}

output "public_agent_public_ips" {
  value = "${module.nodes_agent_public.ip_address}"
}
