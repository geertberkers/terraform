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
      docker_image_name   = "ghcr.io/geertberkers/terraform/multi-db-backend:latest"
      docker_registry_url = "https://ghcr.io"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "8080"
  }
}