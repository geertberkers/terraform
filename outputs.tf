output "databases" {
  value = module.databases
}

output "dns_zone_name" {
  value = module.dns.zone_name
}

output "dns_nameservers" {
  value = module.dns.nameservers
}

output "app_hostname" {
  value = module.app_service.default_hostname
}

output "custom_domain_fqdn" {
  value = module.dns.cname_fqdn
}
