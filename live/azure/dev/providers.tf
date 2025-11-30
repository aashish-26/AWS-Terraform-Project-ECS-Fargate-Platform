// providers.tf
// Azure provider configuration for dev environment.
// Requires Terraform >= 1.5.0 and AzureRM provider >= 3.0.

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


