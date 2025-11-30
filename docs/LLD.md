## AWS low-level design (reference)

VPC: 10.20.0.0/16
Public subnets:
 - us-east-1a: 10.20.0.0/24
 - us-east-1b: 10.20.1.0/24

Backend:
 - S3 key: infra-project/terraform/state/<env>/<component>.tfstate
 - DynamoDB: terraform-locks-infra-project
 - KMS alias: alias/terraform-state-key-dev

## Azure low-level design (primary)

- Resource group: `rg-<project>-<env>` (for example, `rg-infra-project-dev`).
- Region: `eastus` for dev by default.
- App Service Plan:
  - `os_type = "Linux"`
  - `sku_name = "F1"` (Free tier for demo; can be bumped to `B1`, `P1v2`, etc.)
- Linux Web App:
  - Name: `<project>-<env>-webapp`.
  - Runtime: Node 18 LTS via `application_stack.node_version`.
  - Tags: `project`, `env` for cost allocation and filtering.
- Terraform backend (Azure):
  - Resource group: `rg-terraform-backend-dev`.
  - Storage account: `tfstatebkdev7faa6`.
  - Container: `tfstate`.
  - Key: `infra-project/dev/terraform.tfstate`.
