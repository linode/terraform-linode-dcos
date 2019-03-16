variable "dcos_version" {
  default = "1.12.2"
}

variable "state" {
  default = "install"
}

variable "region" {
  default = "us-east"
}

variable "instance_type" {
  default = "g6-standard-2"
}

// https://docs.mesosphere.com/version-policy/
variable "instance_image" {
  default = "linode/centos7"
}

variable "num_of_public_agents" {
  default = "3"
}

variable "dcos_skip_checks" {
  default = "false"
}

variable "num_of_masters" {
  default = "3"
}

variable "ssh_public_key" {
  type        = "string"
  default     = "~/.ssh/id_rsa.pub"
  description = "The path to your public key"
}
