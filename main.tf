terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend stays in backend.tf
}

moved {
  from = module.app_service.azurerm_user_assigned_identity.app_identity
  to   = azurerm_user_assigned_identity.app_identity
}

# =========================
# AZURE PROVIDER (FIXED)
# =========================
provider "azurerm" {
  features {}

  # 🔥 REQUIRED for GitHub OIDC authentication
  use_oidc = true
}

# =========================
# SWITZERLAND
# =========================
module "switzerland" {
  source = "./modules/region"

  resource_group_name = "rg-terraform-switzerland-north"
  location            = "switzerlandnorth"
  prefix              = "ch"

  vnet_cidr   = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"

  vm_sizes = [
    "Standard_B2ts_v2",
    "Standard_B2ts_v2"
  ]

  ssh_public_key = var.ssh_public_key
}

# =========================
# SWEDEN
# =========================
module "sweden" {
  source = "./modules/region"

  resource_group_name = "rg-terraform-sweden-central"
  location            = "swedencentral"
  prefix              = "se"

  vnet_cidr   = "10.1.0.0/16"
  subnet_cidr = "10.1.1.0/24"

  vm_sizes = [
    "Standard_B2ts_v2",
    "Standard_B2ts_v2"
  ]

  ssh_public_key = var.ssh_public_key
}

# =========================
# MANAGED IDENTITY
# =========================
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "my-web-service-identity"
  location            = "westeurope"
  resource_group_name = "rg-terraform-app-service-westeurope"
}

# =========================
# RESOURCE GROUPS
# =========================
resource "azurerm_resource_group" "app_service_free_rg" {
  name     = "rg-terraform-app-service-free-westeurope"
  location = "westeurope"
}

resource "azurerm_resource_group" "aks_cheap_rg" {
  name     = "rg-terraform-aks-cheap"
  location = "westeurope"
}

# =========================
# APP SERVICE (PAID TIER)
# =========================
module "app_service" {
  source              = "./modules/app_service"
  resource_group_name = "rg-terraform-app-service-westeurope"
  location            = "westeurope"
  name_prefix         = "my-web-service"
  service_plan_sku    = "B1" # Basic tier

  app_identity_id           = azurerm_user_assigned_identity.app_identity.id
  app_identity_client_id    = azurerm_user_assigned_identity.app_identity.client_id
  app_identity_principal_id = azurerm_user_assigned_identity.app_identity.principal_id
  app_identity_name         = azurerm_user_assigned_identity.app_identity.name

  docker_image_tag = var.docker_image_tag
  app_version_name = var.app_version_name
  app_version_code = var.app_version_code

  postgres_fqdn     = module.databases.postgres_fqdn
  postgres_user     = module.databases.postgres_user
  postgres_password = module.databases.postgres_password
  postgres_db       = module.databases.postgres_db

  mysql_fqdn     = module.databases.mysql_fqdn
  mysql_user     = module.databases.mysql_user
  mysql_password = module.databases.mysql_password
  mysql_db       = module.databases.mysql_db

  sql_server_fqdn     = module.databases.sql_server_fqdn
  sql_server_user     = module.databases.sql_server_user
  sql_server_password = module.databases.sql_server_password
  sql_server_db       = module.databases.sql_server_db

  cosmos_endpoint = module.databases.cosmos_endpoint

  # Key Vault Secret URIs for App Service (Secure references)
  postgres_password_secret_uri   = module.databases.postgres_password_secret_uri
  mysql_password_secret_uri      = module.databases.mysql_password_secret_uri
  sql_server_password_secret_uri = module.databases.sql_server_password_secret_uri
  cosmos_connection_secret_uri   = module.databases.cosmos_connection_secret_uri

  azure_storage_account = module.logging.storage_account_name
  azure_file_share      = module.logging.file_share_name
  azure_storage_key     = module.logging.storage_account_primary_access_key
}

# =========================
# APP SERVICE (FREE TIER)
# =========================
module "app_service_free" {
  source              = "./modules/app_service"
  resource_group_name = "rg-terraform-app-service-free-westeurope"
  location            = "westeurope"
  name_prefix         = "free-web-service"
  service_plan_sku    = "F1" # Free tier

  app_identity_id           = azurerm_user_assigned_identity.app_identity.id
  app_identity_client_id    = azurerm_user_assigned_identity.app_identity.client_id
  app_identity_principal_id = azurerm_user_assigned_identity.app_identity.principal_id
  app_identity_name         = azurerm_user_assigned_identity.app_identity.name

  docker_image_tag = var.docker_image_tag
  app_version_name = var.app_version_name
  app_version_code = var.app_version_code

  postgres_fqdn     = module.databases.postgres_fqdn
  postgres_user     = module.databases.postgres_user
  postgres_password = module.databases.postgres_password
  postgres_db       = module.databases.postgres_db

  mysql_fqdn     = module.databases.mysql_fqdn
  mysql_user     = module.databases.mysql_user
  mysql_password = module.databases.mysql_password
  mysql_db       = module.databases.mysql_db

  sql_server_fqdn     = module.databases.sql_server_fqdn
  sql_server_user     = module.databases.sql_server_user
  sql_server_password = module.databases.sql_server_password
  sql_server_db       = module.databases.sql_server_db

  cosmos_endpoint = module.databases.cosmos_endpoint

  # Key Vault Secret URIs for App Service (Secure references)
  postgres_password_secret_uri   = module.databases.postgres_password_secret_uri
  mysql_password_secret_uri      = module.databases.mysql_password_secret_uri
  sql_server_password_secret_uri = module.databases.sql_server_password_secret_uri
  cosmos_connection_secret_uri   = module.databases.cosmos_connection_secret_uri

  azure_storage_account = module.logging.storage_account_name
  azure_file_share      = module.logging.file_share_name
  azure_storage_key     = module.logging.storage_account_primary_access_key
}

# =========================
# LOGGING
# =========================
module "logging" {
  source = "./modules/logging"

  resource_group_name = "rg-terraform-app-service-westeurope"
  location            = "westeurope"
  name_prefix         = "app"
}

# =========================
# DNS
# =========================
module "dns" {
  source = "./modules/dns"

  zone_name           = var.dns_zone_name
  resource_group_name = "rg-terraform-app-service-westeurope"
  subdomain_name      = var.dns_subdomain
  custom_domain_name  = var.custom_domain_name
  app_hostname        = module.app_service.default_hostname
  app_service_name    = module.app_service.app_name
}

# =========================
# DNS (FREE TIER)
# =========================
module "dns_free" {
  source = "./modules/dns"

  zone_name                 = var.dns_zone_name
  resource_group_name       = azurerm_resource_group.app_service_free_rg.name
  subdomain_name            = "free" # Separate subdomain for free tier
  custom_domain_name        = "free.${var.dns_zone_name}"
  app_hostname              = module.app_service_free.default_hostname
  app_service_name          = module.app_service_free.app_name
  domain_verification_value = "601cc3e67399002c0fe3e5b9688bb2cf67ceaaf7accf07ca47bcaad1e988200e"

  depends_on = [azurerm_resource_group.app_service_free_rg]
}

# =========================
# DATABASES
# =========================
module "databases" {
  source = "./modules/databases"

  resource_group_name = "rg-terraform-databases-europe"
  location            = "swedencentral"
  env                 = "global"

  mysql_admin_user = var.mysql_admin_user
  sql_admin_user   = var.sql_admin_user
  pg_admin_user    = var.pg_admin_user

  app_identity_principal_id = azurerm_user_assigned_identity.app_identity.principal_id
  app_identity_name         = azurerm_user_assigned_identity.app_identity.name

  sql_database_name = var.sql_database_name
}


# =========================
# KUBERNETES CLUSTER (CHEAP DEPLOYMENT)
# =========================
module "aks_cheap" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.aks_cheap_rg.name
  location            = "westeurope"
  name_prefix         = "cheap-k8s"

  depends_on = [azurerm_resource_group.aks_cheap_rg]
}


# =========================
# APP HOSTING EXAMPLES
# =========================
# Below are examples of how to adopt the new web hosting architectures instead of VMs.
# Uncomment the one you want to use for your application footprint!

# module "my_app_service" {
#   source              = "./modules/app_service"
#   resource_group_name = "rg-terraform-app-service-eu"
#   location            = "swedencentral"
#   name_prefix         = "mywebapp"
# }

# module "my_container_apps" {
#   source              = "./modules/container_apps"
#   resource_group_name = "rg-terraform-ca-eu"
#   location            = "swedencentral"
#   name_prefix         = "myca"
# }

# module "my_aks" {
#   source              = "./modules/aks"
#   resource_group_name = "rg-terraform-aks-eu"
#   location            = "swedencentral"
#   name_prefix         = "myk8s"
# }
