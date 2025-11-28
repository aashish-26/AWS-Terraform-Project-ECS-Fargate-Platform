// providers.tf
// Skeleton Azure provider configuration for dev environment.
// This is a placeholder to illustrate structure; actual Azure resources
// are not defined yet in this project.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "7faa6275-6840-45f2-bba2-d69d1ce640dc"
}


