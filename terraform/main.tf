# =============================================================================
# DAG SWARM INFRASTRUCTURE
# =============================================================================

# First create IAM roles - other modules depend on these
module "roles" {
  source = "./modules/roles"

  # Shared variables
  region              = var.region
  ecr_repository_name = var.ecr_repository_name

  # GitHub Actions variables
  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_ref   = var.github_ref
  role_name    = var.github_actions_role_name

  # Role names
  eks_ecr_pull_role_name = var.eks_ecr_pull_role_name
  k8s_ecr_pull_role_name = var.k8s_ecr_pull_role_name

  # Local development settings
  k8s_allow_local_development = var.k8s_allow_local_development
  k8s_allow_ec2_assume        = var.k8s_allow_ec2_assume
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
