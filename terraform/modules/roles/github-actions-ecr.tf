# GitHub Actions OIDC Provider and ECR Role
# This file contains resources for GitHub Actions to push images to ECR

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e5e9041e0e9d7b1b6fdecbc1f90d1"
  ]
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        # Standard branch/tag ref format
        "repo:${var.github_owner}/${var.github_repo}:ref:${var.github_ref}",
        # Allow non-ref subjects like pull_request
        "repo:${var.github_owner}/${var.github_repo}:${var.github_ref}"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr" {
  name                  = var.role_name
  assume_role_policy    = data.aws_iam_policy_document.github_oidc_assume_role.json
  description           = "Role assumed by GitHub Actions to push images to ECR for ${var.github_owner}/${var.github_repo}"
  force_detach_policies = true
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "AuthenticateToECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PushAndPullSpecificRepo"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [local.ecr_repo_arn]
  }
}

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "${var.role_name}-policy"
  description = "Allow pushing images to ECR repository ${var.ecr_repository_name}"
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr_push" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}
