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

variable "identity_id" {
  type        = string
  description = "The ID of the User Assigned Identity"
}

variable "postgres_config" {
  type = object({
    host     = string
    db       = string
    user     = string
    password = string
  })
}

variable "mysql_config" {
  type = object({
    host     = string
    db       = string
    user     = string
    password = string
  })
}

variable "sqlserver_config" {
  type = object({
    host     = string
    db       = string
    user     = string
    password = string
  })
}

variable "docker_registry_config" {
  type = object({
    url      = string
    username = string
    password = string
  })
  default = {
    url      = "https://ghcr.io"
    username = ""
    password = ""
  }
}
