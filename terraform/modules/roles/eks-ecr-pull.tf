# EKS Node Group Role for ECR pulling
# This file contains resources for EKS managed node groups to pull images from ECR

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_ecr_pull_role" {
  name                  = var.eks_ecr_pull_role_name
  assume_role_policy    = data.aws_iam_policy_document.eks_node_assume_role.json
  description           = "Role for EKS nodes to pull images from ECR"
  force_detach_policies = true
}

data "aws_iam_policy_document" "ecr_pull" {
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

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "${var.eks_ecr_pull_role_name}-policy"
  description = "Allow pulling images from ECR repository ${var.ecr_repository_name}"
  policy      = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr_pull" {
  role       = aws_iam_role.eks_ecr_pull_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

# Attach AWS managed policies required for EKS node groups
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_ecr_pull_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_ecr_pull_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_readonly" {
  role       = aws_iam_role.eks_ecr_pull_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
