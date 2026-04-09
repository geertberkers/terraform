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

variable "custom_domain_name" {
  type    = string
  default = "azure.gb-coding.nl"
}

variable "dns_zone_name" {
  type    = string
  default = "gb-coding.nl"
}

variable "dns_subdomain" {
  type    = string
  default = "azure"
}