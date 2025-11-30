// Azure App module: Container Apps (serverless, no VM quota required).

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project = var.project
    env     = var.environment
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project}-${var.environment}-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    project = var.project
    env     = var.environment
  }
}

resource "azurerm_user_assigned_identity" "container_app" {
  name                = "${var.project}-${var.environment}-container-app-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = {
    project = var.project
    env     = var.environment
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = var.acr_id != null ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_container_app_environment" "this" {
  name                       = "${var.project}-${var.environment}-env"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  tags = {
    project = var.project
    env     = var.environment
  }
}

resource "azurerm_container_app" "this" {
  name                         = "${var.project}-${var.environment}-app"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  dynamic "registry" {
    for_each = var.container_registry_url != "" ? [1] : []
    content {
      server   = var.container_registry_url
      identity = azurerm_user_assigned_identity.container_app.id
    }
  }

  template {
    container {
      name   = "${var.project}-${var.environment}-container"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = "8080"
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    project = var.project
    env     = var.environment
  }
}


