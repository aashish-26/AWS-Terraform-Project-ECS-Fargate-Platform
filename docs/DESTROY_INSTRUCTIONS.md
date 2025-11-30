# Infrastructure Destruction Instructions

This document provides step-by-step instructions to destroy all infrastructure in both AWS and Azure.

⚠️ **WARNING**: These commands will **permanently delete** all resources. Make sure you have backups if needed.

---

## 🗑️ Azure Infrastructure Destruction

### Option 1: Using Terraform (Recommended)

#### Step 1: Navigate to Azure dev directory
```bash
cd live/azure/dev
```

#### Step 2: Initialize Terraform (if not already done)
```bash
terraform init
```

#### Step 3: Review what will be destroyed
```bash
terraform plan -var-file=dev.tfvars -destroy
```

#### Step 4: Destroy all resources
```bash
terraform destroy -var-file=dev.tfvars
```

**What gets destroyed:**
- Container App (`infra-project-dev-app`)
- Container App Environment (`infra-project-dev-env`)
- Container Registry (`infraacrdev`)
- Log Analytics Workspace (`infra-project-dev-logs`)
- User-Assigned Managed Identity
- Role Assignments
- Resource Group (`rg-infra-project-dev`)

**Note**: Terraform state will remain in Azure Storage. To delete the state as well, see "Cleanup Terraform Backend" below.

---

### Option 2: Using Azure CLI

If Terraform destroy fails or you need to force cleanup:

```bash
# Set variables
RESOURCE_GROUP="rg-infra-project-dev"
ACR_NAME="infraacrdev"

# Delete resource group (this deletes everything in it)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Verify deletion
az group show --name $RESOURCE_GROUP
```

---

### Cleanup Terraform Backend (Optional)

If you want to delete the Terraform state storage as well:

```bash
# Delete the state container (WARNING: This deletes all state!)
az storage container delete \
  --name tfstate \
  --account-name tfstatebkdev7faa6 \
  --auth-mode login

# Or delete the entire storage account (if not used by other projects)
az storage account delete \
  --name tfstatebkdev7faa6 \
  --resource-group rg-terraform-backend-dev \
  --yes
```

---

## 🗑️ AWS Infrastructure Destruction

### Option 1: Using Terraform (Recommended)

#### Step 1: Navigate to AWS dev directory
```bash
cd live/aws/dev
```

#### Step 2: Initialize Terraform (if not already done)
```bash
terraform init
```

#### Step 3: Review what will be destroyed
```bash
terraform plan -var-file=dev.tfvars -destroy
```

#### Step 4: Destroy all resources
```bash
terraform destroy -var-file=dev.tfvars -auto-approve
```

**What gets destroyed:**
- ECS Fargate Service
- ECS Cluster
- ALB and Target Groups
- ECR Repository
- EC2 Postgres Instance
- VPC and Subnets
- Security Groups
- IAM Roles
- CloudWatch Resources
- All other AWS resources

**Note**: Terraform state will remain in S3. To delete the state as well, see "Cleanup Terraform Backend" below.

---

### Option 2: Using AWS CLI

If Terraform destroy fails or you need to force cleanup:

```bash
# Set variables
REGION="us-east-1"  # or your region
ENV="dev"

# Delete ECS Service (if exists)
aws ecs update-service \
  --cluster infra-project-${ENV}-cluster \
  --service infra-project-${ENV}-service \
  --desired-count 0 \
  --region $REGION

aws ecs delete-service \
  --cluster infra-project-${ENV}-cluster \
  --service infra-project-${ENV}-service \
  --region $REGION

# Delete ECS Cluster
aws ecs delete-cluster \
  --cluster infra-project-${ENV}-cluster \
  --region $REGION

# Delete ALB (requires deleting target groups first)
# ... (complex, better to use Terraform)

# Delete VPC (requires deleting all resources first)
# ... (complex, better to use Terraform)
```

**Recommendation**: Use Terraform destroy - it handles dependencies automatically.

---

### Cleanup Terraform Backend (Optional)

If you want to delete the Terraform state storage as well:

```bash
# Delete DynamoDB lock table
aws dynamodb delete-table \
  --table-name terraform-locks-infra-project \
  --region $REGION

# Delete S3 state bucket (must be empty first)
aws s3 rm s3://terraform-state-${ENV}-<account-id>/ --recursive
aws s3 rb s3://terraform-state-${ENV}-<account-id>/

# Delete KMS key (if not used elsewhere)
aws kms schedule-key-deletion \
  --key-id alias/terraform-state-key-${ENV} \
  --pending-window-in-days 7 \
  --region $REGION
```

---

## 🔄 Complete Cleanup Script

### Azure Complete Cleanup

```bash
#!/bin/bash
set -e

echo "🗑️  Destroying Azure infrastructure..."

cd live/azure/dev

# Destroy infrastructure
terraform destroy -var-file=dev.tfvars -auto-approve

echo "✅ Azure infrastructure destroyed!"
echo "⚠️  Note: Terraform state remains in Azure Storage"
echo "   To delete state: See DESTROY_INSTRUCTIONS.md"
```

### AWS Complete Cleanup

```bash
#!/bin/bash
set -e

echo "🗑️  Destroying AWS infrastructure..."

cd live/aws/dev

# Destroy infrastructure
terraform destroy -var-file=dev.tfvars -auto-approve

# Cleanup backend (optional)
# ./scripts/cleanup.sh --env dev

echo "✅ AWS infrastructure destroyed!"
echo "⚠️  Note: Terraform state remains in S3"
echo "   To delete state: See DESTROY_INSTRUCTIONS.md"
```

---

## ⚠️ Important Notes

1. **State Files**: Destroying infrastructure does NOT delete Terraform state files. They remain in:
   - Azure: Azure Storage (`tfstatebkdev7faa6`)
   - AWS: S3 bucket (`terraform-state-dev-<account-id>`)

2. **State Lock**: If destroy fails with "state locked", unlock it:
   ```bash
   # Azure
   terraform force-unlock <LOCK_ID>
   
   # AWS
   # Lock is in DynamoDB, Terraform will handle it
   ```

3. **Dependencies**: Terraform handles resource dependencies automatically. Manual deletion may fail if dependencies exist.

4. **Backups**: Before destroying, ensure you have:
   - Exported Terraform state (if needed)
   - Backed up any important data
   - Documented current configuration

5. **Cost**: Destroying resources stops all charges immediately (except for storage that may have retention policies).

---

## ✅ Verification

After destruction, verify resources are gone:

### Azure
```bash
# Check resource group
az group show --name rg-infra-project-dev
# Should return: Resource group 'rg-infra-project-dev' could not be found.

# Check ACR
az acr show --name infraacrdev
# Should return: Resource not found
```

### AWS
```bash
# Check ECS cluster
aws ecs describe-clusters --clusters infra-project-dev-cluster
# Should return: clusters: []

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:project,Values=infra-project"
# Should return: Vpcs: []
```

---

*Last updated: After project completion*

