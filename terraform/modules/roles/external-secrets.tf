# =============================================================================
# EXTERNAL SECRETS OPERATOR IAM ROLE
# =============================================================================

# IAM role for External Secrets Operator to access AWS Secrets Manager
resource "aws_iam_role" "external_secrets" {
  count = var.eks_oidc_issuer_id != null ? 1 : 0
  name  = "external-secrets-operator"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${var.eks_oidc_issuer_id}"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.${var.region}.amazonaws.com/id/${var.eks_oidc_issuer_id}:sub" = "system:serviceaccount:external-secrets-system:external-secrets"
            "oidc.eks.${var.region}.amazonaws.com/id/${var.eks_oidc_issuer_id}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "external-secrets-operator"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM policy for accessing Secrets Manager
resource "aws_iam_policy" "external_secrets_secrets_manager" {
  count       = var.eks_oidc_issuer_id != "" ? 1 : 0
  name        = "external-secrets-secrets-manager-policy"
  description = "Policy for External Secrets Operator to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}-*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "external_secrets_secrets_manager" {
  count      = var.eks_oidc_issuer_id != "" ? 1 : 0
  policy_arn = aws_iam_policy.external_secrets_secrets_manager[0].arn
  role       = aws_iam_role.external_secrets[0].name
}
