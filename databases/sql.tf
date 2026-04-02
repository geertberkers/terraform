resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${var.env}"
  resource_group_name          = var.resource_group_name
  location                     = var.location

  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password

  version = "12.0"
}

resource "azurerm_mssql_database" "db" {
  name      = "appdb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}
