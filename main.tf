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
# IDENTITY
# =========================
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "my-web-service-identity"
  location            = "westeurope"
  resource_group_name = "rg-terraform-app-service-eu"
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
# APP SERVICE
# =========================
module "app_service" {
  source              = "./modules/app_service"
  resource_group_name = "rg-terraform-app-service-eu"
  location            = "westeurope"
  name_prefix         = "my-web-service"
  identity_id         = azurerm_user_assigned_identity.app_identity.id

  postgres_config = {
    host     = module.databases.postgres_fqdn
    db       = "appdb"
    user     = var.pg_admin_user
    password = module.databases.postgres_password
  }

  mysql_config = {
    host     = module.databases.mysql_fqdn
    db       = "appdb"
    user     = var.mysql_admin_user
    password = module.databases.mysql_password
  }

  sqlserver_config = {
    host     = module.databases.sql_server_fqdn
    db       = "appdb"
    user     = var.sql_admin_user
    password = module.databases.sql_server_password
  }

  docker_registry_config = {
    url      = "https://ghcr.io"
    username = "geertberkers"
    password = var.gh_pat
  }
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
