#!/bin/bash

set -e

BASE_DIR="databases"

echo "📁 Creating Terraform databases module structure..."

mkdir -p $BASE_DIR

# -------------------------
# main.tf
# -------------------------
cat > $BASE_DIR/main.tf <<'EOF'
# Databases module entrypoint

EOF

# -------------------------
# PostgreSQL
# -------------------------
cat > $BASE_DIR/postgres.tf <<'EOF'
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "pg-flex-${var.env}"
  resource_group_name    = var.resource_group_name
  location               = var.location

  administrator_login    = var.pg_admin_user
  administrator_password = var.pg_admin_password

  sku_name = "B_Standard_B1ms"

  storage_mb = 32768
  version    = "14"

  backup_retention_days = 7

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
EOF

# -------------------------
# MySQL
# -------------------------
cat > $BASE_DIR/mysql.tf <<'EOF'
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
EOF

# -------------------------
# SQL Server
# -------------------------
cat > $BASE_DIR/sql.tf <<'EOF'
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
EOF

# -------------------------
# Cosmos DB
# -------------------------
cat > $BASE_DIR/cosmos.tf <<'EOF'
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

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
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name

  partition_key_path = "/id"
}
EOF

# -------------------------
# variables.tf
# -------------------------
cat > $BASE_DIR/variables.tf <<'EOF'
variable "resource_group_name" {}
variable "location" {}
variable "env" {}

variable "pg_admin_user" {}
variable "pg_admin_password" {}

variable "mysql_admin_user" {}
variable "mysql_admin_password" {}

variable "sql_admin_user" {}
variable "sql_admin_password" {}
EOF

# -------------------------
# outputs.tf
# -------------------------
cat > $BASE_DIR/outputs.tf <<'EOF'
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.name
}

output "cosmos_endpoint" {
  value = azurerm_cosmosdb_account.cosmos.endpoint
}
EOF

echo "✅ Terraform databases module created at: $BASE_DIR"
