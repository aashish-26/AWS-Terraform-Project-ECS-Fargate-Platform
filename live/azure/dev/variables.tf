// variables.tf
// Input variables for Azure dev environment.

variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "infra-project"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

