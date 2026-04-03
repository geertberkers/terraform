# Managed Identity for the web app to access databases
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "${var.name_prefix}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Add identity to the web app
resource "azurerm_linux_web_app" "app_with_identity" {
  depends_on = [azurerm_linux_web_app.app]

  name                = azurerm_linux_web_app.app.name
  location            = azurerm_linux_web_app.app.location
  resource_group_name = azurerm_linux_web_app.app.resource_group_name
  service_plan_id     = azurerm_linux_web_app.app.service_plan_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }
}

# Output the identity details for database role assignments
output "app_identity_principal_id" {
  value = azurerm_user_assigned_identity.app_identity.principal_id
}

output "app_identity_id" {
  value = azurerm_user_assigned_identity.app_identity.id
}

output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app_identity.client_id
}
