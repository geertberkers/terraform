resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "mysql-${var.env}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  administrator_login    = var.mysql_admin_user
  administrator_password = var.mysql_admin_password

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