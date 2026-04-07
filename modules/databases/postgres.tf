resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "pg-flex-${var.env}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  administrator_login    = var.pg_admin_user
  administrator_password = random_password.pg_admin.result

  active_directory_auth_enabled = true
  sku_name = "B_Standard_B1ms"

  storage_mb = 32768
  version    = "14"

  backup_retention_days = 7

  public_network_access_enabled = true

  lifecycle {
    ignore_changes = [
      zone,
      high_availability
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}