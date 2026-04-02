resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-${var.env}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "appdb"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "items"
  resource_group_name = azurerm_resource_group.db_rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name

  partition_key_path = "/id"
}
