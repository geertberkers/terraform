output "default_hostname" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "The default hostname of the App Service"
}

output "web_app_id" {
  value       = azurerm_linux_web_app.app.id
  description = "The ID of the App Service"
}

output "app_name" {
  value       = azurerm_linux_web_app.app.name
  description = "The name of the App Service"
}

output "resource_group_name" {
  value       = azurerm_resource_group.app_rg.name
  description = "Resource group name where the app is deployed"
}

output "service_plan_id" {
  value       = azurerm_service_plan.asp.id
  description = "App Service Plan ID"
}

# SystemAssigned Identity (correct way)
output "principal_id" {
  value       = azurerm_linux_web_app.app.identity[0].principal_id
  description = "System Assigned Managed Identity Principal ID"
}

output "tenant_id" {
  value       = azurerm_linux_web_app.app.identity[0].tenant_id
  description = "Tenant ID of the Managed Identity"
}