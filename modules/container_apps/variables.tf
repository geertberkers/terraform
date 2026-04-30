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
  description = "Prefix for the container apps environments"
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

variable "postgres_fqdn" { type = string }
variable "postgres_user" { type = string }
variable "postgres_password" { 
  type      = string
  sensitive = true 
}
variable "postgres_db" { type = string }

variable "mysql_fqdn" { type = string }
variable "mysql_user" { type = string }
variable "mysql_password" { 
  type      = string
  sensitive = true 
}
variable "mysql_db" { type = string }

variable "sql_server_fqdn" { type = string }
variable "sql_server_user" { type = string }
variable "sql_server_password" { 
  type      = string
  sensitive = true 
}
variable "sql_server_db" { type = string }

variable "cosmos_endpoint" { type = string }
variable "cosmos_connection_string" { 
  type      = string
  sensitive = true 
}

variable "app_identity_client_id" { type = string }
variable "app_identity_name" { type = string }

variable "app_version_name" { type = string }
variable "app_version_code" { type = string }
