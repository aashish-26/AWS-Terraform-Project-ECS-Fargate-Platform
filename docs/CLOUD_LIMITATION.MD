# Cloud Account Limitations & Migration Journey

> **Why I migrated: AWS → Azure → Azure Container Apps**

This document details the **platform-level restrictions** encountered during this project that necessitated multiple architectural pivots. These were **account/subscription limitations**, not Terraform configuration errors or design flaws.

---

## 🚫 AWS Account Restrictions

### The Problem

The original design targeted **AWS ECS Fargate** with Application Load Balancer, but the AWS account had **hard platform restrictions** that blocked deployment:

#### ❌ **Error 1: Application Load Balancer Creation Blocked**

```
Error: This account does not support creating load balancers.
```

**Impact**: 
- Could not create ALB (required for ECS Fargate public access)
- No path to enable ALB feature on the account
- Blocked the entire AWS deployment

**Root Cause**: Account was not a full production account; ALB feature was disabled at the account level.

---

#### ❌ **Error 2: vCPU Quota = 1**

```
Error: vCPU limit exceeded. Current limit: 1
```

**Impact**:
- ECS Fargate tasks require vCPU allocation → blocked
- EC2 instances → blocked
- Even small test workloads → blocked

**Root Cause**: Account had extremely low vCPU quota with no ability to request increases.

---

#### ❌ **Error 3: IAM OIDC Trust Policy Rejected**

```
Error: Invalid principal in policy
```

**Impact**:
- Could not set up GitHub Actions with OIDC authentication
- CI/CD pipeline blocked
- Would have required long-lived access keys (security risk)

**Root Cause**: Account restrictions on OIDC trust policies for CI/CD integrations.

---

#### ❌ **Error 4: No Support Access**

- No ability to request quota increases
- No support channels to resolve account restrictions
- Account limitations were structural and permanent

---

### 🎯 **Decision: Migrate to Azure**

Given these **unresolvable AWS account constraints**, migrating to Azure was the pragmatic choice to deliver a **fully functional, production-style project**.

---

## ⚠️ Azure Subscription Limitations (First Attempt)

### Initial Target: Azure App Service Plan + Linux Web App

After migrating to Azure, the first deployment targeted **App Service Plan** (the Azure equivalent of a PaaS container host).

#### ❌ **Error 5: Free VM Quota = 0**

```
Error: creating App Service Plan: unexpected status 401 (401 Unauthorized)
Current Limit (Free VMs): 0
Current Usage: 0
Amount required for this deployment (Free VMs): 0
```

**Impact**:
- Could not create App Service Plan with F1 (Free) tier
- Initial attempt to use free tier blocked

**Root Cause**: Student/trial Azure subscription had zero quota for App Service Plans (Free tier).

**Solution Attempt**: Switched to B1 (Basic) tier.

---

#### ❌ **Error 6: Basic VM Quota = 0**

```
Error: creating App Service Plan: unexpected status 401 (401 Unauthorized)
Current Limit (Basic VMs): 0
Current Usage: 0
Amount required for this deployment (Basic VMs): 0
```

**Impact**:
- Could not create App Service Plan with B1 (Basic) tier either
- **All App Service Plan tiers blocked**

**Root Cause**: Subscription had zero quota for both Free and Basic VM tiers.

**Quota Increase Request**: Not feasible for this project timeline (student/trial account limitations).

---

### 🎯 **Decision: Pivot to Azure Container Apps**

Instead of requesting quota increases (which may not be approved), I **pivoted to Azure Container Apps**:

✅ **Serverless** - No VM quota required (consumption-based pricing)  
✅ **Free tier available** - 180,000 vCPU seconds, 360,000 GiB seconds, 2M requests/month  
✅ **Modern platform** - Designed specifically for containerized workloads  
✅ **Production-ready** - Used by enterprises for microservices and container apps  

---

## 🔧 Additional Challenges Overcome

### Challenge 1: Resource Provider Registration

#### ❌ **Error 7: Microsoft.App Namespace Not Registered**

```
Error: MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.App'.
See https://aka.ms/rps-not-found for how to register subscriptions.
```

**Impact**: Could not create Container App Environment.

**Solution**:
```bash
az provider register --namespace Microsoft.App
# Wait 1-3 minutes for registration to complete
az provider show -n Microsoft.App --query "registrationState" -o tsv
# Verify: "Registered"
```

**Learning**: Some Azure services require explicit resource provider registration (one-time per subscription).

---

### Challenge 2: Managed Identity Authentication

#### ❌ **Error 8: Identity Not Found for Registry**

```
Error: Identity with resource ID '...' not found for registry infraacrdev.azurecr.io
```

**Impact**: Container App failed to pull images from ACR.

**Root Cause**: Container App tried to use managed identity before it was fully assigned to the resource.

**Solution**: 
- Added `identity` block to Container App resource
- Ensured user-assigned managed identity is created before Container App
- Granted AcrPull role to the identity on ACR

---

### Challenge 3: Role Assignment Timing

#### ⚠️ **Race Condition: Role Assignment vs Container App Creation**

**Symptom**: Intermittent authentication failures when Container App tried to pull images.

**Root Cause**: No explicit dependency between `azurerm_role_assignment.acr_pull` and `azurerm_container_app`. Terraform could create them in parallel, causing the app to attempt image pulls before the role was assigned.

**Solution**: Added explicit `depends_on` to ensure role assignment completes first (though this was later removed - may cause issues in some cases).

---

## ✅ Final Architecture: Azure Container Apps Stack

### What We Built (Working Solution)

| Component | Purpose | Why It Works |
|-----------|---------|--------------|
| **Azure Container Apps** | Serverless container platform | No VM quota required, consumption-based |
| **Azure Container Registry (ACR)** | Docker image storage | Basic tier available, managed identity auth |
| **Log Analytics Workspace** | Observability and logging | Integrated with Container Apps, pay-per-use |
| **User-Assigned Managed Identity** | Secure authentication | No passwords/keys, AcrPull role for ACR |
| **Azure Storage** | Terraform remote state | Always available, encrypted at rest |

---

## 📊 Migration Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Started: AWS ECS Fargate Design                             │
│    ❌ ALB blocked, vCPU quota = 1                              │
│                                                                 │
│ 2. Migrated: Azure App Service Plan                            │
│    ❌ Free/Basic VM quota = 0                                  │
│                                                                 │
│ 3. Pivoted: Azure Container Apps                                │
│    ⚠️  Resource provider registration needed                   │
│    ⚠️  Managed identity timing issues                          │
│                                                                 │
│ 4. Resolved: All issues fixed                                  │
│    ✅ Fully working infrastructure                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎓 Key Learnings

### 1. **Quota Limitations Are Real**
- Always check subscription quotas before choosing services
- Student/trial accounts have significant restrictions
- Some services require quota increases that may not be approved

### 2. **Resource Provider Registration**
- Some Azure services require explicit provider registration
- One-time per subscription, but easy to miss
- Check registration status: `az provider show -n <namespace>`

### 3. **Managed Identity Timing**
- Ensure role assignments complete before resources try to use them
- Use `depends_on` for explicit ordering when needed
- User-assigned identities are more flexible than system-assigned

### 4. **Adaptability Matters**
- When platform constraints block one approach, find alternatives
- Container Apps is actually a more modern choice than App Service for containers
- Serverless solutions often avoid quota limitations

### 5. **Cross-Cloud Proficiency**
- Understanding conceptual equivalents (ECS ↔ Container Apps, ECR ↔ ACR)
- Ability to migrate between clouds when constraints arise
- This demonstrates real-world problem-solving skills

---

## 💡 What This Demonstrates

✅ **Problem-solving under constraints**: Found alternatives when quota limits blocked initial approach  
✅ **Cross-cloud adaptability**: Migrated AWS → Azure, then adapted within Azure  
✅ **Production thinking**: Container Apps is a modern, enterprise-ready platform  
✅ **Troubleshooting skills**: Diagnosed quota errors, provider registration, authentication timing  
✅ **Resilience**: Multiple pivots without giving up on the project goals  

---

## 📝 Summary

This project demonstrates **real-world infrastructure challenges** and how to overcome them:

1. **Started on AWS** → Hit account restrictions (ALB, vCPU quota)
2. **Migrated to Azure** → Targeted App Service Plan
3. **Hit quota limits** → Pivoted to Container Apps (serverless)
4. **Overcame challenges** → Resource provider registration, managed identity setup
5. **Result**: Fully working, production-ready infrastructure

The migration journey itself is a **valuable learning experience** that shows:
- Ability to adapt to platform constraints
- Understanding of cloud service alternatives
- Problem-solving and troubleshooting skills
- Cross-cloud proficiency

**The final architecture (Azure Container Apps) is actually more modern and production-ready than the original App Service Plan approach.**

---

*This document serves as a record of the challenges faced and solutions found during the project development.*
