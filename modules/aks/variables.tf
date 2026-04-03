variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for the AKS cluster name"
}
