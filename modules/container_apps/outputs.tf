output "latest_revision_fqdn" {
  value       = azurerm_container_app.app.latest_revision_fqdn
  description = "The FQDN of the Container App"
}

output "container_app_id" {
  value = azurerm_container_app.app.id
}

output "custom_domain_verification_id" {
  value = azurerm_container_app.app.custom_domain_verification_id
}
