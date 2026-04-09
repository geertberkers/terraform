output "default_hostname" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "The Default Hostname associated with the App Service"
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
  description = "The resource group used by the App Service"
}
