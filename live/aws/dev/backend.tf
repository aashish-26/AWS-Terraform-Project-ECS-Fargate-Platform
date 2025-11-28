// backend.tf
// Terraform backend configuration for the dev environment.
// This must be kept in sync with the names created by scripts/bootstrap-backend.sh
// and modules/bootstrap.
//
// Note:
// - Backend configuration cannot use normal Terraform variables.
// - Update the bucket, dynamodb_table, and kms_key_id values to match your account
//   before running terraform init for the first time.

terraform {
  backend "s3" {
    bucket         = "terraform-state-dev-471112729537" // TODO: replace with your actual account ID
    key            = "infra-project/terraform/state/dev/root.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks-infra-project-dev"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-dev"
  }
}


