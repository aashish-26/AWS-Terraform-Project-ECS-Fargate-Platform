## Deploy runbook – AWS dev (reference)

### Bootstrap backend (one-time per account)
./scripts/bootstrap-backend.sh --env dev --region us-east-1 --account-id 123456789012

### Plan (dev)
cd live/aws/dev
terraform init
terraform plan -var-file=dev.tfvars -out=plan.tfplan

### Apply (after approvals)
terraform apply plan.tfplan

### Smoke test
ALB_DNS=$(terraform output -raw alb_dns)
curl -fsS "http://${ALB_DNS}/health" || (echo "health check failed" && exit 1)

## Deploy runbook – Azure dev (primary)

### Preconditions
- Azure subscription with contributor rights for the target RG.
- Service principal created and stored as `AZURE_CREDENTIALS` GitHub secret.
- Terraform >= 1.5 installed locally if you plan to run commands by hand.

### Option A – GitHub Actions (recommended)
1. Push a feature branch and open a PR into `dev` or `main`.
2. Wait for the **Terraform Plan (azure dev)** workflow to complete and review the plan comment on the PR.
3. After approval, merge the PR.
4. In GitHub → **Actions → Terraform Apply (azure dev)**:
   - Click **Run workflow**.
   - Choose the branch you want to apply from (typically `dev` or `main`).
   - Keep `apply_environment = azure-dev`.
   - Monitor logs until `terraform apply` completes.

### Option B – Local Terraform (advanced users)
```bash
cd live/azure/dev
terraform init
terraform plan -var-file=dev.tfvars -out=dev.tfplan
terraform apply dev.tfplan
```

### Smoke test (Azure)
- From the Terraform outputs or Azure Portal, grab the Web App default hostname.  
- Open it in a browser or curl the `/` or `/health` endpoint once your app is deployed.