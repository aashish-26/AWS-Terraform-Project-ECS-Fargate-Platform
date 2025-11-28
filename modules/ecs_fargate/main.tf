// main.tf
// Creates an ECS Fargate cluster, task definition, and service for the application.
// The service is integrated with the ALB target group and sends container logs
// to CloudWatch Logs. This module assumes the image is already pushed to ECR.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  cluster_name   = "${var.project}-${var.environment}-ecs-cluster"
  service_name   = "${var.project}-${var.environment}-service"
  container_name = "${var.project}-${var.environment}-app"
  log_group_name = "/aws/ecs/${var.project}/${var.environment}/app"
}

// CloudWatch log group where container logs will be sent.
resource "aws_cloudwatch_log_group" "app" {
  name              = local.log_group_name
  retention_in_days = var.log_group_retention_in_days

  tags = {
    project = var.project
    env     = var.environment
  }
}

// ECS cluster to host the Fargate service.
resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  tags = {
    project = var.project
    env     = var.environment
  }
}

// Task definition describing how to run the application container on Fargate.
// Uses a template file for the containerDefinitions JSON.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.environment}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = var.task_execution_role_arn
  // A dedicated task role (for app-level AWS access) can be added later if needed.

  container_definitions = templatefile("${path.module}/task_definition.tpl.json", {
    container_name   = local.container_name
    image            = var.image
    container_port   = var.container_port
    log_group_name   = local.log_group_name
    log_group_region = var.region
  })
}

// ECS service running the Fargate tasks and wired to the ALB target group.
resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "FARGATE"
  desired_count   = var.desired_count
  task_definition = aws_ecs_task_definition.app.arn

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = {
    project = var.project
    env     = var.environment
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}


