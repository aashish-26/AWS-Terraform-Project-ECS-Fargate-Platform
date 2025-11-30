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

variable "container_image" {
  description = "Full container image name to run (for example, nginx:latest or myregistry.azurecr.io/app:tag)."
  type        = string
  default     = "nginx:latest"
}

variable "container_registry_url" {
  description = "Docker registry URL (for example, https://index.docker.io or https://myregistry.azurecr.io)."
  type        = string
  default     = "https://index.docker.io"
}

variable "acr_id" {
  description = "Azure Container Registry resource ID (for granting AcrPull role to the managed identity)."
  type        = string
  default     = null
}


