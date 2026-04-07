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