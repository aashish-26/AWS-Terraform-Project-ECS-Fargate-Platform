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
- **Container App Environment**:
  - Name: `<project>-<env>-env`.
  - Integrated with Log Analytics workspace for observability.
  - Public network access enabled (can be configured for internal-only).
- **Container App**:
  - Name: `<project>-<env>-app`.
  - Runtime: Node 20 app packaged as a Docker image (see `Dockerfile` and `app/server.js`).
  - Image source: Azure Container Registry (`infraacr<env>`) at `<login_server>/<project>-<env>-app:latest`.
  - Managed identity: User-assigned identity with AcrPull role on ACR.
  - Replicas: 1 min, 1 max (can scale based on load).
  - Ingress: External HTTP on port 8080.
  - Tags: `project`, `env` for cost allocation and filtering.
- **Azure Container Registry (ACR)**:
  - Name: `infraacr<env>` (for example, `infraacrdev`).
  - SKU: Basic (can be upgraded to Standard/Premium).
  - Admin access: Disabled (uses managed identity for authentication).
- **Log Analytics Workspace**:
  - Name: `<project>-<env>-logs`.
  - SKU: PerGB2018 (pay-per-use).
  - Retention: 30 days (configurable).
- **Terraform backend (Azure)**:
  - Resource group: `rg-terraform-backend-dev`.
  - Storage account: `tfstatebkdev7faa6`.
  - Container: `tfstate`.
  - Key: `infra-project/dev/terraform.tfstate`.

**Why Container Apps instead of App Service Plan?**  
Initially targeted App Service Plan + Linux Web App, but the subscription had zero quota for App Service Plans (Free and Basic VMs). Container Apps is serverless and doesn't require VM quotas, making it ideal for subscriptions with quota limitations. It's also a more modern, production-ready platform for containerized workloads.
