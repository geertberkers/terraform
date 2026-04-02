resource "random_string" "sql_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_mssql_server" "sql" {
  name = "sql-${var.env}-${random_string.sql_suffix.result}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password

  version = "12.0"

  minimum_tls_version = "1.2"
}

# Allow Azure services (required for connectivity in most setups)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "db" {
  name      = "appdb"
  server_id = azurerm_mssql_server.sql.id

  sku_name = "Basic"

  depends_on = [
    azurerm_mssql_server.sql
  ]
}