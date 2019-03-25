output "master_public_ips" {
  value = "${module.dcos_linode.master_public_ips}"
}

output "public_agent_public_ips" {
  value = "${module.dcos_linode.public_agent_public_ips}"
}

output "install_cli" {
  value = <<EOS
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/$(uname -s | tr A-Z a-z)/x86-64/dcos-1.12/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos &&
dcos cluster setup http://${module.dcos_linode.master_public_ips[0]} &&
dcos
EOS
}
