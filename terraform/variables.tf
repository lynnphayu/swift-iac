# =============================================================================
# SHARED GLOBAL VARIABLES
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dag-swarm"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "dag-swarm"
}

# =============================================================================
# ECR AND GITHUB VARIABLES
# =============================================================================

variable "ecr_repository_name" {
  description = "ECR repository name to allow push/pull"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_ref" {
  description = "Git ref to trust (e.g., 'refs/heads/main' or 'refs/tags/*' or 'pull_request')"
  type        = string
  default     = "refs/heads/main"
}

# =============================================================================
# IAM ROLE NAMES
# =============================================================================

variable "github_actions_role_name" {
  description = "IAM role name for GitHub Actions to assume"
  type        = string
  default     = "github-actions-ecr"
}

variable "eks_ecr_pull_role_name" {
  description = "IAM role name for EKS nodes to pull images from ECR"
  type        = string
  default     = "eks-ecr-pull-role"
}

variable "k8s_ecr_pull_role_name" {
  description = "IAM role name for non-EKS Kubernetes cluster to pull images from ECR"
  type        = string
  default     = "k8s-ecr-pull-role"
}

# =============================================================================
# RDS DATABASE VARIABLES
# =============================================================================

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "swiftbackend_core"
}

variable "master_username" {
  description = "Master username for the RDS cluster"
  type        = string
  default     = "postgres"
}

variable "instance_class" {
  description = "Instance class for RDS instances"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the RDS cluster"
  type        = number
  default     = 1
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# =============================================================================
# DOCUMENTDB VARIABLES
# =============================================================================

variable "documentdb_cluster_identifier" {
  description = "DocumentDB cluster identifier"
  type        = string
  default     = "dag-swarm-docdb"
}

variable "documentdb_master_username" {
  description = "Master username for the DocumentDB cluster"
  type        = string
  default     = "docdbadmin"
}

variable "documentdb_instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "documentdb_instance_count" {
  description = "Number of instances in the DocumentDB cluster"
  type        = number
  default     = 1
}

# =============================================================================
# OPTIONAL LOCAL DEVELOPMENT VARIABLES
# =============================================================================

variable "k8s_allow_local_development" {
  description = "Allow any identity in the current AWS account to assume this role (useful for local development)"
  type        = bool
  default     = false
}

variable "k8s_allow_ec2_assume" {
  description = "Allow EC2 instances to assume the K8s ECR pull role (for self-managed K8s on EC2)"
  type        = bool
  default     = false
}
