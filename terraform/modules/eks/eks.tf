# Data source to get the ECR pull role
data "aws_iam_role" "eks_ecr_pull_role" {
  name = var.eks_ecr_pull_role_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  # Cluster endpoint access configuration
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t2.small"]
      desired_size   = 1
      min_size       = 0
      max_size       = 1

      # Use custom ECR pull role for node groups
      create_iam_role = false
      iam_role_arn    = data.aws_iam_role.eks_ecr_pull_role.arn
    }
  }
}
