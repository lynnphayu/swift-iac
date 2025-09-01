# =============================================================================
# DOCUMENTDB CLUSTER OUTPUTS
# =============================================================================

output "cluster_arn" {
  description = "The ARN of the DocumentDB cluster"
  value       = aws_docdb_cluster.docdb.arn
}

output "cluster_endpoint" {
  description = "The connection endpoint for the DocumentDB cluster"
  value       = aws_docdb_cluster.docdb.endpoint
}

output "cluster_reader_endpoint" {
  description = "The reader endpoint for the DocumentDB cluster"
  value       = aws_docdb_cluster.docdb.reader_endpoint
}

output "cluster_port" {
  description = "The port of the DocumentDB cluster"
  value       = aws_docdb_cluster.docdb.port
}

output "cluster_identifier" {
  description = "The identifier of the DocumentDB cluster"
  value       = aws_docdb_cluster.docdb.cluster_identifier
}

output "master_username" {
  description = "The master username for the database"
  value       = var.master_username
  sensitive   = true
}

output "connection_string" {
  description = "The MongoDB connection string for the DocumentDB cluster"
  value       = "mongodb://${var.master_username}:${random_password.docdb_password.result}@${aws_docdb_cluster.docdb.endpoint}:${aws_docdb_cluster.docdb.port}/?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  sensitive   = true
}

output "connection_string_without_credentials" {
  description = "The MongoDB connection string without credentials"
  value       = "mongodb://<username>:<password>@${aws_docdb_cluster.docdb.endpoint}:${aws_docdb_cluster.docdb.port}/?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
}

# =============================================================================
# SECRETS MANAGER OUTPUTS
# =============================================================================

output "secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the DocumentDB password"
  value       = aws_secretsmanager_secret.docdb_password.arn
}

output "secrets_manager_secret_name" {
  description = "The name of the Secrets Manager secret storing the DocumentDB password"
  value       = aws_secretsmanager_secret.docdb_password.name
}

# =============================================================================
# SECURITY OUTPUTS
# =============================================================================

output "security_group_id" {
  description = "The ID of the DocumentDB security group"
  value       = aws_security_group.docdb.id
}

output "security_group_arn" {
  description = "The ARN of the DocumentDB security group"
  value       = aws_security_group.docdb.arn
}

output "subnet_group_name" {
  description = "The name of the DocumentDB subnet group"
  value       = aws_docdb_subnet_group.docdb.name
}

output "subnet_group_arn" {
  description = "The ARN of the DocumentDB subnet group"
  value       = aws_docdb_subnet_group.docdb.arn
}

# =============================================================================
# ENCRYPTION OUTPUTS
# =============================================================================

output "kms_key_id" {
  description = "The ID of the KMS key used for DocumentDB encryption"
  value       = aws_kms_key.docdb.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for DocumentDB encryption"
  value       = aws_kms_key.docdb.arn
}

# =============================================================================
# INSTANCE OUTPUTS
# =============================================================================

output "cluster_instances" {
  description = "List of DocumentDB cluster instance identifiers"
  value       = aws_docdb_cluster_instance.docdb[*].identifier
}

output "cluster_instance_endpoints" {
  description = "List of DocumentDB cluster instance endpoints"
  value       = aws_docdb_cluster_instance.docdb[*].endpoint
}

# =============================================================================
# EXTERNAL SECRETS INTEGRATION
# =============================================================================



# =============================================================================
# SSL CERTIFICATE INFORMATION
# =============================================================================

output "ssl_certificate_info" {
  description = "Information about SSL certificate for DocumentDB"
  value = {
    download_url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem"
    description  = "Download this certificate and configure your MongoDB client to use SSL"
  }
}
