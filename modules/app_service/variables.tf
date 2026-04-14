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

variable "postgres_fqdn" {
  type        = string
  description = "PostgreSQL server FQDN"
  default     = ""
}

variable "postgres_user" {
  type      = string
  sensitive = true
  default   = ""
}

variable "postgres_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "postgres_db" {
  type    = string
  default = "appdb"
}

variable "mysql_fqdn" {
  type        = string
  description = "MySQL server FQDN"
  default     = ""
}

variable "mysql_user" {
  type      = string
  sensitive = true
  default   = ""
}

variable "mysql_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "mysql_db" {
  type    = string
  default = "appdb"
}

variable "sql_server_fqdn" {
  type        = string
  description = "SQL Server FQDN"
  default     = ""
}

variable "sql_server_user" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sql_server_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "sql_server_db" {
  type    = string
  default = "master"
}

variable "cosmos_endpoint" {
  type        = string
  description = "CosmosDB endpoint"
  default     = ""
}

variable "postgres_password_secret_uri" {
  type    = string
  default = ""
}

variable "mysql_password_secret_uri" {
  type    = string
  default = ""
}

variable "sql_server_password_secret_uri" {
  type    = string
  default = ""
}

variable "cosmos_connection_secret_uri" {
  type    = string
  default = ""
}

variable "azure_storage_account" {
  type        = string
  description = "Azure Storage account name for logging"
  default     = ""
}

variable "azure_file_share" {
  type        = string
  description = "Azure File Share name for logging"
  default     = "logs"
}

variable "azure_log_directory" {
  type        = string
  description = "Directory in file share for logs"
  default     = "app-logs"
}

variable "azure_storage_key" {
  type        = string
  description = "Azure Storage account access key for logging"
  default     = ""
  sensitive   = true
}

variable "app_identity_id" {
  type        = string
  description = "The ID of the User Assigned Identity"
  default     = ""
}

variable "app_identity_name" {
  description = "The name of the User Assigned Identity"
  type        = string
}

variable "app_identity_client_id" {
  type        = string
  description = "The Client ID of the User Assigned Identity"
  default     = ""
}

variable "app_identity_principal_id" {
  type        = string
  description = "The Principal ID of the User Assigned Identity"
  default     = ""
}

variable "docker_image_tag" {
  type        = string
  description = "The tag of the Docker image to deploy"
  default     = "latest"
}
