resource "azurerm_dns_zone" "zone" {
  name                = var.zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_cname_record" "app_subdomain" {
  name                = var.subdomain_name
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_dns_zone.zone.resource_group_name
  ttl                 = var.ttl
  record              = var.app_hostname
}

resource "azurerm_dns_txt_record" "domain_verification" {
  count = var.domain_verification_value != "" ? 1 : 0

  name                = "asuid.${var.subdomain_name}"
  zone_name           = azurerm_dns_zone.zone.name
  resource_group_name = azurerm_dns_zone.zone.resource_group_name
  ttl                 = 300

  record {
    value = var.domain_verification_value
  }
}

resource "azurerm_app_service_custom_hostname_binding" "custom_domain" {
  hostname            = var.custom_domain_name
  app_service_name    = var.app_service_name
  resource_group_name = var.resource_group_name
}
