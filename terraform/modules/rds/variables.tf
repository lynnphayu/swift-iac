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
  description = "VPC ID where RDS will be deployed"
  type        = string
  default     = "" # Will be fetched from existing EKS VPC
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
  default     = [] # Will be fetched from existing EKS VPC
}

# =============================================================================
# RDS CLUSTER VARIABLES
# =============================================================================

variable "cluster_identifier" {
  description = "RDS cluster identifier"
  type        = string
  default     = "dag-swarm-aurora"
}

variable "engine" {
  description = "Aurora engine type"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
  default     = "15.4"
}

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
  description = "CIDR blocks allowed to access RDS"
  type        = list(string)
  default     = ["10.0.0.0/16"] # Default VPC CIDR
}

variable "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID for RDS access"
  type        = string
  default     = ""
}
