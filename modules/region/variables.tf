variable "resource_group_name" {}
variable "location" {}
variable "prefix" {}

variable "vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "vm_sizes" {
  type = list(string)
}

variable "ssh_public_key" {
  type = string
}
