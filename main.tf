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
}

provider "azurerm" {
  features {}

  use_oidc = true
}

# =========================
# SWITZERLAND
# =========================
module "switzerland" {
  source = "./modules/region"

  resource_group_name = "rg-switzerland-north"
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

  resource_group_name = "rg-sweden-central"
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
# APP SERVICE
# =========================
module "app_service" {
  source              = "./modules/app_service"
  resource_group_name = "rg-app-service-eu"
  location            = "westeurope"
  name_prefix         = "my-web-service"
}

# =========================
# DATABASES
# =========================
module "databases" {
  source = "./modules/databases"

  resource_group_name = "rg-databases-europe"
  location            = "swedencentral"
  env                 = "global"

  mysql_admin_user = var.mysql_admin_user
  sql_admin_user   = var.sql_admin_user
  pg_admin_user    = var.pg_admin_user

  app_service_name          = module.app_service.app_name
  app_service_rg            = "rg-app-service-eu"
  app_identity_principal_id = data.azurerm_linux_web_app.app.identity[0].principal_id

  sql_database_name = var.sql_database_name
}

# =========================
# APP HOSTING EXAMPLES
# =========================
# Below are examples of how to adopt the new web hosting architectures instead of VMs.
# Uncomment the one you want to use for your application footprint!

# module "my_app_service" {
#   source              = "./modules/app_service"
#   resource_group_name = "rg-app-service-eu"
#   location            = "swedencentral"
#   name_prefix         = "mywebapp"
# }

# module "my_container_apps" {
#   source              = "./modules/container_apps"
#   resource_group_name = "rg-ca-eu"
#   location            = "swedencentral"
#   name_prefix         = "myca"
# }

# module "my_aks" {
#   source              = "./modules/aks"
#   resource_group_name = "rg-aks-eu"
#   location            = "swedencentral"
#   name_prefix         = "myk8s"
# }
