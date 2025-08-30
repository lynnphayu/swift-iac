# =============================================================================
# RANDOM PASSWORD FOR DOCUMENTDB
# =============================================================================

resource "random_password" "docdb_password" {
  length  = 16
  special = true
}

# =============================================================================
# SECRETS MANAGER SECRET
# =============================================================================

resource "aws_secretsmanager_secret" "docdb_password" {
  name                    = "${var.project_name}-docdb-password-${var.environment}"
  description             = "DocumentDB cluster master password"
  recovery_window_in_days = 0 # For dev environments

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = aws_secretsmanager_secret.docdb_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.docdb_password.result
  })
}

# =============================================================================
# KMS KEY FOR ENCRYPTION
# =============================================================================

resource "aws_kms_key" "docdb" {
  description             = "KMS key for DocumentDB cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-docdb-kms-key-${var.environment}"
  })
}

resource "aws_kms_alias" "docdb" {
  name          = "alias/${var.project_name}-docdb-${var.environment}"
  target_key_id = aws_kms_key.docdb.key_id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

resource "aws_security_group" "docdb" {
  name_prefix = "${var.project_name}-docdb-"
  vpc_id      = var.vpc_id
  description = "Security group for DocumentDB cluster"

  # Allow DocumentDB access from EKS cluster
  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.eks_cluster_security_group_id != "" ? [var.eks_cluster_security_group_id] : []
    description     = "DocumentDB access from EKS cluster"
  }

  # Allow DocumentDB access from VPC CIDR
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "DocumentDB access from VPC"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-docdb-sg-${var.environment}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DOCUMENTDB SUBNET GROUP
# =============================================================================

resource "aws_docdb_subnet_group" "docdb" {
  name       = "${var.project_name}-docdb-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-docdb-subnet-group-${var.environment}"
  })
}

# =============================================================================
# CLOUDWATCH LOG GROUP
# =============================================================================

resource "aws_cloudwatch_log_group" "docdb" {
  name              = "/aws/docdb/cluster/${var.project_name}-${var.environment}/audit"
  retention_in_days = 7

  tags = local.common_tags
}

# =============================================================================
# DOCUMENTDB CLUSTER PARAMETER GROUP
# =============================================================================

resource "aws_docdb_cluster_parameter_group" "docdb" {
  family      = "docdb5.0"
  name        = "${var.project_name}-docdb-cluster-pg-${var.environment}"
  description = "DocumentDB cluster parameter group for ${var.project_name}"

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  parameter {
    name  = "profiler"
    value = "enabled"
  }

  parameter {
    name  = "profiler_threshold_ms"
    value = "100"
  }

  tags = local.common_tags
}

# =============================================================================
# DOCUMENTDB CLUSTER
# =============================================================================

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier = "${var.cluster_identifier}-${var.environment}"
  engine             = var.engine
  engine_version     = var.engine_version
  master_username    = var.master_username
  master_password    = random_password.docdb_password.result

  # Networking
  db_subnet_group_name   = aws_docdb_subnet_group.docdb.name
  vpc_security_group_ids = [aws_security_group.docdb.id]
  port                   = var.port

  # Backup and maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # Security
  storage_encrypted   = var.storage_encrypted
  kms_key_id          = aws_kms_key.docdb.arn
  deletion_protection = var.deletion_protection

  # Logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Upgrades
  apply_immediately = var.apply_immediately

  # Snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Parameter group
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.docdb.name

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-docdb-cluster-${var.environment}"
  })

  depends_on = [
    aws_cloudwatch_log_group.docdb
  ]
}

# =============================================================================
# DOCUMENTDB CLUSTER INSTANCES
# =============================================================================

resource "aws_docdb_cluster_instance" "docdb" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-${var.environment}-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = var.instance_class

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-docdb-instance-${count.index + 1}-${var.environment}"
  })
}
