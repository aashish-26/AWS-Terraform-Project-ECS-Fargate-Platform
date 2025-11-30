# Security Controls

## Data Classification
- Service handles general application data and non-regulated user metadata.
- No PII/PCI unless extended. Treat DB credentials and secrets as confidential.

## Secrets Management
**AWS (reference)**
- All secrets stored in AWS Secrets Manager.
- Encryption enforced using KMS CMK: alias/service-key-<env>.
- No plaintext secrets in Terraform code or tfvars.
- ECS tasks retrieve secrets using task execution role with GetSecretValue only.

**Azure (primary) – target model**
- Secrets stored in Azure Key Vault (connection strings, API keys, DB credentials).
- Encryption-at-rest via Microsoft-managed or customer-managed keys.
- Container App accesses secrets via user-assigned managed identity and Key Vault access policies / RBAC.
- ACR authentication uses managed identity (AcrPull role) - no passwords or admin keys.

## Encryption Standards
**AWS**
- S3 state bucket: SSE-KMS (CMK alias/terraform-state-key-<env>).
- DynamoDB table: server-side encryption enabled.
- EBS volume for Postgres EC2 instance encrypted with KMS.
- TLS termination at ALB when HTTPS is configured (optional).

**Azure**
- Terraform state: encrypted at rest in Azure Storage.
- Container App images: stored in ACR with encryption at rest (platform-managed keys).
- Container App environment: Log Analytics workspace data encrypted at rest.
- (Planned) Azure Database for PostgreSQL: storage encryption and TLS enforced for client connections.

## Identity / Access Model (Least Privilege)
**AWS**
| Principal | Purpose | Allowed Actions | Resource Scope |
|----------|----------|----------------|----------------|
| Deploy Role | Terraform apply from CI | CRUD on project resources, tag-restricted | Only resources tagged project=<project>, env=<env> |
| CI Role | Run plan/apply | sts:AssumeRole → DeployRole, state read/write | S3 state bucket, DynamoDB lock |
| Exec Role (Task) | Run container | ecr:GetAuthToken, ecr:BatchGetImage, secretsmanager:GetSecretValue, logs:CreateLogStream/PutLogEvents | Only required ARNs |
| Developer ReadOnly Role | Inspect infra | Describe*/List* only | Entire account |
| Admin Role | Rare operations, break-glass | Full action set | Restricted to two MFA-enforced principals |

**Azure (conceptual equivalent)**
- GitHub OIDC → Azure AD service principal with rights only to the target RG and backend RG.
- Container App uses user-assigned managed identity for:
  - ACR image pulls (AcrPull role on ACR)
  - Key Vault secret access (planned, Get/List secrets permission)
  - Other PaaS service authentication
- Role assignments scoped to resource groups, not subscription-wide, wherever possible.

## Network Controls
**AWS**
- ALB public. ECS tasks allowed inbound only from ALB target group.
- Postgres EC2 allows inbound only from ECS task ENIs on port 5432.
- No `0.0.0.0/0` inbound to DB or ECS tasks.
- S3 public access block enforced.

**Azure (current + planned)**
- Container App is internet-facing (external ingress enabled) but can be configured for internal-only access via Container App Environment settings.
- Container App Environment can be configured with internal load balancer for private networking.
- (Planned) Azure Database for PostgreSQL reachable only from Container App outbound IPs or VNet integration.
- Storage account for state configured without public anonymous access.
- ACR admin access disabled; all authentication via managed identity.

## Policy-as-Code Requirements
Reject merges if any rule fails:
- IAM policies containing `"Action": "*"` or `"Resource": "*"` (except admin role).
- Any security group allowing `0.0.0.0/0` to 5432.
- Any S3 bucket without SSE-KMS.
- Any resource missing mandatory tags: project, env, owner.

> The same policies can be extended to Azure by evaluating the Terraform plan JSON with Conftest (for example: no public storage accounts, mandatory tags, restricted firewall rules).

## Logging and Audit
**AWS**
- CloudTrail enabled and storing API logs.
- CloudWatch Logs receive app logs, container logs, and DB logs.
- IAM changes tracked through CloudTrail and IAM Access Analyzer.

**Azure**
- Activity Logs capture control-plane operations.
- Container App logs automatically sent to Log Analytics workspace (integrated with Container App Environment).
- Container App metrics (CPU, memory, request count, latency) available in Azure Monitor.
- (Planned) Application Insights for request-level traces and distributed tracing.

## Access Control
- MFA required for human principals (AWS IAM / Azure AD).
- CI uses OIDC or specific IAM/service principal with limited session duration.
- Session-based or bastion access for servers; no long-lived SSH keys for demo.

## Rotation and Key Management
- CMK rotation: annual (AWS KMS or Azure Key Vault keys).
- DB password rotation: Secrets Manager / Key Vault rotation allowed.
- IAM access keys prohibited except break-glass accounts.

