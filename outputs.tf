output "databases" {
  value     = module.databases
  sensitive = true
}

output "database_endpoints" {
  value = {
    postgres = module.databases.postgres_fqdn
    mysql    = module.databases.mysql_fqdn
    sql      = module.databases.sql_server_fqdn
    cosmos   = module.databases.cosmos_endpoint
  }
}

output "dns_zone_name" {
  value = module.dns.zone_name
}

# output "dns_nameservers" {
#  value = module.dns.nameservers
# }

output "app_hostname" {
  value = module.app_service.default_hostname
}

output "custom_domain_fqdn" {
  value = module.dns.cname_fqdn
}

output "ssl_certificate_binding_id" {
  value = module.dns.certificate_binding_id
}

output "managed_certificate_id" {
  value = module.dns.managed_certificate_id
}
