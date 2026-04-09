resource "azurerm_resource_group" "identity_rg" {
  name     = "rg-identity-global"
  location = var.location
}

resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "id-app-service-global"
  location            = azurerm_resource_group.identity_rg.location
  resource_group_name = azurerm_resource_group.identity_rg.name
}

output "id" {
  value = azurerm_user_assigned_identity.app_identity.id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.app_identity.principal_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}

output "name" {
  value = azurerm_user_assigned_identity.app_identity.name
}

variable "location" {
  type    = string
  default = "westeurope"
}
