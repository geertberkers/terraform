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
    "Standard_B2als_v2",
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
    "Standard_B2als_v2",
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
# APP SERVICE
# =========================
module "app_service" {
  source              = "./modules/app_service"
  resource_group_name = "rg-terraform-app-service-westeurope"
  location            = "westeurope"
  name_prefix         = "my-web-service"

  app_identity_id           = azurerm_user_assigned_identity.app_identity.id
  app_identity_client_id     = azurerm_user_assigned_identity.app_identity.client_id
  app_identity_principal_id  = azurerm_user_assigned_identity.app_identity.principal_id

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

  sql_database_name = var.sql_database_name
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
