variable "zone_name" {
  type        = string
  description = "The name of the DNS zone (e.g., gb-coding.nl)"
}

variable "resource_group_name" {
  type        = string
  description = "The resource group to deploy DNS resources to"
}

variable "subdomain_name" {
  type        = string
  description = "The subdomain name without the zone (e.g., 'azure' for 'azure.gb-coding.nl')"
}

variable "custom_domain_name" {
  type        = string
  description = "The full custom domain name (e.g., 'azure.gb-coding.nl')"
}

variable "app_hostname" {
  type        = string
  description = "The App Service default hostname (e.g., 'my-web-service-app.azurewebsites.net')"
}

variable "app_service_name" {
  type        = string
  description = "The name of the App Service to bind the custom domain to"
}

variable "ttl" {
  type        = number
  description = "Time to live for the DNS record"
  default     = 300
}

variable "domain_verification_value" {
  type        = string
  description = "The domain verification value for custom domain binding"
  default     = ""
}
