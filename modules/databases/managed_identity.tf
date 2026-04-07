data "azurerm_linux_web_app" "app" {
  name                = var.app_service_name
  resource_group_name = var.app_service_rg
}

# ==========================================
# PostgreSQL Managed Identity Access
# ==========================================
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "postgres_admin" {
  server_name         = azurerm_postgresql_flexible_server.postgres.name
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_linux_web_app.app.identity[0].principal_id
  principal_type      = "ServicePrincipal"
  principal_name      = "app-identity"
}

# ==========================================
# MySQL Managed Identity Access
# ==========================================
# MySQL doesn't support native Azure AD authentication
# Use connection string management via Key Vault + app settings instead

# ==========================================
# SQL Server Managed Identity Access
# ==========================================
resource "azurerm_mssql_server_microsoft_support_auditing_policy" "sql_audit" {
  server_id = azurerm_mssql_server.sql.id
  enabled   = true
}

# Create contained users for SQL Server via Terraform
# (Note: This requires using sql_admin credentials initially or a custom provider)
resource "null_resource" "sql_contained_user" {
  depends_on = [
    azurerm_mssql_database.db
  ]

  provisioner "local-exec" {
    command = <<-EOT
      sqlcmd -S "${azurerm_mssql_server.sql.fully_qualified_domain_name}" \
        -U "${var.sql_admin_user}" \
        -P "${random_password.sql_admin.result}" \
        -d "master" \
        -Q "CREATE USER [app-identity] FROM EXTERNAL PROVIDER;"
    EOT
  }
}



# ==========================================
# Key Vault Access for the Managed Identity
# ==========================================
resource "azurerm_key_vault_access_policy" "app_identity_kv" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  object_id = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}