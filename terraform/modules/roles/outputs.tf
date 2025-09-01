# =============================================================================
# GITHUB ACTIONS ECR OUTPUTS
# =============================================================================

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions_ecr.arn
}

output "github_actions_role_name" {
  description = "IAM role name for GitHub Actions"
  value       = aws_iam_role.github_actions_ecr.name
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}

# =============================================================================
# EKS ECR PULL OUTPUTS
# =============================================================================

output "eks_ecr_pull_role_arn" {
  description = "IAM role ARN for EKS nodes to pull images from ECR"
  value       = aws_iam_role.eks_ecr_pull_role.arn
}

output "eks_ecr_pull_role_name" {
  description = "IAM role name for EKS nodes to pull images from ECR"
  value       = aws_iam_role.eks_ecr_pull_role.name
}

# =============================================================================
# NON-EKS KUBERNETES ECR PULL OUTPUTS
# =============================================================================

output "k8s_ecr_pull_role_arn" {
  description = "IAM role ARN for non-EKS Kubernetes cluster to pull images from ECR"
  value       = aws_iam_role.k8s_ecr_pull_role.arn
}

output "k8s_ecr_pull_role_name" {
  description = "IAM role name for non-EKS Kubernetes cluster to pull images from ECR"
  value       = aws_iam_role.k8s_ecr_pull_role.name
}

# =============================================================================
# BACKWARD COMPATIBILITY OUTPUTS (deprecated but kept for compatibility)
# =============================================================================

output "role_arn" {
  description = "[DEPRECATED] Use github_actions_role_arn instead"
  value       = aws_iam_role.github_actions_ecr.arn
}

output "oidc_provider_arn" {
  description = "[DEPRECATED] Use github_oidc_provider_arn instead"
  value       = aws_iam_openid_connect_provider.github.arn
}

# =============================================================================
# EXTERNAL SECRETS OPERATOR OUTPUTS
# =============================================================================

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "external_secrets_role_name" {
  description = "IAM role name for External Secrets Operator"
  value       = aws_iam_role.external_secrets.name
}
