// main.tf
// Creates a "postgres-lite" EC2 instance for demo purposes:
// - A small EC2 instance (t3.micro by default) running Postgres.
// - A dedicated EBS volume for Postgres data.
// - A security group that allows inbound 5432 only from the app/ECS security group.
// - A Secrets Manager secret that stores DB connection details (username, password, host, db name).
// This is NOT production-grade (no HA, manual backups only) and is intended purely for demos.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}-postgres"
}

// Look up subnet details so we can place the EBS volume in the correct AZ.
data "aws_subnet" "this" {
  id = var.subnet_id
}

// Security group for Postgres, allowing connections only from the app/ECS SG.
resource "aws_security_group" "postgres" {
  name        = "${local.name_prefix}-sg"
  description = "Postgres SG: allow 5432 from app/ECS security group only."
  vpc_id      = var.vpc_id

  // Allow inbound 5432 only from the app_security_group_id (ECS tasks).
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
    description     = "Postgres from app/ECS only"
  }

  // Allow all outbound so the instance can reach the internet for patches
  // and talk to AWS APIs (for example, SSM, Secrets Manager).
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-sg"
    project = var.project
    env     = var.environment
  }
}

// Random password for the database user. This avoids hard-coding secrets in code.
// Note: special characters are disabled to keep SQL string interpolation simple
// in the demo user-data script and avoid quoting/escaping issues.
resource "random_password" "db" {
  length  = 16
  special = false
}

// EBS volume that will hold the Postgres data directory.
resource "aws_ebs_volume" "postgres_data" {
  availability_zone = data.aws_subnet.this.availability_zone
  size              = var.data_volume_size_gb
  type              = "gp3"

  tags = {
    Name    = "${local.name_prefix}-data"
    project = var.project
    env     = var.environment
  }
}

// EC2 instance running Postgres for demo purposes.
resource "aws_instance" "postgres" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.postgres.id]

  // User data script configures Postgres on first boot (see userdata/postgres-setup.sh).
  user_data = templatefile("${path.module}/userdata/postgres-setup.sh", {
    db_name     = var.db_name
    db_username = var.db_username
    db_password = random_password.db.result
  })

  tags = {
    Name    = "${local.name_prefix}-ec2"
    project = var.project
    env     = var.environment
  }
}

// Attach the data volume to the Postgres instance.
resource "aws_volume_attachment" "postgres_data" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.postgres_data.id
  instance_id = aws_instance.postgres.id
}

// Secrets Manager secret containing DB connection details.
resource "aws_secretsmanager_secret" "db" {
  name = "${local.name_prefix}-credentials"

  tags = {
    project = var.project
    env     = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
    host     = aws_instance.postgres.private_ip
    port     = 5432
  })
}


