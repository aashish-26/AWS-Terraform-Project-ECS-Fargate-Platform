// main.tf
// Placeholder root configuration for Azure dev environment.
// No resources are currently defined. This file exists to mirror the
// live/aws/dev structure and can be filled in when Azure support is added.

terraform {
  required_version = ">= 1.5.0"
}

resource "azurerm_container_registry" "this" {
  name                = "infraacr${var.environment}"
  resource_group_name = "rg-${var.project}-${var.environment}"
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    project = var.project
    env     = var.environment
  }
}

module "app" {
  source = "../../../modules/azure_app"

  project             = var.project
  environment         = var.environment
  location            = var.location
  resource_group_name = "rg-${var.project}-${var.environment}"

  container_image        = "${azurerm_container_registry.this.login_server}/${var.project}-${var.environment}-app:latest"
  container_registry_url = azurerm_container_registry.this.login_server
  acr_id                 = azurerm_container_registry.this.id
}

