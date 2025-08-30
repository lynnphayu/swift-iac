variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "dag-swarm"
}

variable "eks_ecr_pull_role_name" {
  description = "IAM role name for EKS nodes to pull images from ECR"
  type        = string
  default     = "eks-ecr-pull-role"
}
