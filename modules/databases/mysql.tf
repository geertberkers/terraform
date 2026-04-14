resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-${var.env}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = random_password.mysql_admin.result

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  storage {
    size_gb = 32
  }

  backup_retention_days = 7

  # required in newer provider versions
  # Optional but recommended: zone can cause issues in some regions
  # zone = "1"

  lifecycle {
    ignore_changes = [zone]
  }
}

# Allow Azure Services (including App Service) to connect
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.db_rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_flexible_server_database" "db" {
  name                = "appdb"
  resource_group_name = azurerm_resource_group.db_rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb3"
  collation           = "utf8mb3_general_ci"
}