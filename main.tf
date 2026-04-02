terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

# variable "ssh_public_key" {
#   type = string
# }

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
# DATABASES
# =========================
module "databases" {
  source = "./modules/databases"

  resource_group_name = "rg-databases-europe"
  location            = "westeurope"
  env                 = "global"

  mysql_admin_user     = var.mysql_admin_user
  mysql_admin_password = var.mysql_admin_password

  sql_admin_user     = var.sql_admin_user
  sql_admin_password = var.sql_admin_password

  pg_admin_user     = var.pg_admin_user
  pg_admin_password = var.pg_admin_password
}
