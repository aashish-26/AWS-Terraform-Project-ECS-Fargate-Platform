// main.tf
// Placeholder root configuration for Azure dev environment.
// No resources are currently defined. This file exists to mirror the
// live/aws/dev structure and can be filled in when Azure support is added.

terraform {
  required_version = ">= 1.5.0"
}

// Simple dev resource group so Azure deployment actually creates something.
resource "azurerm_resource_group" "dev" {
  name     = "rg-infra-${var.environment}"
  location = var.location

  tags = {
    env     = var.environment
    project = "infra-project"
  }
}

