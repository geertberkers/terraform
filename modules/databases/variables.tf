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

variable "mysql_admin_password" {
  type = string
}

variable "sql_admin_user" {
  type = string
}

variable "sql_admin_password" {
  type = string
}

variable "pg_admin_user" {
  type = string
}

variable "pg_admin_password" {
  type      = string
  sensitive = true
}