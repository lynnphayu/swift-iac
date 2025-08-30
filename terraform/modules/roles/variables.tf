# =============================================================================
# SHARED VARIABLES
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "ecr_repository_name" {
  description = "ECR repository name to allow push/pull"
  type        = string
}

# =============================================================================
# GITHUB ACTIONS ECR VARIABLES
# =============================================================================

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

variable "role_name" {
  description = "IAM role name for GitHub Actions to assume"
  type        = string
  default     = "github-actions-ecr"
}

# =============================================================================
# EKS ECR PULL VARIABLES
# =============================================================================

variable "eks_ecr_pull_role_name" {
  description = "IAM role name for EKS nodes to pull images from ECR"
  type        = string
  default     = "eks-ecr-pull-role"
}

# =============================================================================
# NON-EKS KUBERNETES ECR PULL VARIABLES
# =============================================================================

variable "k8s_ecr_pull_role_name" {
  description = "IAM role name for non-EKS Kubernetes cluster to pull images from ECR"
  type        = string
  default     = "k8s-ecr-pull-role"
}

variable "k8s_allow_ec2_assume" {
  description = "Allow EC2 instances to assume the K8s ECR pull role (for self-managed K8s on EC2)"
  type        = bool
  default     = true
}

variable "k8s_oidc_provider_arn" {
  description = "OIDC provider ARN for K8s service account integration (leave empty if not using OIDC)"
  type        = string
  default     = ""
}

variable "k8s_oidc_provider_url" {
  description = "OIDC provider URL for K8s service account integration (e.g., https://oidc.eks.region.amazonaws.com/id/XXXXX)"
  type        = string
  default     = ""
}

variable "k8s_oidc_audiences" {
  description = "List of audiences for OIDC provider"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "k8s_service_accounts" {
  description = "List of K8s service account subjects that can assume this role (format: system:serviceaccount:namespace:serviceaccount-name)"
  type        = list(string)
  default     = []
}

variable "k8s_trusted_arns" {
  description = "List of AWS ARNs (accounts/roles/users) that can assume this role"
  type        = list(string)
  default     = []
}

variable "k8s_allow_local_development" {
  description = "Allow any identity in the current AWS account to assume this role (useful for local development)"
  type        = bool
  default     = false
}
