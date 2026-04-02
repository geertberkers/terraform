variable "ssh_public_key" {
  type = string
}

variable "mysql_admin_user" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "sql_admin_user" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "pg_admin_user" {
  type = string
}

variable "pg_admin_password" {
  type      = string
  sensitive = true
}
