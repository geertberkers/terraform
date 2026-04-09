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
    identity_ids = [var.identity_id]
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

    # PostgreSQL
    "POSTGRES_HOST"     = var.postgres_config.host
    "POSTGRES_DB"       = var.postgres_config.db
    "POSTGRES_USER"     = var.postgres_config.user
    "POSTGRES_PASSWORD" = var.postgres_config.password

    # MySQL
    "MYSQL_HOST"     = var.mysql_config.host
    "MYSQL_DB"       = var.mysql_config.db
    "MYSQL_USER"     = var.mysql_config.user
    "MYSQL_PASSWORD" = var.mysql_config.password

    # SQL Server
    "SQLSERVER_HOST"     = var.sqlserver_config.host
    "SQLSERVER_DB"       = var.sqlserver_config.db
    "SQLSERVER_USER"     = var.sqlserver_config.user
    "SQLSERVER_PASSWORD" = var.sqlserver_config.password

    # Docker Registry Auth
    "DOCKER_REGISTRY_SERVER_URL"      = var.docker_registry_config.url
    "DOCKER_REGISTRY_SERVER_USERNAME" = var.docker_registry_config.username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = var.docker_registry_config.password
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