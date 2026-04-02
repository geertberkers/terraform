output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.cosmos.endpoint
}

output "cosmos_primary_key" {
  value     = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive = true
}