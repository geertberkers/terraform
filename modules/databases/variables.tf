variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "env" {
  type = string
}

variable "mysql_admin_user" {
  type = string
}

variable "sql_admin_user" {
  type = string
}

variable "pg_admin_user" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "app_service_name" {
  type        = string
  description = "Name of the App Service to read identity from"
}

variable "app_service_rg" {
  type        = string
  description = "Resource group of the App Service"
}

variable "app_service_principal_id" {
  type        = string
  description = "Principal ID of the App Service managed identity"
  default     = null
}

variable "app_service_client_id" {
  type        = string
  description = "Client ID of the App Service managed identity"
  default     = null
}

variable "app_service_identity_name" {
  type        = string
  description = "Name of the User Assigned Identity"
  default     = null
}