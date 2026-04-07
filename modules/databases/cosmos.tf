resource "random_string" "cosmos_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-${var.env}-${random_string.cosmos_suffix.result}"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.db_rg.location
    failover_priority = 0
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "appdbcosmos"
  resource_group_name = azurerm_resource_group.db_rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "items"
  resource_group_name = azurerm_resource_group.db_rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name

  partition_key_paths = ["/id"]
}

data "azurerm_role_definition" "cosmos_contributor" {
  name  = "Cosmos DB Built-in Data Contributor"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "cosmos_access" {
  scope                = azurerm_cosmosdb_account.cosmos.id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = var.app_identity_principal_id
}