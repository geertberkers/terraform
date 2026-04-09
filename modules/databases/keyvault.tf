resource "random_id" "kv_suffix" {
  byte_length = 4
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-db-${var.env}-${random_id.kv_suffix.hex}"
  location            = azurerm_resource_group.db_rg.location
  resource_group_name = azurerm_resource_group.db_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Reverted to access policies because current principal lacks permissions to manage RBAC roles
  enable_rbac_authorization = false

  # Required for Terraform & deployments
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# ==========================================
# Allow Terraform (current user/SP) to manage secrets
# ==========================================
resource "azurerm_key_vault_access_policy" "terraform_admin" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
  ]
}

# ==========================================
# Random passwords
# ==========================================
resource "random_password" "mysql_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "pg_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "sql_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ==========================================
# Secrets
# ==========================================
resource "azurerm_key_vault_secret" "mysql_pass" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.terraform_admin]
}

resource "azurerm_key_vault_secret" "pg_pass" {
  name         = "pg-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.terraform_admin]
}

resource "azurerm_key_vault_secret" "sql_pass" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault_access_policy.terraform_admin]
}

resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "cosmos-connection"
  value        = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_cosmosdb_account.cosmos,
    azurerm_role_assignment.terraform_kv_admin
  ]
}