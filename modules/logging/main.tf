resource "azurerm_storage_account" "logging" {
  name                     = "log-${var.name_prefix}${random_string.suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "logging" {
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.logging.name
  quota                = var.file_share_quota
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}
