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

output "app_hostname_free" {
  value       = module.app_service_free.default_hostname
  description = "Free tier App Service hostname"
}

output "custom_domain_fqdn" {
  value = module.dns.cname_fqdn
}

output "custom_domain_fqdn_free" {
  value       = try(module.dns_free[0].cname_fqdn, "")
  description = "Free tier custom domain FQDN. Empty when free-tier custom domain binding is disabled."
}

output "ssl_certificate_binding_id" {
  value = module.dns.certificate_binding_id
}

output "managed_certificate_id" {
  value = module.dns.managed_certificate_id
}

# =========================
# REGION (SSH / IP)
# =========================
output "switzerland_public_ip" {
  value = module.switzerland.public_ip
}

output "switzerland_ssh_commands" {
  value = module.switzerland.ssh_commands
}

output "sweden_public_ip" {
  value = module.sweden.public_ip
}

output "sweden_ssh_commands" {
  value = module.sweden.ssh_commands
}

# =========================
# KUBERNETES CLUSTER
# =========================
output "aks_resource_group" {
  value       = module.aks_cheap.resource_group_name
  description = "Resource group containing the AKS cluster"
}

output "aks_cluster_name" {
  value       = module.aks_cheap.cluster_name
  description = "Name of the AKS cluster"
}

output "aks_kube_config" {
  value       = module.aks_cheap.kube_config_raw
  sensitive   = true
  description = "Raw Kubernetes configuration for cluster access"
}
