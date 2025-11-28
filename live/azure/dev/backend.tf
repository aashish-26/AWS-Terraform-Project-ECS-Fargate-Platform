// backend.tf
// Placeholder backend configuration for Azure dev.
// When you add Azure support, configure this to use Azure Storage or another backend.

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend-dev"
    storage_account_name = "tfstatebkdev7faa6"
    container_name       = "tfstate"
    key                  = "infra-project/dev/terraform.tfstate"
  }
}


