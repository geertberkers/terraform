output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_user" {
  value     = azurerm_mysql_flexible_server.mysql.administrator_login
  sensitive = true
}

output "mysql_password" {
  value     = azurerm_mysql_flexible_server.mysql.administrator_password
  sensitive = true
}

output "mysql_db" {
  value = azurerm_mysql_flexible_server_database.db.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_user" {
  value     = azurerm_postgresql_flexible_server.postgres.administrator_login
  sensitive = true
}

output "postgres_password" {
  value     = azurerm_postgresql_flexible_server.postgres.administrator_password
  sensitive = true
}

output "postgres_db" {
  value = azurerm_postgresql_flexible_server_database.db.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_server_user" {
  value     = azurerm_mssql_server.sql.administrator_login
  sensitive = true
}

output "sql_server_password" {
  value     = azurerm_mssql_server.sql.administrator_login_password
  sensitive = true
}

output "sql_server_db" {
  value = azurerm_mssql_database.db.name
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.cosmos.endpoint
}
