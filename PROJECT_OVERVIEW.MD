## What is this project?

This project is a **full Terraform-driven, production-style infrastructure implementation on Azure**, with an AWS design kept as a reference.  
It demonstrates the **architecture, security, automation, DevOps, and SRE fundamentals** expected in modern enterprise environments.

### Core characteristics

- **Azure-first, container-based app platform**
  - App runs in a Docker container on **Azure Container Apps** (serverless, no VM quota required).
  - Images are built from this repo, scanned with Trivy, and pushed to **Azure Container Registry (ACR)** via GitHub Actions.
  - Uses managed identity for secure ACR authentication (no passwords or keys).
- **Environment layout**
  - `live/azure/dev` (primary runnable environment).
  - Reference AWS layout (`live/aws/dev`, `live/aws/prod`) preserved for design comparison, but not required to run.
- **Remote state and backends**
  - Terraform state stored in **Azure Storage** with encryption at rest.
  - Backends defined per-environment (`backend "azurerm"`).
- **Identity and access**
  - **Azure Service Principal** for CI/CD, scoped to resource groups (least privilege).
  - No personal credentials used by automation.
- **Modular design**
  - `modules/azure_app` + other modules follow **single-responsibility** patterns.
  - Easy to extend with VNets, managed PostgreSQL, Key Vault, Azure Monitor, etc.
- **CI-ready structure**
  - GitHub Actions for:
    - Terraform plan + validation + security scanning.
    - Terraform apply (protected, manual trigger).
    - Container image build, scan (Trivy), SBOM generation, push to ACR.
- **Scanning and policy enforcement**
  - `tflint` (linting), `tfsec` (security), `conftest` (policy-as-code over plan JSON).

The result is a **portfolio-level infrastructure project** that reflects real production patterns, not a toy example.

---

## Q1: Why did you build this?

**Recruiter-style question**  
“What were you trying to prove with this project?”

**Answer**

I wanted a **single, demonstrable, end-to-end infrastructure environment** that looks like how real companies deploy and operate cloud systems.  
The goal was not to ship a tiny demo, but to mirror real patterns:

- **Modular IaC**
  - Clear separation between `modules/` and `live/` environments.
- **Remote state with locking**
  - Backends set up so multiple engineers/CI can safely collaborate.
- **Guardrails before `apply`**
  - Formatting, validation, security scanning, and policy checks run before changes are applied.
- **Automation-friendly design**
  - GitHub Actions workflows that reflect real CI/CD flows (plan on PRs, protected apply).
- **Cloud-native managed services**
  - Use of App Service, ACR, and Azure backends instead of hand-managed servers.
- **Secure access patterns**
  - Service principals, scoped permissions, no hardcoded secrets.
- **Environment separation**
  - Dev environment isolated by naming and tagging, easy to extend to staging/prod.
- **Idempotent, declarative deployment**
  - Everything defined in Terraform; re-applying is safe and predictable.

This project is my concrete answer to:  
**“Can this person design and ship infrastructure the way companies expect?”**  
The repo shows that ability directly.

---

## Q2: Why did you use AI instead of writing everything by hand?

**Recruiter-style question**  
“Why rely on AI instead of writing every line manually?”

**Answer**

I used AI as an **accelerator**, not as a substitute for understanding.

- **Industry reality**
  - Modern DevOps/SRE teams already use tools like GitHub Copilot, Cursor, and other AI assistants.
  - Being able to drive AI effectively is a **skill**, not a shortcut.
- **Speed with accuracy**
  - AI handled repetitive boilerplate (resource stanzas, variable blocks, documentation scaffolding).
  - I focused my time on architecture, boundaries between modules, security, and correctness.
- **Pattern enforcement**
  - AI helped keep naming, structure, and formatting consistent across many files.
- **Human validation**
  - Every resource, variable, backend, and policy was **manually read, adjusted, and validated** by me.
  - Design decisions (what to build, how to model it, which tradeoffs to accept) are mine.
- **Enterprise direction**
  - Companies expect engineers to be **AI-augmented**, not AI-replaced.
  - This project demonstrates I know how to use AI as a force multiplier while owning the result.

**Bottom line:**  
Using AI was deliberate. **Understanding, review, and final decisions are human.**

---

## Q3: What did you do to keep things secure?

**Recruiter-style question**  
“What security steps did you take in this project?”

**Answer**

### State and credentials

- **Terraform state**
  - Stored in **Azure Storage** with encryption at rest.
- **Identity**
  - Access from CI is via an **Azure Service Principal**, not long-lived personal keys.
  - Permissions scoped primarily to the **resource group**, not full subscription.
- **Secrets**
  - No hardcoded secrets in `.tf` or `.tfvars` checked into Git.
  - Secrets live in GitHub Secrets and (conceptually) Azure Key Vault (documented as the target pattern).

### Terraform security scanning

- **`tflint`** – provider-specific linting, catching common mistakes.
- **`tfsec`** – static analysis for insecure patterns (open networks, missing encryption, etc.).
- **`conftest` + Rego policies** – policy-as-code on the Terraform plan JSON to enforce:
  - Mandatory tags.
  - No wide-open network rules.
  - Only approved storage and encryption configs.

### Least privilege and network design

- **Service Principal scope**
  - Designed to be scoped to **just the resource group(s)** this project needs.
- **Network segmentation (design)**
  - Architecture is written to extend naturally with VNets and subnets as a next step.
- **Containers**
  - App image is pulled from **ACR**, with admin access disabled and authentication controlled by Azure.

### Future-ready security posture

The repo is structured to plug into more advanced controls without refactoring:

- SAST tools for app code (if/when added).
- Additional IaC policy gates.
- OPA/Conftest policies expanded for Azure-specific rules.
- GitHub Actions environment protections and approvals.

Security is treated as a **through-line**: from design → modules → deployment → scanning → runtime.

---

## Q4: Why did you migrate away from AWS to Azure, and why Container Apps instead of App Service?

**Recruiter-style question**  
"You started on AWS. Why did you switch to Azure, and why Container Apps specifically?"

**Answer**

### Part 1: AWS → Azure Migration

The original work started on AWS (ECS Fargate, ALB, S3/DynamoDB backends).  
However, the **AWS account itself** had several **hard platform restrictions**:

- **ALB creation blocked**
  - Error: *"This account does not support creating load balancers."*
- **vCPU limit set to 1**
  - ECS Fargate, EC2, and even small test workloads were blocked by quota.
- **IAM trust policy limitations**
  - CI roles with OIDC trust policies were rejected (*Invalid principal in policy*).
- **No path to fix the account**
  - It was not a full production account, so I couldn't request quota increases or ALB enablement.

These were **not Terraform or design bugs**; they were **account-level constraints**.

Given those blockers—and the goal of delivering a **fully functional, production-style project**—migrating the implementation to **Azure** was the pragmatic choice:

- Full ability to create required resources.
- Clean service principal model for CI.
- Cost-efficient, short-lived deployments.

### Part 2: App Service Plan → Container Apps Migration

After migrating to Azure, I initially targeted **App Service Plan + Linux Web App** (the Azure equivalent of a PaaS container host). However, I hit another quota wall:

- **App Service Plan quota error**: *"Current Limit (Free VMs): 0"* and *"Current Limit (Basic VMs): 0"*
- The subscription (student/trial account) had zero quota for App Service Plans
- Requesting quota increases wasn't feasible for this project timeline

**Solution: Azure Container Apps**

I pivoted to **Azure Container Apps**, which:
- Is **serverless** and doesn't require VM quotas (consumption-based pricing)
- Has a generous free tier (180,000 vCPU seconds, 360,000 GiB seconds, 2M requests/month)
- Is a modern, production-ready platform designed for containers
- Includes built-in observability (Log Analytics workspace integration)
- Uses managed identity for ACR authentication (no passwords)

**Additional challenges overcome:**
1. **Resource provider registration**: Had to register `Microsoft.App` namespace (`az provider register --namespace Microsoft.App`)
2. **Managed identity timing**: Added explicit `depends_on` to ensure AcrPull role assignment completes before container app attempts image pulls
3. **Registry URL format**: Fixed protocol handling (ACR server names don't include `https://`)

**What this demonstrates:**
- **Problem-solving under constraints**: When quota limits blocked the initial approach, I found an alternative that met the same goals
- **Cross-cloud adaptability**: Migrated from AWS → Azure, then adapted within Azure when quota issues arose
- **Production thinking**: Container Apps is actually a more modern choice than App Service for containerized workloads
- **Troubleshooting skills**: Diagnosed quota errors, resource provider issues, and authentication timing problems

The AWS design remains in the repo as a **reference architecture**, but the working, demonstrable platform is **Azure-first with Container Apps**.  
This migration journey shows **adaptability, cross-cloud proficiency, and resilience in the face of platform constraints**—qualities that matter more than being tied to one provider or approach.

---

## Q5: What does this project demonstrate to a recruiter or hiring manager?

**Answer**

### Design ability

- You can see a **complete infrastructure design**, not just a few isolated resources.
- The layout (`modules/`, `live/`, `docs/`) mirrors how real SRE/Platform teams structure IaC.

### IaC discipline

- Use of **modules**, **remote state**, **environments**, and **policy checks**.
- Clean separation between reusable components and environment-specific wiring.

### Multi-cloud awareness

- Started with an AWS ECS Fargate platform design.
- Executed a **real AWS → Azure migration** driven by real-world constraints.
- Shows understanding of **conceptual equivalents** (ECS ↔ App Service/ACR, S3 ↔ Azure Storage, etc.).

### Security-first mindset

- Encryption at rest, identity separation, scanning, and policy enforcement are built-in.
- Documentation (`docs/security.md`) explains the model clearly in both AWS terms and Azure terms.

### CI/CD awareness

- GitHub Actions pipelines mirror **real workflows**:
  - Plan on PRs with full validation and security checks.
  - Manual, protected applies.
  - Image build, scan, SBOM generation, and push.

### Failure handling and troubleshooting

- The project history includes:
  - **AWS account restrictions**: ALB creation blocked, vCPU quota of 1, IAM trust policy rejections
  - **Azure quota limitations**: App Service Plan quota of 0 (Free and Basic VMs)
  - **Resource provider registration**: Missing `Microsoft.App` namespace registration
  - **Managed identity timing**: Race conditions between role assignment and container app image pulls
  - **Provider version changes**: Deprecated `azurerm_app_service_plan` → `azurerm_service_plan`
  - **Registry URL format**: Protocol prefix handling for ACR server names
- It shows the ability to **diagnose root causes**, adapt architecture, and adjust design—not just fix syntax errors.

### AI-augmented engineering

- AI was used as a **productivity layer**:
  - Speeding up boilerplate creation.
  - Keeping structure consistent.
- But architectural decisions, security rules, and final shape of the code were **human-owned**.

### Production thinking

- Logging, monitoring, lifecycle, and teardown are part of the design.
- The docs (`README.md`, `docs/`, `PROJECT_OVERVIEW.MD`) read like something you’d hand to another engineer joining the team.

---

## One-sentence summary you can say in an interview

> **"I built a full Terraform-based production-style infrastructure on Azure using modular IaC, remote state, policy enforcement, containers on Azure Container Apps, and secure cloud architecture. I started on AWS but migrated to Azure due to hard account restrictions (ALB blocked, vCPU quota of 1). Within Azure, I hit App Service Plan quota limits, so I pivoted to Container Apps—a serverless solution that doesn't require VM quotas. This forced me to handle a real cross-cloud migration and adapt within Azure when constraints arose. I used AI as an accelerator but made and validated all key design, security, and CI/CD decisions myself. The project reflects how real companies design, secure, and automate cloud infrastructure end-to-end, including troubleshooting platform constraints and finding alternative solutions."**
