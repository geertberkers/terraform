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

variable "enable_free_custom_domain" {
  type        = bool
  description = "Whether to create a custom domain binding for the free App Service tier"
  default     = false
}

variable "dns_zone_name" {
  type    = string
  default = "gb-coding.nl"
}

variable "dns_subdomain" {
  type    = string
  default = "azure"
}

variable "docker_image_tag" {
  type        = string
  description = "The tag of the Docker image to deploy"
  default     = "latest"
}

variable "app_version_name" {
  type    = string
  default = "unknown"
}

variable "app_version_code" {
  type    = string
  default = "unknown"
}