# =============================================================================
# IAM ROLES OUTPUTS
# =============================================================================

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.roles.github_actions_role_arn
}

output "eks_ecr_pull_role_arn" {
  description = "EKS ECR pull IAM role ARN"
  value       = module.roles.eks_ecr_pull_role_arn
}

output "k8s_ecr_pull_role_arn" {
  description = "K8s ECR pull IAM role ARN"
  value       = module.roles.k8s_ecr_pull_role_arn
}

# =============================================================================
# EKS CLUSTER OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.eks.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.eks.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.eks.public_subnet_ids
}

# =============================================================================
# RDS CLUSTER OUTPUTS
# =============================================================================

output "rds_cluster_arn" {
  description = "The ARN of the RDS Aurora cluster"
  value       = module.rds.cluster_arn
}

output "rds_cluster_endpoint" {
  description = "The connection endpoint for the RDS Aurora cluster"
  value       = module.rds.cluster_endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "The reader endpoint for the RDS Aurora cluster"
  value       = module.rds.cluster_reader_endpoint
}

output "rds_cluster_port" {
  description = "The port of the RDS Aurora cluster"
  value       = module.rds.cluster_port
}

output "rds_database_name" {
  description = "The name of the database"
  value       = module.rds.database_name
}

output "rds_connection_string" {
  description = "The full connection string for the database"
  value       = module.rds.connection_string
  sensitive   = true
}

output "rds_secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the DB password"
  value       = module.rds.secrets_manager_secret_arn
}

output "kubernetes_secret_manifest" {
  description = "Kubernetes secret manifest for database connection"
  value       = module.rds.kubernetes_secret_manifest
  sensitive   = true
}

# =============================================================================
# DOCUMENTDB OUTPUTS
# =============================================================================

output "documentdb_cluster_arn" {
  description = "The ARN of the DocumentDB cluster"
  value       = module.documentdb.cluster_arn
}

output "documentdb_cluster_endpoint" {
  description = "The connection endpoint for the DocumentDB cluster"
  value       = module.documentdb.cluster_endpoint
}

output "documentdb_cluster_reader_endpoint" {
  description = "The reader endpoint for the DocumentDB cluster"
  value       = module.documentdb.cluster_reader_endpoint
}

output "documentdb_cluster_port" {
  description = "The port of the DocumentDB cluster"
  value       = module.documentdb.cluster_port
}

output "documentdb_master_username" {
  description = "The master username for DocumentDB"
  value       = module.documentdb.master_username
  sensitive   = true
}

output "documentdb_connection_string" {
  description = "The MongoDB connection string for the DocumentDB cluster"
  value       = module.documentdb.connection_string
  sensitive   = true
}

output "documentdb_connection_string_template" {
  description = "The MongoDB connection string template without credentials"
  value       = module.documentdb.connection_string_without_credentials
}

output "documentdb_secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the DocumentDB password"
  value       = module.documentdb.secrets_manager_secret_arn
}

output "documentdb_kubernetes_secret_manifest" {
  description = "Kubernetes secret manifest for DocumentDB connection"
  value       = module.documentdb.kubernetes_secret_manifest
  sensitive   = true
}

output "documentdb_ssl_certificate_info" {
  description = "Information about SSL certificate for DocumentDB"
  value       = module.documentdb.ssl_certificate_info
}

# =============================================================================
# CONVENIENCE OUTPUTS
# =============================================================================

output "kubeconfig_update_command" {
  description = "Command to update kubeconfig for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${split("/", var.ecr_repository_name)[0]}.dkr.ecr.${var.region}.amazonaws.com"
}
