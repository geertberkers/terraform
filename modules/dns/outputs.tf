output "zone_name" {
  value       = azurerm_dns_zone.zone.name
  description = "The DNS zone name"
}

output "nameservers" {
  value       = azurerm_dns_zone.zone.name_servers
  description = "The Azure DNS nameservers for delegation"
}

output "cname_fqdn" {
  value       = "${azurerm_dns_cname_record.app_subdomain.name}.${azurerm_dns_zone.zone.name}"
  description = "The fully qualified CNAME record (e.g., azure.gb-coding.nl)"
}

output "custom_domain_binding_id" {
  value       = azurerm_app_service_custom_hostname_binding.custom_domain.id
  description = "The ID of the custom hostname binding"
}
