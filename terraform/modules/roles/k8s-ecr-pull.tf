# Non-EKS Kubernetes Cluster Role for ECR pulling
# This file contains resources for self-managed or other K8s clusters to pull images from ECR

data "aws_iam_policy_document" "k8s_ecr_assume_role" {

  # Allow OIDC provider to assume this role (for service account integration)
  dynamic "statement" {
    for_each = var.k8s_oidc_provider_arn != "" ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [var.k8s_oidc_provider_arn]
      }

      condition {
        test     = "StringEquals"
        variable = "${replace(var.k8s_oidc_provider_url, "https://", "")}:aud"
        values   = var.k8s_oidc_audiences
      }

      dynamic "condition" {
        for_each = length(var.k8s_service_accounts) > 0 ? [1] : []
        content {
          test     = "StringEquals"
          variable = "${replace(var.k8s_oidc_provider_url, "https://", "")}:sub"
          values   = var.k8s_service_accounts
        }
      }
    }
  }

  # Allow specific AWS accounts/roles to assume this role (for cross-account scenarios)
  dynamic "statement" {
    for_each = length(var.k8s_trusted_arns) > 0 ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.k8s_trusted_arns
      }
    }
  }

  # Allow current AWS account root for local development (enables local clusters)
  dynamic "statement" {
    for_each = var.k8s_allow_local_development ? [1] : []
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }

      condition {
        test     = "StringEquals"
        variable = "aws:RequestedRegion"
        values   = [var.region]
      }
    }
  }
}

resource "aws_iam_role" "k8s_ecr_pull_role" {
  name                  = var.k8s_ecr_pull_role_name
  assume_role_policy    = data.aws_iam_policy_document.k8s_ecr_assume_role.json
  description           = "Role for non-EKS Kubernetes cluster to pull images from ECR"
  force_detach_policies = true
}

# Create a separate ECR pull policy for the non-EKS K8s role
data "aws_iam_policy_document" "k8s_ecr_pull" {
  statement {
    sid    = "AuthenticateToECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PullFromECR"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]
    resources = [local.ecr_repo_arn]
  }
}

resource "aws_iam_policy" "k8s_ecr_pull_policy" {
  name        = "${var.k8s_ecr_pull_role_name}-policy"
  description = "Allow pulling images from ECR repository ${var.ecr_repository_name}"
  policy      = data.aws_iam_policy_document.k8s_ecr_pull.json
}

# Attach the ECR pull policy to the K8s role
resource "aws_iam_role_policy_attachment" "k8s_attach_ecr_pull" {
  role       = aws_iam_role.k8s_ecr_pull_role.name
  policy_arn = aws_iam_policy.k8s_ecr_pull_policy.arn
}
