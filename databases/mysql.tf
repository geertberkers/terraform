resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-${var.env}"
  resource_group_name    = var.resource_group_name
  location               = var.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

  sku_name = "B_Standard_B1ms"
  version  = "8.0"

  storage_mb = 32768
  backup_retention_days = 7
}

resource "azurerm_mysql_flexible_database" "db" {
  name                = "appdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
