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
# DATABASES
# =========================
module "app_service" {
  source              = "./modules/app_service"
  resource_group_name = "rg-terraform-app-service-westeurope"
  location            = "westeurope"
  name_prefix         = "my-web-service"
}

resource "azurerm_dns_zone" "gb_coding" {
  name                = var.dns_zone_name
  resource_group_name = module.app_service.resource_group_name
}

resource "azurerm_dns_cname_record" "azure_subdomain" {
  name                = var.dns_subdomain
  zone_name           = azurerm_dns_zone.gb_coding.name
  resource_group_name = azurerm_dns_zone.gb_coding.resource_group_name
  ttl                 = 300
  record              = module.app_service.default_hostname
}

resource "azurerm_app_service_custom_hostname_binding" "azure_domain" {
  hostname            = var.custom_domain_name
  app_service_name    = module.app_service.app_name
  resource_group_name = module.app_service.resource_group_name

  depends_on = [
    azurerm_dns_cname_record.azure_subdomain
  ]
}

module "databases" {
  source = "./modules/databases"

  resource_group_name = "rg-terraform-databases-europe"
  location            = "swedencentral"
  env                 = "global"

  mysql_admin_user = var.mysql_admin_user
  sql_admin_user   = var.sql_admin_user
  pg_admin_user    = var.pg_admin_user

  app_identity_principal_id = module.app_service.app_identity_principal_id

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
