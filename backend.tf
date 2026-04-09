terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-tfstate"
    storage_account_name = "tfstate12792"
    container_name       = "tfstate"
    key                  = "multi-cloud.tfstate"
  }
}
