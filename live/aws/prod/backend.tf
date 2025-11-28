// backend.tf
// Terraform backend configuration for the prod environment.
// Update these values to match the real backend resources created for prod.

terraform {
  backend "s3" {
    bucket         = "terraform-state-prod-471112729537" // TODO: replace with your actual account ID
    key            = "infra-project/terraform/state/prod/root.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks-infra-project-prod"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-prod"
  }
}


