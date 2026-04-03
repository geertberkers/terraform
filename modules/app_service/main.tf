resource "azurerm_service_plan" "asp" {
  name                = "${var.name_prefix}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1" # Basic tier for cost-effectiveness
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = false # B1 supports this, but setting false avoids some deployment hiccups if they decide to downgrade to Free
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
}
