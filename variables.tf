variable "ssh_public_key" {
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
  type    = string
  default = "app-db"
}