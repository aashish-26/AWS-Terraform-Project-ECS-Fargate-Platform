// backend.tf
// Remote state backend configuration for Azure dev.
// Stores Terraform state in Azure Storage with encryption at rest.

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-backend-dev"
    storage_account_name = "tfstatebkdev7faa6"
    container_name       = "tfstate"
    key                  = "infra-project/dev/terraform.tfstate"
  }
}


