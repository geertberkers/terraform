output "latest_revision_fqdn" {
  value       = azurerm_container_app.app.latest_revision_fqdn
  description = "The FQDN of the Container App"
}
