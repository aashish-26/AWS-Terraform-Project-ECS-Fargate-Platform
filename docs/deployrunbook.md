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
- From the Terraform outputs or Azure Portal, grab the Container App FQDN (fully qualified domain name).
- Open it in a browser or curl the `/` or `/health` endpoint once your app is deployed:
  ```bash
  CONTAINER_APP_FQDN=$(terraform output -raw container_app_fqdn)
  curl -fsS "http://${CONTAINER_APP_FQDN}/health" || (echo "health check failed" && exit 1)
  ```

### Troubleshooting common issues

**Issue: "MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.App'"**
- Solution: Register the resource provider: `az provider register --namespace Microsoft.App`
- Wait until status shows "Registered": `az provider show -n Microsoft.App --query "registrationState" -o tsv`

**Issue: "Current Limit (Basic VMs): 0" or "Current Limit (Free VMs): 0"**
- This error occurs if you try to use App Service Plan instead of Container Apps.
- Container Apps doesn't require VM quotas (it's serverless).
- If you see this, ensure you're using the Container Apps module, not App Service Plan.

**Issue: Container App fails to pull image with authentication errors**
- Verify the managed identity has AcrPull role: `az role assignment list --scope <acr-id> --assignee <identity-id>`
- Ensure `depends_on` is set correctly in the Terraform configuration (role assignment must complete before app creation).

See `docs/TROUBLESHOOTING.md` for more detailed troubleshooting steps.