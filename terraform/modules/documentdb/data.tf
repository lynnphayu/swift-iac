# =============================================================================
# DATA SOURCES
# =============================================================================

# Get current AWS account info
data "aws_caller_identity" "current" {}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Since we're now getting VPC info directly from the EKS module,
# we don't need conditional data sources

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
