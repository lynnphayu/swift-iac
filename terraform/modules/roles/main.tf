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

provider "aws" {
  region = var.region
}

# Shared data sources
data "aws_caller_identity" "current" {}

# Shared locals used across multiple files
locals {
  ecr_repo_arn = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}"
}
