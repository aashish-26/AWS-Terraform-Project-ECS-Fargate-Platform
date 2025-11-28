// variables.tf
// Input variables for the prod environment stack.

variable "project" {
  description = "Project tag value used across all modules."
  type        = string
  default     = "infra-project"
}

variable "environment" {
  description = "Environment name for this stack."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region where prod resources will be created."
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "AWS account ID used for globally-unique names."
  type        = string
}

variable "cidr_vpc" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones corresponding to public_subnets."
  type        = list(string)
}

variable "image" {
  description = "Full ECR image URI (including tag) for the ECS Fargate service."
  type        = string
}

variable "task_cpu" {
  description = "CPU units for Fargate task."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for Fargate task."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired ECS service task count."
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Port that the application container listens on."
  type        = number
  default     = 80
}

variable "db_instance_type" {
  description = "EC2 instance type for postgres-lite."
  type        = string
  default     = "t3.micro"
}

variable "db_ami_id" {
  description = "AMI ID for postgres-lite EC2 instance."
  type        = string
}

variable "db_name" {
  description = "Demo database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Demo database username."
  type        = string
  default     = "appuser"
}

variable "db_data_volume_size_gb" {
  description = "Size of EBS data volume for postgres-lite."
  type        = number
  default     = 20
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
  default     = "abhandari.2002@gmail.com"
}


