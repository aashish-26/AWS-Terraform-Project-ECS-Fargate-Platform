# 🗑️ Complete Infrastructure Destruction Guide

## ⚠️ WARNING
**This will PERMANENTLY DELETE all infrastructure in both AWS and Azure!**

Make sure you:
- ✅ Have backups if needed
- ✅ Don't need the infrastructure anymore
- ✅ Understand this is irreversible

---

## 📋 What Will Be Destroyed

### Azure (7 resources):
1. Container App (`infra-project-dev-app`)
2. Container App Environment (`infra-project-dev-env`)
3. Container Registry (`infraacrdev`)
4. Log Analytics Workspace (`infra-project-dev-logs`)
5. User-Assigned Managed Identity
6. Role Assignment (AcrPull)
7. Resource Group (`rg-infra-project-dev`)

### AWS (if deployed):
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

---

## 🚀 Quick Destroy Commands

### Azure Destruction

```powershell
# Navigate to Azure dev directory
cd "F:\Terraform project\Proj1\live\azure\dev"

# Review what will be destroyed (optional)
terraform plan -destroy -var-file .\dev.tfvars

# Destroy all resources
terraform destroy -var-file .\dev.tfvars
```

**Type `yes` when prompted to confirm.**

---

### AWS Destruction (if deployed)

```bash
# Navigate to AWS dev directory
cd live/aws/dev

# Review what will be destroyed (optional)
terraform plan -destroy -var-file=dev.tfvars

# Destroy all resources
terraform destroy -var-file=dev.tfvars -auto-approve
```

**Note**: AWS infrastructure may not be deployed due to account restrictions.

---

## ✅ Verification After Destruction

### Azure
```powershell
# Check if resource group is gone
az group show --name rg-infra-project-dev
# Should return: Resource group 'rg-infra-project-dev' could not be found.
```

### AWS
```bash
# Check if ECS cluster is gone
aws ecs describe-clusters --clusters infra-project-dev-cluster
# Should return: clusters: []
```

---

## 📝 Notes

1. **Terraform State**: State files remain in storage (Azure Storage / S3). To delete them:
   - Azure: Delete the storage container or account
   - AWS: Delete the S3 bucket and DynamoDB table

2. **State Lock**: If destroy fails with "state locked":
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

3. **Cost**: Destroying stops all charges immediately.

---

**Ready to destroy? Run the commands above!**

