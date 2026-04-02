provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate-rg"
  location = "westeurope"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
