# =============================================================================
# CORE ECR CONFIGURATION
# =============================================================================

variable "repository_name" {
  description = "Name of the main ECR repository"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "dag-swarm"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# =============================================================================
# ECR REPOSITORY CONFIGURATION
# =============================================================================

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Force deletion of repository even if it contains images"
  type        = bool
  default     = false
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning on image push"
  type        = bool
  default     = true
}

# =============================================================================
# ENCRYPTION CONFIGURATION
# =============================================================================

variable "encryption_type" {
  description = "Encryption type for ECR repository (AES256 or KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for ECR encryption (only used if encryption_type is KMS)"
  type        = string
  default     = null
}

# =============================================================================
# LIFECYCLE POLICY CONFIGURATION
# =============================================================================

variable "enable_lifecycle_policy" {
  description = "Enable lifecycle policy for automatic image cleanup"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep for tagged images"
  type        = number
  default     = 10
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images are deleted"
  type        = number
  default     = 1
}

variable "lifecycle_tag_prefixes" {
  description = "List of tag prefixes to apply lifecycle policy to"
  type        = list(string)
  default     = ["v", "release", "main", "develop"]
}

# =============================================================================
# TAGS
# =============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
