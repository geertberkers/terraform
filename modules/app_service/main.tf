resource "azurerm_resource_group" "app_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.name_prefix}-plan"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  os_type             = "Linux"
  sku_name            = "B2"
}

resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "${var.name_prefix}-identity"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  site_config {
    always_on = true

    application_stack {
      docker_image     = "ghcr.io/geertberkers/terraform/multi-db-backend"
      docker_image_tag = "latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8080"

    # Database connection settings
    "POSTGRES_HOST"   = var.postgres_fqdn
    "MYSQL_HOST"      = var.mysql_fqdn
    "SQL_SERVER_HOST" = var.sql_server_fqdn
    "COSMOS_ENDPOINT" = var.cosmos_endpoint

    # Use managed identity for authentication
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.app_identity.client_id

    # Azure Storage for logging
    "AZURE_STORAGE_ACCOUNT" = var.azure_storage_account
    "AZURE_FILE_SHARE"      = var.azure_file_share
    "AZURE_LOG_DIRECTORY"   = var.azure_log_directory
  }

  depends_on = [
    azurerm_service_plan.asp
  ]

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_tag
    ]
  }
}
