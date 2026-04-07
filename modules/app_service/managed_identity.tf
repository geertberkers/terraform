output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app_identity.principal_id
}

output "app_identity_id" {
  value = azurerm_user_assigned_identity.app_identity.id
}

output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}