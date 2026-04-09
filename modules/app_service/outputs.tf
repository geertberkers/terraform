output "default_hostname" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "The Default Hostname associated with the App Service"
}

output "web_app_id" {
  value       = azurerm_linux_web_app.app.id
  description = "The ID of the App Service"
}
