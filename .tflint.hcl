# .tflint.hcl
# Minimal TFLint config with AWS plugin enabled.

plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}