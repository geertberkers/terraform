output "databases" {
  value = module.databases
}

output "custom_domain_name" {
  value = var.custom_domain_name
}

output "dns_zone_name" {
  value = azurerm_dns_zone.gb_coding.name
}

output "dns_name_servers" {
  value = azurerm_dns_zone.gb_coding.name_servers
}

output "app_hostname" {
  value = module.app_service.default_hostname
}