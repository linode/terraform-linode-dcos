variable "linode_token" {
  description = "Linode API v4 Personal Access Token"
}

variable "region" {
  description = "Linode Region"
  default     = "us-east"
}

variable "agent_type" {
  description = "DCOS Agent Linode Instance Type"
  default     = "g6-standard-4"
}

variable "master_type" {
  description = "DCOS Master Linode Instance Type"
  default     = "g6-standard-4"
}

variable "boot_type" {
  description = "DCOS Boot Server Linode Instance Type"
  default     = "g6-standard-4"
}

variable "dcos_cluster_name" {
  description = "Name of your cluster. Alpha-numeric and hyphens only, please."
  default     = "linode-dcos"
}

variable "dcos_master_count" {
  default     = "3"
  description = "Number of master nodes. 1, 3, or 5."
}

variable "dcos_agent_count" {
  description = "Number of agents to deploy"
  default     = "4"
}

variable "dcos_public_agent_count" {
  description = "Number of public agents to deploy"
  default     = "1"
}

variable "dcos_ssh_public_key_path" {
  description = "Path to your public SSH key path"
  default     = "./linode-key.pub"
}

variable "dcos_installer_url" {
  description = "Path to get DCOS"
  default     = "https://downloads.dcos.io/dcos/EarlyAccess/dcos_generate_config.sh"
}

variable "dcos_ssh_key_path" {
  description = "Path to your private SSH key for the project"
  default     = "./linode-key"
}
