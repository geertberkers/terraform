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

variable "app_identity_principal_id" {
  type        = string
  description = "Principal ID of the managed identity for database access"
  default     = ""
}
