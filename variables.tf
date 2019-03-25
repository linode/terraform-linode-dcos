variable "dcos_version" {
  description = "Specifies which DC/OS version instruction to use"
  default     = "1.12.2"
}

variable "state" {
  description = "Type of command to execute. Options: install or upgrade"
  default     = "install"
}

variable "region" {
  description = "Linode region where the cluster will be deployed"
  default     = "us-east"
}

variable "instance_type" {
  description = "Linode instance type (defines RAM, CPU, Disk)"
  default     = "g6-standard-6"
}

// https://docs.mesosphere.com/version-policy/
variable "instance_image" {
  description = "Linode image to deploy (only tested with: linode/containerlinux)"
  default     = "linode/containerlinux"
}

variable "num_of_public_agents" {
  // https://docs.mesosphere.com/1.12/overview/architecture/node-types/
  description = "Number of Public Agents to deploy"
  default     = "1"
}

variable "num_of_private_agents" {
  // https://docs.mesosphere.com/1.12/overview/architecture/node-types/
  description = "Number of Private Agents to deploy"
  default     = "3"
}

variable "dcos_skip_checks" {
  description = "Used to skip all dcos checks that may block an upgrade if any DC/OS component is unhealthly"
  default     = "false"
}

variable "num_of_masters" {
  // https://docs.mesosphere.com/1.12/overview/architecture/node-types/
  description = "Number of Master Nodes to deploy"
  default     = "3"
}

variable "ssh_public_key" {
  type        = "string"
  default     = "~/.ssh/id_rsa.pub"
  description = "The path to your public key"
}

variable "ssh_user" {
  type        = "string"
  default     = "core"
  description = "The user account to use in SSH commands to the Linode"
}
