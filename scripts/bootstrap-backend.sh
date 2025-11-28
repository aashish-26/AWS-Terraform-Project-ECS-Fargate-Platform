#!/usr/bin/env bash
# bootstrap-backend.sh
# One-time bootstrap script to create the Terraform remote state backend
# (S3 bucket, DynamoDB lock table, and KMS key) for a given environment.
#
# Why this script exists:
# - Backend resources must exist before any other Terraform stacks can run.
# - It is easier and safer to create them once via script than to manage them
#   manually in the console.
# - The script is designed to be idempotent: re-running it should not cause
#   errors or create duplicate resources.
#
# Usage (example):
#   ./scripts/bootstrap-backend.sh --env dev --region ap-south-1 --account-id 471112729537
#
# IAM / principal requirements:
# - The principal running this script must have permissions to:
#   - Create / describe S3 buckets.
#   - Create / describe DynamoDB tables.
#   - Create / describe KMS keys and aliases.
# - In many teams this is an admin or "bootstrap" role used only for initial setup.

set -euo pipefail

ENVIRONMENT=""
REGION=""
ACCOUNT_ID=""

usage() {
  cat <<EOF
Usage: $0 --env <env> --region <aws-region> --account-id <aws-account-id>

Examples:
  $0 --env dev --region us-east-1 --account-id 123456789012

This script will:
  - Create (or reuse) a KMS key and alias for Terraform state encryption.
  - Create (or reuse) an S3 bucket for Terraform state (versioned, SSE-KMS, public access blocked).
  - Create (or reuse) a DynamoDB table for Terraform state locking.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --account-id)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${ENVIRONMENT}" || -z "${REGION}" || -z "${ACCOUNT_ID}" ]]; then
  echo "ERROR: --env, --region, and --account-id are required."
  usage
  exit 1
fi

echo "[bootstrap-backend] Environment: ${ENVIRONMENT}"
echo "[bootstrap-backend] Region: ${REGION}"
echo "[bootstrap-backend] Account ID: ${ACCOUNT_ID}"

AWS_CLI_PROFILE="${AWS_PROFILE:-default}"

# Derived names (must match your Terraform bootstrap module / backend config)
KMS_ALIAS_NAME="alias/terraform-state-${ENVIRONMENT}"
STATE_BUCKET_NAME="terraform-state-${ENVIRONMENT}-${ACCOUNT_ID}"
LOCK_TABLE_NAME="terraform-locks-infra-project-${ENVIRONMENT}"

echo "[bootstrap-backend] Using KMS alias: ${KMS_ALIAS_NAME}"
echo "[bootstrap-backend] Using state bucket: ${STATE_BUCKET_NAME}"
echo "[bootstrap-backend] Using lock table: ${LOCK_TABLE_NAME}"

########################################
# KMS key and alias
########################################

echo "[bootstrap-backend] Checking for existing KMS key with alias ${KMS_ALIAS_NAME}"
set +e
KMS_KEY_ID=$(aws kms describe-key \
  --profile "${AWS_CLI_PROFILE}" \
  --region "${REGION}" \
  --key-id "${KMS_ALIAS_NAME}" \
  --query 'KeyMetadata.KeyId' \
  --output text 2>/dev/null)
KMS_DESCRIBE_EXIT=$?
set -e

if [[ ${KMS_DESCRIBE_EXIT} -ne 0 || "${KMS_KEY_ID}" == "None" ]]; then
  echo "[bootstrap-backend] KMS alias not found; creating new KMS key"
  KMS_KEY_ID=$(aws kms create-key \
    --profile "${AWS_CLI_PROFILE}" \
    --region "${REGION}" \
    --description "Terraform state KMS key for ${ENVIRONMENT}" \
    --query 'KeyMetadata.KeyId' \
    --output text)

  echo "[bootstrap-backend] Creating KMS alias ${KMS_ALIAS_NAME} for key ${KMS_KEY_ID}"
  aws kms create-alias \
    --profile "${AWS_CLI_PROFILE}" \
    --region "${REGION}" \
    --alias-name "${KMS_ALIAS_NAME}" \
    --target-key-id "${KMS_KEY_ID}"
else
  echo "[bootstrap-backend] Reusing existing KMS key with alias ${KMS_ALIAS_NAME} (KeyId: ${KMS_KEY_ID})"
fi

########################################
# S3 state bucket
########################################

echo "[bootstrap-backend] Checking for existing S3 bucket ${STATE_BUCKET_NAME}"
set +e
aws s3api head-bucket \
  --profile "${AWS_CLI_PROFILE}" \
  --bucket "${STATE_BUCKET_NAME}" >/dev/null 2>&1
BUCKET_EXISTS_EXIT=$?
set -e

if [[ ${BUCKET_EXISTS_EXIT} -ne 0 ]]; then
  echo "[bootstrap-backend] Creating S3 bucket ${STATE_BUCKET_NAME}"
  if [[ "${REGION}" == "us-east-1" ]]; then
    # In us-east-1, the LocationConstraint parameter must be omitted.
    aws s3api create-bucket \
      --profile "${AWS_CLI_PROFILE}" \
      --bucket "${STATE_BUCKET_NAME}"
  else
    aws s3api create-bucket \
      --profile "${AWS_CLI_PROFILE}" \
      --bucket "${STATE_BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
else
  echo "[bootstrap-backend] Reusing existing S3 bucket ${STATE_BUCKET_NAME}"
fi

echo "[bootstrap-backend] Enabling versioning on bucket ${STATE_BUCKET_NAME}"
aws s3api put-bucket-versioning \
  --profile "${AWS_CLI_PROFILE}" \
  --bucket "${STATE_BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "[bootstrap-backend] Enabling default SSE-KMS using key ${KMS_KEY_ID}"
aws s3api put-bucket-encryption \
  --profile "${AWS_CLI_PROFILE}" \
  --bucket "${STATE_BUCKET_NAME}" \
  --server-side-encryption-configuration "{
    \"Rules\": [
      {
        \"ApplyServerSideEncryptionByDefault\": {
          \"SSEAlgorithm\": \"aws:kms\",
          \"KMSMasterKeyID\": \"${KMS_KEY_ID}\"
        }
      }
    ]
  }"

echo "[bootstrap-backend] Blocking public access to bucket ${STATE_BUCKET_NAME}"
aws s3api put-public-access-block \
  --profile "${AWS_CLI_PROFILE}" \
  --bucket "${STATE_BUCKET_NAME}" \
  --public-access-block-configuration "{
    \"BlockPublicAcls\": true,
    \"IgnorePublicAcls\": true,
    \"BlockPublicPolicy\": true,
    \"RestrictPublicBuckets\": true
  }"

########################################
# DynamoDB lock table
########################################

echo "[bootstrap-backend] Checking for existing DynamoDB table ${LOCK_TABLE_NAME}"
set +e
aws dynamodb describe-table \
  --profile "${AWS_CLI_PROFILE}" \
  --region "${REGION}" \
  --table-name "${LOCK_TABLE_NAME}" >/dev/null 2>&1
TABLE_EXISTS_EXIT=$?
set -e

if [[ ${TABLE_EXISTS_EXIT} -ne 0 ]]; then
  echo "[bootstrap-backend] Creating DynamoDB lock table ${LOCK_TABLE_NAME}"
  aws dynamodb create-table \
    --profile "${AWS_CLI_PROFILE}" \
    --region "${REGION}" \
    --table-name "${LOCK_TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --sse-specification Enabled=true,KMSMasterKeyId="${KMS_KEY_ID}"
else
  echo "[bootstrap-backend] Reusing existing DynamoDB table ${LOCK_TABLE_NAME}"
fi

########################################
# Output summary as JSON
########################################

cat <<EOF
{
  "environment": "${ENVIRONMENT}",
  "region": "${REGION}",
  "state_bucket": "${STATE_BUCKET_NAME}",
  "lock_table": "${LOCK_TABLE_NAME}",
  "kms_key_id": "${KMS_KEY_ID}",
  "kms_alias": "${KMS_ALIAS_NAME}"
}
EOF


