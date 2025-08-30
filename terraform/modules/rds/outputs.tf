# =============================================================================
# RDS CLUSTER OUTPUTS
# =============================================================================

output "cluster_identifier" {
  description = "RDS cluster identifier"
  value       = aws_rds_cluster.aurora.cluster_identifier
}

output "cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_port" {
  description = "RDS cluster port"
  value       = aws_rds_cluster.aurora.port
}

output "cluster_arn" {
  description = "RDS cluster ARN"
  value       = aws_rds_cluster.aurora.arn
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora.database_name
}

output "master_username" {
  description = "RDS cluster master username"
  value       = aws_rds_cluster.aurora.master_username
  sensitive   = true
}

# =============================================================================
# SECURITY OUTPUTS
# =============================================================================

output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "RDS security group ARN"
  value       = aws_security_group.rds.arn
}

# =============================================================================
# SECRETS MANAGER OUTPUTS
# =============================================================================

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secrets_manager_secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.db_password.name
}

# =============================================================================
# SUBNET GROUP OUTPUTS
# =============================================================================

output "subnet_group_name" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.aurora.name
}

output "subnet_group_arn" {
  description = "RDS subnet group ARN"
  value       = aws_db_subnet_group.aurora.arn
}

# =============================================================================
# KMS OUTPUTS
# =============================================================================

output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds.arn
}

# =============================================================================
# CONNECTION STRING OUTPUT
# =============================================================================

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_rds_cluster.aurora.master_username}@${aws_rds_cluster.aurora.endpoint}:${aws_rds_cluster.aurora.port}/${aws_rds_cluster.aurora.database_name}"
  sensitive   = true
}

# =============================================================================
# KUBERNETES SECRET MANIFEST
# =============================================================================

output "kubernetes_secret_manifest" {
  description = "Kubernetes secret manifest for database connection"
  value = base64encode(yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "postgres-connection"
      namespace = "default"
    }
    type = "Opaque"
    data = {
      DATABASE_URL = base64encode("postgresql://${aws_rds_cluster.aurora.master_username}:${random_password.db_password.result}@${aws_rds_cluster.aurora.endpoint}:${aws_rds_cluster.aurora.port}/${aws_rds_cluster.aurora.database_name}")
      DB_HOST      = base64encode(aws_rds_cluster.aurora.endpoint)
      DB_PORT      = base64encode(tostring(aws_rds_cluster.aurora.port))
      DB_NAME      = base64encode(aws_rds_cluster.aurora.database_name)
      DB_USERNAME  = base64encode(aws_rds_cluster.aurora.master_username)
      DB_PASSWORD  = base64encode(random_password.db_password.result)
    }
  }))
  sensitive = true
}
