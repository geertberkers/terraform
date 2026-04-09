# Databases module entrypoint

resource "azurerm_resource_group" "db_rg" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_subscription" "current" {}
