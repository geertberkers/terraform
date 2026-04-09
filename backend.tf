terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate12792"
    container_name       = "tfstate"
    key                  = "multi-cloud.tfstate"
  }
}
