# Shared Terraform and AWS configuration
# This file contains shared resources used across multiple role configurations

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Shared data sources
data "aws_caller_identity" "current" {}

# Shared locals used across multiple files
locals {
  # Use ECR output if provided, otherwise construct from repository name (for backward compatibility)
  ecr_repo_arn = var.ecr_repository_arn
}
