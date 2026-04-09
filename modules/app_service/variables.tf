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

variable "mysql_fqdn" {
  type        = string
  description = "MySQL server FQDN"
  default     = ""
}

variable "sql_server_fqdn" {
  type        = string
  description = "SQL Server FQDN"
  default     = ""
}

variable "cosmos_endpoint" {
  type        = string
  description = "CosmosDB endpoint"
  default     = ""
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
