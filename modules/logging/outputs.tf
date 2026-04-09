output "storage_account_name" {
  value       = azurerm_storage_account.logging.name
  description = "The name of the logging storage account"
}

output "file_share_name" {
  value       = azurerm_storage_share.logging.name
  description = "The name of the logging file share"
}

output "storage_account_id" {
  value       = azurerm_storage_account.logging.id
  description = "The ID of the logging storage account"
}
