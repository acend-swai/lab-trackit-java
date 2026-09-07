# TrackIt on Azure Container Apps, with a managed PostgreSQL behind it.
#
# This configuration is written and validated, never applied. Applying it is out of
# scope for the lab, and .claude/hooks/check-infra.sh blocks `terraform apply` and
# `terraform destroy` at the tool call so that stays true.

locals {
  name = "trackit-${var.environment}"

  tags = {
    application = "trackit"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = "cae-${local.name}"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = local.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "psql-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  version                = "17"
  administrator_login    = var.db_administrator_login
  administrator_password = var.db_password

  # Smallest burstable tier. Cost is a review criterion, not an afterthought.
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false

  zone = "1"

  tags = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "trackit" {
  name      = "trackit"
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_container_app" "backend" {
  name                         = "ca-${local.name}-backend"
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type = "SystemAssigned"
  }

  secret {
    name  = "db-password"
    value = var.db_password
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "TRACKIT_DB_URL"
        value = "jdbc:postgresql://${azurerm_postgresql_flexible_server.this.fqdn}:5432/${azurerm_postgresql_flexible_server_database.trackit.name}"
      }

      env {
        name  = "TRACKIT_DB_USER"
        value = var.db_administrator_login
      }

      env {
        name        = "TRACKIT_DB_PASSWORD"
        secret_name = "db-password"
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/api/v1/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/api/v1/health"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
