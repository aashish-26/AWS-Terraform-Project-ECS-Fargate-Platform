## Azure-first Terraform Infrastructure – App Platform (with AWS reference stack)

### Purpose
Provision a production-aligned infrastructure stack using Terraform, now **Azure-first** with an **AWS ECS Fargate reference implementation**.  
The project demonstrates multi-cloud patterns: remote state, CI/CD, least-privilege access, security guardrails, and observability.

### High-level Scope
- **Azure (primary)**: Container-based web app stack on Azure App Service (Linux) pulling images from Azure Container Registry, with remote Terraform state in Azure Storage and GitHub Actions for plan/apply and image build.
- **AWS (reference)**: Full ECS Fargate platform with VPC, ALB, ECR, EC2 Postgres, CloudWatch monitoring, and S3/DynamoDB backend.

---

### Azure Architecture Overview (current primary)
- Resource group per environment (for example, `rg-infra-project-dev`).
- **Azure Container Apps** (`azurerm_container_app`) – serverless container platform (no VM quota required).
- Container App Environment (`azurerm_container_app_environment`) with Log Analytics workspace for observability.
- User-assigned managed identity for secure ACR authentication (AcrPull role).
- Azure Container Registry (`azurerm_container_registry`) created and managed via Terraform in `live/azure/dev`.
- Remote Terraform state stored in Azure Storage (`backend "azurerm"` in `live/azure/dev/backend.tf`).
- GitHub Actions workflows:
  - `Terraform Plan (azure dev)` – PR-based plan, linting, security, and policy-as-code.
  - `Terraform Apply (azure dev)` – manual, protected apply from a reviewed plan file.
  - `Azure Image Build and Push (dev)` – builds the Docker image from this repo, scans it with Trivy, generates an SBOM, and pushes to Azure Container Registry.

> **Why Container Apps?** Container Apps is serverless and doesn't require App Service Plan VM quotas, making it ideal for subscriptions with quota limitations. It's also a modern, production-ready alternative to App Service for containerized workloads.

> Note: Additional Azure components (Key Vault, Azure Database for PostgreSQL, Azure Monitor / Application Insights) are documented as the next iteration and can be layered in using the same patterns.

### AWS Architecture Overview (reference implementation)
- VPC (public subnets for demo)
- ALB + target group
- ECS Cluster + Fargate Service + Task Definition
- ECR registry
- Postgres on EC2
- Secrets Manager (DB credentials)
- KMS CMK (state + secrets)
- S3 remote state + DynamoDB lock table
- CloudWatch logs, metrics, dashboards, alarms
- IAM roles: deploy role, exec role, developer read-only role, admin

---

### Migration Story: from AWS ECS Fargate to Azure App Service
- **Containers / compute**: ECS Fargate → Azure App Service (Linux) for a simpler, PaaS-style runtime in this repo.  
  The same patterns (immutable image, health checks, rolling deploys) can be carried over to Azure Container Apps or AKS.
- **Registry**: ECR → Azure Container Registry (planned extension; current app uses built-in runtime).
- **Database**: EC2-hosted Postgres → Azure Database for PostgreSQL Flexible Server (planned extension).
- **Secrets**: AWS Secrets Manager → Azure Key Vault (planned extension).
- **State backend**: S3 + DynamoDB → Azure Storage account container (`backend "azurerm"`).
- **Monitoring**: CloudWatch + SNS → Azure Monitor + Log Analytics + action groups (planned extension).

This repo intentionally keeps the original AWS implementation as a **reference** while showing how to stand up and run an equivalent app stack on Azure using Terraform and GitHub Actions.

---

### Repo Structure
- `docs/`
- `modules/`
- `live/aws/dev`, `live/aws/prod` (reference AWS ECS stack)
- `live/azure/dev`, `live/azure/prod` (Azure App Service stack)
- `ci/github_actions/` (AWS CI pipelines)
- `.github/workflows/` (Azure CI pipelines)
- `scripts/`

> Some directories began as placeholders and were filled in as the AWS and Azure implementations were added.

### Pre-Deployment Requirements (Azure)
- Azure subscription with permissions to create Resource Groups, Container Apps, Container App Environments, Log Analytics Workspaces, and Container Registries.
- **No VM quota required**: Container Apps is serverless and doesn't require App Service Plan quotas, making it ideal for subscriptions with quota limitations.
- Service principal credentials stored as `AZURE_CREDENTIALS` GitHub secret (used by Azure login action).
- Terraform >= 1.5 (see `.terraform-version`).
- GitHub Actions enabled for the repository.

> **Note**: Container Apps uses a consumption-based pricing model with a generous free tier (180,000 vCPU seconds, 360,000 GiB seconds, and 2 million requests per month), making it cost-effective for development and small workloads.

### How to Deploy Azure (dev) via GitHub Actions
1. Push a feature branch and open a PR into `dev` or `main`.
2. GitHub runs **Terraform Plan (azure dev)**:
   - Executes fmt/validate/tflint/tfsec/conftest.
   - Generates a plan and comments it on the PR.
3. After review, merge the PR.
4. Go to **Actions → Terraform Apply (azure dev)**:
   - Click **Run workflow**, choose the branch (for example, `dev`), and keep `apply_environment = azure-dev`.
   - The workflow logs show `terraform init` + `terraform apply` running against `live/azure/dev`.

### How to Deploy AWS (dev) – Reference Flow
```bash
./scripts/bootstrap-backend.sh --env dev --region us-east-1 --account-id <id>

cd live/aws/dev
terraform init
terraform plan -var-file=dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan

ALB_DNS=$(terraform output -raw alb_dns)
curl -fsS "http://${ALB_DNS}/health"
```

### How to Destroy AWS (dev) – Reference Flow
```bash
cd live/aws/dev
terraform destroy -var-file=dev.tfvars -auto-approve
./scripts/cleanup.sh --env dev
```

### Observability (current state)
- **AWS stack**: CloudWatch Logs + CloudWatch Metrics, dashboards and alarms via `modules/monitoring`, alerting via SNS.
- **Azure stack**: Web App metrics and logs available in Azure Portal, and can be extended with Log Analytics workspaces, Application Insights, and alert rules using the same Terraform patterns.

### Owners
- **Infra Owner:** Aashish  
- **Security Owner:** Aashish  
- **SRE Owner:** Aashish  
- **CI/CD Owner:** Aashish  
