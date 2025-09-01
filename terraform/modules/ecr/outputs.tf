# =============================================================================
# ECR REPOSITORY OUTPUTS
# =============================================================================

output "repository_url" {
  description = "URL of the main ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN of the main ECR repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Name of the main ECR repository"
  value       = aws_ecr_repository.main.name
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.main.registry_id
}

# =============================================================================
# USEFUL DERIVED OUTPUTS
# =============================================================================

output "docker_login_command" {
  description = "AWS CLI command to authenticate Docker to ECR"
  value       = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.main.repository_url}"
}


# =============================================================================
# CI/CD INTEGRATION OUTPUTS
# =============================================================================

output "image_uri_template" {
  description = "Template for image URI (replace {tag} with actual tag)"
  value       = "${aws_ecr_repository.main.repository_url}:{tag}"
}

output "latest_image_uri" {
  description = "URI for the latest image"
  value       = "${aws_ecr_repository.main.repository_url}:latest"
}
