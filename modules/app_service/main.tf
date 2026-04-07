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
  name                = "${var.name_prefix}-app"
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
      java_version        = "17"
      java_server         = "TOMCAT"
      java_server_version = "10.1"
    }

    app_command_line = "java -jar /home/site/wwwroot/app.jar"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITE_USE_32BIT_WORKER_PROCESS"    = "false"
    "PORT"                                = "8080"
  }
}