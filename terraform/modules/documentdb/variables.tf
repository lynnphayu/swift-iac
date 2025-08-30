# =============================================================================
# GENERAL VARIABLES
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

# =============================================================================
# VPC VARIABLES
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where DocumentDB will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DocumentDB"
  type        = list(string)
}

# =============================================================================
# DOCUMENTDB CLUSTER VARIABLES
# =============================================================================

variable "cluster_identifier" {
  description = "DocumentDB cluster identifier"
  type        = string
  default     = "dag-swarm-docdb"
}

variable "engine" {
  description = "DocumentDB engine"
  type        = string
  default     = "docdb"
}

variable "engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "master_username" {
  description = "Master username for the DocumentDB cluster"
  type        = string
  default     = "docdbadmin"
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
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
# SECURITY VARIABLES
# =============================================================================

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access DocumentDB"
  type        = list(string)
  default     = ["10.0.0.0/16"] # Default VPC CIDR
}

variable "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID for DocumentDB access"
  type        = string
  default     = ""
}

# =============================================================================
# ADVANCED VARIABLES
# =============================================================================

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["audit", "profiler"]
}

variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "port" {
  description = "DocumentDB port"
  type        = number
  default     = 27017
}
