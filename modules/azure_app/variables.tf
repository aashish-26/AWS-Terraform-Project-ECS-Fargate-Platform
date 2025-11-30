variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created."
  type        = string
}

variable "app_service_sku_tier" {
  description = "App Service plan tier (e.g., Free, Basic, Standard, PremiumV2)."
  type        = string
  default     = "Free"
}

variable "app_service_sku_size" {
  description = "App Service plan size (e.g., F1, B1, S1)."
  type        = string
  default     = "F1"
}


