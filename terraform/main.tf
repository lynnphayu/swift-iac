# =============================================================================
# DAG SWARM INFRASTRUCTURE
# =============================================================================

# First create ECR repositories - roles module depends on these
module "ecr" {
  source = "./modules/ecr"

  # Core configuration
  repository_name = var.ecr_repository_name
  region          = var.region
  environment     = var.environment
  project_name    = var.project_name

  # ECR configuration
  image_tag_mutability = "MUTABLE"
  force_delete         = var.environment == "dev" ? true : false
  scan_on_push         = true

  # Lifecycle policy
  enable_lifecycle_policy    = true
  max_image_count            = var.environment == "prod" ? 20 : 10
  untagged_image_expiry_days = 1

  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Create IAM roles - depends on ECR
module "roles" {
  source = "./modules/roles"

  # Shared variables
  region = var.region

  # ECR integration - use outputs from ECR module
  ecr_repository_arn = module.ecr.repository_arn
  ecr_repository_url = module.ecr.repository_url

  # Backward compatibility (remove once fully migrated)
  ecr_repository_name = var.ecr_repository_name

  # GitHub Actions variables
  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_ref   = var.github_ref
  role_name    = var.github_actions_role_name

  # Role names
  eks_ecr_pull_role_name = var.eks_ecr_pull_role_name
  k8s_ecr_pull_role_name = var.k8s_ecr_pull_role_name

  # External Secrets Operator role configuration (will be created separately to avoid circular dependency)
  project_name       = var.project_name
  environment        = var.environment
  eks_oidc_issuer_id = "" # Will be set later to avoid circular dependency

  depends_on = [module.ecr]
}

# Create EKS cluster - depends on roles
module "eks" {
  source = "./modules/eks"

  region                 = var.region
  cluster_name           = var.cluster_name
  eks_ecr_pull_role_name = var.eks_ecr_pull_role_name

  depends_on = [module.roles]
}

# Create RDS cluster - depends on EKS for VPC info
module "rds" {
  source = "./modules/rds"

  # Shared variables
  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  # Database configuration
  database_name                = var.database_name
  master_username              = var.master_username
  instance_class               = var.instance_class
  instance_count               = var.instance_count
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection

  # Use VPC from EKS module
  vpc_id                        = module.eks.vpc_id
  private_subnet_ids            = module.eks.private_subnet_ids
  eks_cluster_security_group_id = module.eks.cluster_security_group_id

  depends_on = [module.eks]
}

# Create DocumentDB cluster - depends on EKS for VPC info
module "documentdb" {
  source = "./modules/documentdb"

  # Shared variables
  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  # DocumentDB configuration
  cluster_identifier           = var.documentdb_cluster_identifier
  master_username              = var.documentdb_master_username
  instance_class               = var.documentdb_instance_class
  instance_count               = var.documentdb_instance_count
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection

  # Use VPC from EKS module
  vpc_id                        = module.eks.vpc_id
  private_subnet_ids            = module.eks.private_subnet_ids
  eks_cluster_security_group_id = module.eks.cluster_security_group_id

  depends_on = [module.eks]
}
