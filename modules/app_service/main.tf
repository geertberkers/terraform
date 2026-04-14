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

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_identity_id]
  }

  site_config {
    always_on = true

    application_stack {
      docker_image_name = "ghcr.io/geertberkers/terraform/multi-db-backend:${var.docker_image_tag}"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8080"

    # Docker deployment info
    "DOCKER_IMAGE" = "ghcr.io/geertberkers/terraform/multi-db-backend"
    "DOCKER_TAG"   = var.docker_image_tag

    # Database connection settings
    "POSTGRES_HOST"     = var.postgres_fqdn
    "POSTGRES_USER"     = var.postgres_user
    "POSTGRES_PASSWORD" = var.postgres_password_secret_uri != "" ? "@Microsoft.KeyVault(SecretUri=${var.postgres_password_secret_uri})" : var.postgres_password
    "POSTGRES_DB"       = var.postgres_db
    "POSTGRES_PORT"     = "5432"

    "MYSQL_HOST"     = var.mysql_fqdn
    "MYSQL_USER"     = var.mysql_user
    "MYSQL_PASSWORD" = var.mysql_password_secret_uri != "" ? "@Microsoft.KeyVault(SecretUri=${var.mysql_password_secret_uri})" : var.mysql_password
    "MYSQL_DB"       = var.mysql_db
    "MYSQL_PORT"     = "3306"

    "SQL_SERVER_HOST"    = var.sql_server_fqdn
    "SQLSERVER_USER"     = var.sql_server_user
    "SQLSERVER_PASSWORD" = var.sql_server_password_secret_uri != "" ? "@Microsoft.KeyVault(SecretUri=${var.sql_server_password_secret_uri})" : var.sql_server_password
    "SQLSERVER_DB"       = var.sql_server_db
    "SQLSERVER_PORT"     = "1433"

    "COSMOS_ENDPOINT"          = var.cosmos_endpoint
    "COSMOS_CONNECTION_STRING" = var.cosmos_connection_secret_uri != "" ? "@Microsoft.KeyVault(SecretUri=${var.cosmos_connection_secret_uri})" : ""

    # Use managed identity for authentication (for databases, not logging)
    "AZURE_CLIENT_ID" = var.app_identity_client_id

    # Azure Storage for logging (using access key instead of managed identity)
    "AZURE_STORAGE_ACCOUNT" = var.azure_storage_account
    "AZURE_FILE_SHARE"      = var.azure_file_share
    "AZURE_LOG_DIRECTORY"   = var.azure_log_directory
    "AZURE_STORAGE_KEY"     = var.azure_storage_key
  }

  depends_on = [
    azurerm_service_plan.asp
  ]

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name
    ]
  }
}
