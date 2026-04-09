variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy the App Service to"
}

variable "location" {
  type        = string
  description = "Azure region for the App Service"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for the App Service names"
}
