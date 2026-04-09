variable "resource_group_name" {
  type        = string
  description = "The resource group to deploy logging resources to"
}

variable "location" {
  type        = string
  description = "Azure region for logging resources"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for logging storage account names"
}

variable "file_share_name" {
  type        = string
  description = "Name of the file share for logs"
  default     = "logs"
}

variable "file_share_quota" {
  type        = number
  description = "Quota for the file share in GB"
  default     = 50
}

variable "app_identity_principal_id" {
  type        = string
  description = "Principal ID of the app service managed identity"
}
