#!/bin/bash

# =============================================================================
# DAG Runner Deployment Script
# =============================================================================
# 
# This script automates the deployment of the DAG Runner chart
# using the unified terraform infrastructure.
#
# Usage: ./deploy.sh [install|upgrade|uninstall|status]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
CHART_NAME="dag-runner"
VALUES_FILE="values.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform directory exists
check_terraform() {
    if [ ! -d "$TERRAFORM_DIR" ]; then
        log_error "Terraform directory not found at $TERRAFORM_DIR"
        exit 1
    fi
    
    if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        log_error "Terraform state not found. Please run 'terraform apply' first."
        exit 1
    fi
}

# Update kubeconfig
update_kubeconfig() {
    log_info "Updating kubeconfig..."
    cd "$TERRAFORM_DIR"
    
    KUBECONFIG_CMD=$(terraform output -raw kubeconfig_update_command 2>/dev/null || echo "")
    if [ -z "$KUBECONFIG_CMD" ]; then
        log_error "Could not get kubeconfig command from terraform"
        exit 1
    fi
    
    log_info "Running: $KUBECONFIG_CMD"
    eval "$KUBECONFIG_CMD"
    log_success "Kubeconfig updated"
}

# Deploy database secrets
deploy_secrets() {
    log_info "Deploying database secrets to Kubernetes..."
    cd "$TERRAFORM_DIR"
    
    # Deploy RDS secret
    log_info "Deploying RDS credentials secret..."
    terraform output -raw kubernetes_secret_manifest | kubectl apply -f -
    
    # Deploy DocumentDB secret
    log_info "Deploying DocumentDB credentials secret..."
    terraform output -raw documentdb_kubernetes_secret_manifest | kubectl apply -f -
    
    log_success "Database secrets deployed"
}

# Update values file with IAM role
update_values_file() {
    log_info "Updating values file with IAM role ARN..."
    cd "$TERRAFORM_DIR"
    
    ECR_ROLE_ARN=$(terraform output -raw k8s_ecr_pull_role_arn 2>/dev/null || echo "")
    if [ -z "$ECR_ROLE_ARN" ]; then
        log_error "Could not get ECR role ARN from terraform"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    
    # Create temporary values file with role ARN
    cp "$VALUES_FILE" "${VALUES_FILE}.tmp"
    sed "s|eks.amazonaws.com/role-arn: \"\".*|eks.amazonaws.com/role-arn: \"$ECR_ROLE_ARN\"|" "${VALUES_FILE}.tmp" > "${VALUES_FILE}.generated"
    
    log_success "Values file updated with role ARN: $ECR_ROLE_ARN"
}

# Install/upgrade helm chart
install_chart() {
    local action=$1
    cd "$SCRIPT_DIR"
    
    log_info "${action^}ing Helm chart..."
    
    if [ "$action" = "install" ]; then
        helm install "$CHART_NAME" . -f "${VALUES_FILE}.generated"
    else
        helm upgrade "$CHART_NAME" . -f "${VALUES_FILE}.generated"
    fi
    
    log_success "Helm chart ${action}ed successfully"
}

# Uninstall helm chart
uninstall_chart() {
    cd "$SCRIPT_DIR"
    
    log_info "Uninstalling Helm chart..."
    helm uninstall "$CHART_NAME" || log_warning "Chart may not be installed"
    
    log_info "Cleaning up secrets..."
    kubectl delete secret dag-swarm-rds-credentials || log_warning "RDS secret may not exist"
    kubectl delete secret dag-swarm-docdb-credentials || log_warning "DocumentDB secret may not exist"
    
    log_success "Helm chart uninstalled"
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    echo
    
    echo "=== Helm Releases ==="
    helm list -q | grep "$CHART_NAME" || echo "Chart not installed"
    echo
    
    echo "=== Pods ==="
    kubectl get pods -l app=dag-runner || echo "No pods found"
    echo
    
    echo "=== Services ==="
    kubectl get svc -l app=dag-runner || echo "No services found"
    echo
    
    echo "=== Ingress ==="
    kubectl get ingress -l app=dag-runner || echo "No ingress found"
    echo
    
    echo "=== Secrets ==="
    kubectl get secrets | grep -E "(rds|docdb)" || echo "No database secrets found"
}

# Cleanup temporary files
cleanup() {
    cd "$SCRIPT_DIR"
    rm -f "${VALUES_FILE}.tmp" "${VALUES_FILE}.generated"
}

# Main script
main() {
    local action=${1:-install}
    
    case $action in
        install|upgrade)
            log_info "Starting $action process..."
            check_terraform
            update_kubeconfig
            deploy_secrets
            update_values_file
            install_chart "$action"
            cleanup
            log_success "$action completed successfully!"
            echo
            show_status
            ;;
        uninstall)
            log_info "Starting uninstall process..."
            uninstall_chart
            cleanup
            log_success "Uninstall completed!"
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Usage: $0 [install|upgrade|uninstall|status]"
            exit 1
            ;;
    esac
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
