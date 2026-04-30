resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.name_prefix}-cae"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app" "app" {
  name                         = "${var.name_prefix}-ca"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "multi-db-backend"
      image  = "ghcr.io/geertberkers/terraform/multi-db-backend:${var.docker_image_tag}"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "POSTGRES_HOST"
        value = var.postgres_fqdn
      }
      env {
        name  = "POSTGRES_USER"
        value = var.postgres_user
      }
      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }
      env {
        name  = "POSTGRES_DB"
        value = var.postgres_db
      }
      env {
        name  = "POSTGRES_PORT"
        value = "5432"
      }

      env {
        name  = "MYSQL_HOST"
        value = var.mysql_fqdn
      }
      env {
        name  = "MYSQL_USER"
        value = var.mysql_user
      }
      env {
        name        = "MYSQL_PASSWORD"
        secret_name = "mysql-password"
      }
      env {
        name  = "MYSQL_DB"
        value = var.mysql_db
      }
      env {
        name  = "MYSQL_PORT"
        value = "3306"
      }

      env {
        name  = "SQL_SERVER_HOST"
        value = var.sql_server_fqdn
      }
      env {
        name  = "SQLSERVER_USER"
        value = var.sql_server_user
      }
      env {
        name        = "SQLSERVER_PASSWORD"
        secret_name = "sqlserver-password"
      }
      env {
        name  = "SQLSERVER_DB"
        value = var.sql_server_db
      }
      env {
        name  = "SQLSERVER_PORT"
        value = "1433"
      }

      env {
        name  = "COSMOS_ENDPOINT"
        value = var.cosmos_endpoint
      }
      env {
        name        = "COSMOS_CONNECTION_STRING"
        secret_name = "cosmos-connection-string"
      }

      env {
        name  = "AZURE_CLIENT_ID"
        value = var.app_identity_client_id
      }
      env {
        name  = "AZURE_IDENTITY_NAME"
        value = var.app_identity_name
      }

      env {
        name  = "APP_VERSION_NAME"
        value = var.app_version_name
      }
      env {
        name  = "APP_VERSION_CODE"
        value = var.app_version_code
      }
      env {
        name  = "PORT"
        value = "8080"
      }
    }
  }

  secret {
    name  = "postgres-password"
    value = var.postgres_password
  }
  secret {
    name  = "mysql-password"
    value = var.mysql_password
  }
  secret {
    name  = "sqlserver-password"
    value = var.sql_server_password
  }
  secret {
    name  = "cosmos-connection-string"
    value = var.cosmos_connection_string
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
