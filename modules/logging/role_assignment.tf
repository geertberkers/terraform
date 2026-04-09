resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.logging.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = var.app_identity_principal_id
}
