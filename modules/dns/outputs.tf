output "zone_name" {
  value       = data.azurerm_dns_zone.zone.name
  description = "The DNS zone name"
}

output "nameservers" {
  value       = data.azurerm_dns_zone.zone.name_servers
  description = "The Azure DNS nameservers for delegation"
}

output "cname_fqdn" {
  value       = "${azurerm_dns_cname_record.app_subdomain.name}.${data.azurerm_dns_zone.zone.name}"
  description = "The fully qualified CNAME record (e.g., azure.gb-coding.nl)"
}

output "custom_domain_binding_id" {
  value       = azurerm_app_service_custom_hostname_binding.custom_domain.id
  description = "The ID of the custom hostname binding"
}

output "managed_certificate_id" {
  value       = azurerm_app_service_managed_certificate.managed_cert.id
  description = "The ID of the Azure Managed Certificate"
}

output "certificate_binding_id" {
  value       = azurerm_app_service_certificate_binding.cert_binding.id
  description = "The ID of the SSL certificate binding"
}
