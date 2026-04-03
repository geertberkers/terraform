resource "azurerm_service_plan" "asp" {
  name                = "${var.name_prefix}-asp"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "B2" # B2 for Java/Kotlin apps
}

resource "azurerm_linux_web_app" "app" {
  name                = "${var.name_prefix}-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = true # Required for Java apps
    
    application_stack {
      java_version      = "17"
      java_server       = "TOMCAT"
      java_server_version = "10.1"
    }

    app_command_line = "java -jar /home/site/wwwroot/app.jar"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"    = "false"
    "WEBSITE_USE_32BIT_WORKER_PROCESS"       = "false"
    "PORT"                                   = "8080"
  }

  identity {
    type = "UserAssigned"
  }
}
