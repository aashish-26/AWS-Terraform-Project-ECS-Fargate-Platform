# Troubleshooting Guide

## Azure Quota Errors

### Error: "Current Limit (Basic VMs): 0" or "Current Limit (Free VMs): 0"

**Symptom:**
```
Error: creating App Service Plan: unexpected status 401 (401 Unauthorized) with response: 
{"Code":"Unauthorized","Message":"Operation cannot be completed without additional quota. 
Additional details - Location: Current Limit (Basic VMs): 0 ..."}
```

**Cause:**
Your Azure subscription has a quota limit of 0 for App Service Plans. This is common on:
- Student/trial subscriptions
- New subscriptions that haven't been activated for App Service usage
- Subscriptions with restricted quotas

**Solution:**

1. **Request a quota increase (recommended):**
   - Go to **Azure Portal → Subscriptions → Your subscription → Usage + quotas**
   - Search for **"App Service Plans"** or **"App Service (Free VMs)"** or **"App Service (Basic VMs)"**
   - Click **Request increase** and request at least 1 VM
   - Wait for approval (usually instant for Free tier, may take time for Basic/Standard)

2. **Alternative: Use a different subscription**
   - If quota increases aren't possible, use a subscription that already has App Service quota enabled

3. **Alternative: Use Azure Container Apps (future enhancement)**
   - Azure Container Apps is serverless and may not have the same quota restrictions
   - This would require modifying the Terraform code to use `azurerm_container_app` instead of `azurerm_service_plan` + `azurerm_linux_web_app`

**Workaround for demo purposes:**
If you cannot get quota increases, you can still demonstrate the Terraform code, CI/CD workflows, and architecture by:
- Running `terraform plan` (which will show what would be created)
- Documenting the quota limitation in your project overview
- Explaining that in production, quota increases would be requested as part of the onboarding process

---

## Container Apps Resource Provider Registration

### Error: "MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.App'"

**Symptom:**
```
Error: creating Managed Environment: unexpected status 409 (409 Conflict) with error: 
MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.App'. 
See https://aka.ms/rps-not-found for how to register subscriptions.
```

**Cause:**
Azure Container Apps requires the `Microsoft.App` resource provider to be registered in your subscription. This is a one-time registration.

**Solution:**

1. **Register the resource provider via Azure CLI:**
   ```bash
   az provider register --namespace Microsoft.App
   ```

2. **Check registration status:**
   ```bash
   az provider show -n Microsoft.App --query "registrationState" -o tsv
   ```
   Wait until it shows `Registered` (usually takes 1-3 minutes).

3. **Alternative: Register via Azure Portal:**
   - Go to **Azure Portal → Subscriptions → Your subscription → Resource providers**
   - Search for `Microsoft.App`
   - Click **Register** and wait for completion

4. **After registration completes, re-run Terraform:**
   ```bash
   terraform apply
   ```

**Note:** You may also need to register `Microsoft.OperationalInsights` if you encounter similar errors with Log Analytics, though this is usually already registered.

---

## Service Principal Access Issues

### Error: "No subscriptions found for [clientId]"

**Symptom:**
```
No subscriptions found for b786b4ba-38ef-4042-84a5-d659a97bbdea.
```

**Cause:**
The service principal used by GitHub Actions doesn't have any role assignments on your subscription.

**Solution:**
1. Go to **Azure Portal → Subscriptions → Your subscription → Access control (IAM)**
2. Click **Add → Add role assignment**
3. Role: **Contributor** (or Owner if needed)
4. Assign access to: **User, group, or service principal**
5. Search for your app registration name and select it
6. Save and wait 1-2 minutes for propagation

---

## State Lock Errors

### Error: "state blob is already locked"

**Symptom:**
```
Error: Error acquiring the state lock
Error message: state blob is already locked
```

**Cause:**
A previous Terraform operation failed and didn't release the lock.

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
# Type "yes" when prompted
```

The lock ID is shown in the error message.

---

## Container Registry Not Found

### Error: "The resource with name 'infraacrdev' and type 'Microsoft.ContainerRegistry/registries' could not be found"

**Symptom:**
GitHub Actions image build workflow fails with this error.

**Cause:**
The Azure Container Registry hasn't been created yet. Terraform needs to run first.

**Solution:**
1. Run `terraform apply` to create the infrastructure (including ACR)
2. Then re-run the image build workflow

**Order of operations:**
1. Terraform Plan → Terraform Apply (creates ACR + App Service Plan + Web App)
2. Azure Image Build and Push (builds and pushes image to ACR)
3. Web App will pull the image from ACR automatically

