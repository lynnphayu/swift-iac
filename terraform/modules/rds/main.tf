# =============================================================================
# LOCAL VALUES
# =============================================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# RANDOM PASSWORD FOR RDS
# =============================================================================

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-rds-password-${var.environment}"
  description             = "RDS Aurora cluster master password"
  recovery_window_in_days = 0 # For development, allows immediate deletion

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.db_password.result
    engine   = var.engine
    host     = aws_rds_cluster.aurora.endpoint
    port     = aws_rds_cluster.aurora.port
    dbname   = var.database_name
  })
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS Aurora cluster"

  # Allow PostgreSQL access from EKS cluster
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
    description     = "PostgreSQL access from EKS cluster"
  }

  # Allow PostgreSQL access from VPC CIDR
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "PostgreSQL access from VPC"
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
    Name = "${var.project_name}-rds-sg-${var.environment}"
  })
}

# =============================================================================
# RDS SUBNET GROUP
# =============================================================================

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-aurora-subnet-group-${var.environment}"
  })
}

# =============================================================================
# RDS PARAMETER GROUPS
# =============================================================================

resource "aws_rds_cluster_parameter_group" "aurora" {
  family      = "aurora-postgresql15"
  name        = "${var.project_name}-aurora-cluster-pg-${var.environment}"
  description = "Aurora cluster parameter group for ${var.project_name}"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "immediate"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking more than 1 second
  }

  tags = local.common_tags
}

resource "aws_db_parameter_group" "aurora" {
  family      = "aurora-postgresql15"
  name        = "${var.project_name}-aurora-instance-pg-${var.environment}"
  description = "Aurora instance parameter group for ${var.project_name}"

  tags = local.common_tags
}

# =============================================================================
# RDS AURORA CLUSTER
# =============================================================================

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.cluster_identifier}-${var.environment}"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version

  # Database configuration
  database_name   = var.database_name
  master_username = var.master_username
  master_password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  copy_tags_to_snapshot   = true

  # Maintenance configuration
  preferred_maintenance_window = var.preferred_maintenance_window

  # Security configuration
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.rds.arn
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-aurora-cluster-${var.environment}"
  })

  depends_on = [
    aws_cloudwatch_log_group.aurora
  ]
}

# =============================================================================
# RDS AURORA INSTANCES
# =============================================================================

resource "aws_rds_cluster_instance" "aurora" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-${var.environment}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id

  instance_class = var.instance_class
  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  db_parameter_group_name = aws_db_parameter_group.aurora.name

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_enhanced_monitoring.arn

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-aurora-instance-${count.index + 1}-${var.environment}"
  })
}

# =============================================================================
# KMS KEY FOR ENCRYPTION
# =============================================================================

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS Aurora cluster encryption"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-kms-key-${var.environment}"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds-${var.environment}"
  target_key_id = aws_kms_key.rds.key_id
}

# =============================================================================
# CLOUDWATCH LOG GROUP
# =============================================================================

resource "aws_cloudwatch_log_group" "aurora" {
  name              = "/aws/rds/cluster/${var.cluster_identifier}-${var.environment}/postgresql"
  retention_in_days = 7

  tags = local.common_tags
}

# =============================================================================
# IAM ROLE FOR ENHANCED MONITORING
# =============================================================================

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
