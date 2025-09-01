#!/bin/bash

# =============================================================================
# Kubernetes Cluster Setup Script
# =============================================================================
# This script installs essential components for the DAG Swarm infrastructure:
# - External Secrets Operator (ESO)
# - KEDA (Event-driven autoscaling)
# - AWS Load Balancer Controller
# - Cluster Autoscaler
# - Metrics Server
# =============================================================================

set -euo pipefail

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-dag-swarm}"
REGION="${REGION:-ap-southeast-1}"
NAMESPACE="${NAMESPACE:-default}"
AWS_PROFILE="${AWS_PROFILE:-swift-dev}"
EXTERNAL_SECRETS_VERSION="${EXTERNAL_SECRETS_VERSION:-0.10.2}"
KEDA_VERSION="${KEDA_VERSION:-2.15.1}"
KEDA_HTTP_VERSION="${KEDA_HTTP_VERSION:-0.8.0}"
AWS_LBC_VERSION="${AWS_LBC_VERSION:-2.8.2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    log_info "Waiting for deployment $deployment in namespace $namespace to be ready..."
    if kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace; then
        log_success "Deployment $deployment is ready"
        return 0
    else
        log_error "Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists helm; then
        missing_tools+=("helm")
    fi
    
    if ! command_exists aws; then
        missing_tools+=("aws-cli")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    # Check kubectl connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Make sure your kubeconfig is properly configured"
        log_info "Run: aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME --profile $AWS_PROFILE"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Update kubeconfig
update_kubeconfig() {
    log_info "Updating kubeconfig for cluster $CLUSTER_NAME in region $REGION..."
    if aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" --profile "$AWS_PROFILE"; then
        log_success "Kubeconfig updated successfully"
    else
        log_error "Failed to update kubeconfig"
        exit 1
    fi
}

# Install External Secrets Operator
install_external_secrets() {
    log_info "Installing External Secrets Operator..."
    
    # Add Helm repository
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    
    # Create namespace
    kubectl create namespace external-secrets-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install External Secrets Operator
    helm upgrade --install external-secrets external-secrets/external-secrets \
        --namespace external-secrets-system \
        --version "$EXTERNAL_SECRETS_VERSION" \
        --set installCRDs=true \
        --set webhook.port=9443 \
        --set certController.enable=true \
        --wait --timeout=10m
    
    # Wait for deployment
    wait_for_deployment external-secrets-system external-secrets
    wait_for_deployment external-secrets-system external-secrets-webhook
    wait_for_deployment external-secrets-system external-secrets-cert-controller
    
    log_success "External Secrets Operator installed successfully"
}

# Install KEDA
install_keda() {
    log_info "Installing KEDA (Kubernetes Event-driven Autoscaling)..."
    
    # Add Helm repository
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    
    # Create namespace
    kubectl create namespace keda-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install KEDA Core
    helm upgrade --install keda kedacore/keda \
        --namespace keda-system \
        --version "$KEDA_VERSION" \
        --set prometheus.metricServer.enabled=false \
        --set prometheus.operator.enabled=false \
        --wait --timeout=10m
    
    # Wait for KEDA core deployments
    wait_for_deployment keda-system keda-operator
    wait_for_deployment keda-system keda-operator-metrics-apiserver
    
    log_success "KEDA Core installed successfully"
    
    # Install KEDA HTTP Add-on
    log_info "Installing KEDA HTTP Add-on..."
    
    helm repo add kedacore-http-add-on https://kedacore.github.io/charts
    helm repo update
    
    helm upgrade --install keda-add-ons-http kedacore-http-add-on/keda-add-ons-http \
        --namespace keda-system \
        --version "$KEDA_HTTP_VERSION" \
        --wait --timeout=10m
    
    # Wait for HTTP add-on deployments (with reduced replica count)
    kubectl patch deployment keda-add-ons-http-external-scaler -n keda-system -p '{"spec":{"replicas":1}}'
    kubectl patch deployment keda-add-ons-http-interceptor -n keda-system -p '{"spec":{"replicas":1}}'
    
    wait_for_deployment keda-system keda-add-ons-http-controller-manager
    
    log_success "KEDA HTTP Add-on installed successfully"
}

# Install AWS Load Balancer Controller
install_aws_load_balancer_controller() {
    log_info "Installing AWS Load Balancer Controller..."
    
    # Get cluster info
    local cluster_name=$(kubectl config current-context | cut -d'/' -f2)
    local account_id=$(aws sts get-caller-identity --query Account --output text --profile "$AWS_PROFILE")
    local region=$(aws configure get region --profile "$AWS_PROFILE" || echo "$REGION")
    
    # Add Helm repository
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    # Create namespace
    kubectl create namespace aws-load-balancer-system --dry-run=client -o yaml | kubectl apply -f -
    
    # Install AWS Load Balancer Controller
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        --namespace aws-load-balancer-system \
        --version "$AWS_LBC_VERSION" \
        --set clusterName="$cluster_name" \
        --set serviceAccount.create=true \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set region="$region" \
        --set vpcId=$(aws eks describe-cluster --name "$cluster_name" --query "cluster.resourcesVpcConfig.vpcId" --output text --profile "$AWS_PROFILE") \
        --wait --timeout=10m
    
    wait_for_deployment aws-load-balancer-system aws-load-balancer-controller
    
    log_success "AWS Load Balancer Controller installed successfully"
}

# Install Metrics Server (if not already present)
install_metrics_server() {
    log_info "Checking for Metrics Server..."
    
    if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
        log_info "Metrics Server already exists"
        return 0
    fi
    
    log_info "Installing Metrics Server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    wait_for_deployment kube-system metrics-server
    
    log_success "Metrics Server installed successfully"
}

# Install Cluster Autoscaler
install_cluster_autoscaler() {
    log_info "Installing Cluster Autoscaler..."
    
    local cluster_name=$(kubectl config current-context | cut -d'/' -f2)
    local region=$(aws configure get region --profile "$AWS_PROFILE" || echo "$REGION")
    
    # Download and apply cluster autoscaler
    curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    
    # Update the cluster name in the YAML
    sed -i.bak "s/<YOUR CLUSTER NAME>/$cluster_name/g" cluster-autoscaler-autodiscover.yaml
    
    kubectl apply -f cluster-autoscaler-autodiscover.yaml
    
    # Annotate the deployment to prevent it from scaling itself
    kubectl annotate deployment cluster-autoscaler -n kube-system \
        cluster-autoscaler.kubernetes.io/safe-to-evict="false" --overwrite
    
    # Clean up
    rm -f cluster-autoscaler-autodiscover.yaml cluster-autoscaler-autodiscover.yaml.bak
    
    wait_for_deployment kube-system cluster-autoscaler
    
    log_success "Cluster Autoscaler installed successfully"
}

# Create application namespace
create_application_namespace() {
    log_info "Creating application namespace: $NAMESPACE..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    log_success "Namespace $NAMESPACE created/updated"
}

# Apply External Secrets configuration
apply_external_secrets_config() {
    log_info "Applying External Secrets configuration..."
    
    # Check if external secrets config files exist
    local config_dir="../external-secrets"
    
    if [ -d "$config_dir" ]; then
        log_info "Applying ClusterSecretStore..."
        if [ -f "$config_dir/cluster-secret-store.yaml" ]; then
            kubectl apply -f "$config_dir/cluster-secret-store.yaml"
        else
            log_warning "ClusterSecretStore configuration not found at $config_dir/cluster-secret-store.yaml"
        fi
        
        log_info "Applying External Secrets..."
        if [ -f "$config_dir/rds-external-secret.yaml" ]; then
            # Update namespace in the external secret
            sed "s/namespace: test-tenant-1/namespace: $NAMESPACE/g" "$config_dir/rds-external-secret.yaml" | kubectl apply -f -
        else
            log_warning "RDS External Secret configuration not found"
        fi
        
        if [ -f "$config_dir/documentdb-external-secret.yaml" ]; then
            # Update namespace in the external secret
            sed "s/namespace: test-tenant-1/namespace: $NAMESPACE/g" "$config_dir/documentdb-external-secret.yaml" | kubectl apply -f -
        else
            log_warning "DocumentDB External Secret configuration not found"
        fi
        
        log_success "External Secrets configuration applied"
    else
        log_warning "External Secrets configuration directory not found at $config_dir"
    fi
}

# Verify installations
verify_installations() {
    log_info "Verifying installations..."
    
    local failed_checks=()
    
    # Check External Secrets Operator
    if kubectl get deployment external-secrets -n external-secrets-system >/dev/null 2>&1; then
        log_success "✓ External Secrets Operator is running"
    else
        failed_checks+=("External Secrets Operator")
    fi
    
    # Check KEDA
    if kubectl get deployment keda-operator -n keda-system >/dev/null 2>&1; then
        log_success "✓ KEDA is running"
    else
        failed_checks+=("KEDA")
    fi
    
    # Check AWS Load Balancer Controller
    if kubectl get deployment aws-load-balancer-controller -n aws-load-balancer-system >/dev/null 2>&1; then
        log_success "✓ AWS Load Balancer Controller is running"
    else
        failed_checks+=("AWS Load Balancer Controller")
    fi
    
    # Check Metrics Server
    if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
        log_success "✓ Metrics Server is running"
    else
        failed_checks+=("Metrics Server")
    fi
    
    # Check Cluster Autoscaler
    if kubectl get deployment cluster-autoscaler -n kube-system >/dev/null 2>&1; then
        log_success "✓ Cluster Autoscaler is running"
    else
        failed_checks+=("Cluster Autoscaler")
    fi
    
    if [ ${#failed_checks[@]} -eq 0 ]; then
        log_success "All components verified successfully!"
    else
        log_error "Some components failed verification: ${failed_checks[*]}"
        return 1
    fi
}

# Show cluster status
show_cluster_status() {
    log_info "Cluster Status Summary:"
    echo "======================================"
    
    echo -e "\n${BLUE}Namespaces:${NC}"
    kubectl get namespaces
    
    echo -e "\n${BLUE}Nodes:${NC}"
    kubectl get nodes
    
    echo -e "\n${BLUE}External Secrets Operator:${NC}"
    kubectl get pods -n external-secrets-system 2>/dev/null || echo "Not installed"
    
    echo -e "\n${BLUE}KEDA:${NC}"
    kubectl get pods -n keda-system 2>/dev/null || echo "Not installed"
    
    echo -e "\n${BLUE}Application Namespace ($NAMESPACE):${NC}"
    kubectl get pods -n "$NAMESPACE" 2>/dev/null || echo "No pods in namespace"
    
    echo "======================================"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install essential Kubernetes components for DAG Swarm infrastructure.

OPTIONS:
    -c, --cluster-name NAME     EKS cluster name (default: dag-swarm)
    -r, --region REGION         AWS region (default: ap-southeast-1)
    -n, --namespace NAMESPACE   Application namespace (default: default)
    --aws-profile PROFILE       AWS profile name (default: swift-dev)
    --skip-eso                  Skip External Secrets Operator installation
    --skip-keda                 Skip KEDA installation
    --skip-alb                  Skip AWS Load Balancer Controller installation
    --skip-metrics              Skip Metrics Server installation
    --skip-autoscaler           Skip Cluster Autoscaler installation
    --update-kubeconfig         Update kubeconfig before installation
    --verify-only               Only verify existing installations
    -h, --help                  Show this help message

EXAMPLES:
    # Install all components with defaults
    $0

    # Install to specific cluster and namespace
    $0 -c my-cluster -r us-west-2 -n production

    # Skip some components
    $0 --skip-alb --skip-autoscaler

    # Use specific AWS profile
    $0 --aws-profile swift-dev

    # Update kubeconfig and install
    $0 --update-kubeconfig

EOF
}

# Main function
main() {
    local skip_eso=false
    local skip_keda=false
    local skip_alb=false
    local skip_metrics=false
    local skip_autoscaler=false
    local update_kubeconfig=false
    local verify_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--cluster-name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -r|--region)
                REGION="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --aws-profile)
                AWS_PROFILE="$2"
                shift 2
                ;;
            --skip-eso)
                skip_eso=true
                shift
                ;;
            --skip-keda)
                skip_keda=true
                shift
                ;;
            --skip-alb)
                skip_alb=true
                shift
                ;;
            --skip-metrics)
                skip_metrics=true
                shift
                ;;
            --skip-autoscaler)
                skip_autoscaler=true
                shift
                ;;
            --update-kubeconfig)
                update_kubeconfig=true
                shift
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    log_info "Starting Kubernetes cluster setup..."
    log_info "Cluster: $CLUSTER_NAME"
    log_info "Region: $REGION"
    log_info "Namespace: $NAMESPACE"
    log_info "AWS Profile: $AWS_PROFILE"
    
    # Update kubeconfig if requested
    if [ "$update_kubeconfig" = true ]; then
        update_kubeconfig
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # If verify-only mode, just verify and exit
    if [ "$verify_only" = true ]; then
        verify_installations
        show_cluster_status
        exit 0
    fi
    
    # Create application namespace
    create_application_namespace
    
    # Install components
    if [ "$skip_eso" = false ]; then
        install_external_secrets
        apply_external_secrets_config
    fi
    
    if [ "$skip_keda" = false ]; then
        install_keda
    fi
    
    if [ "$skip_alb" = false ]; then
        install_aws_load_balancer_controller
    fi
    
    if [ "$skip_metrics" = false ]; then
        install_metrics_server
    fi
    
    if [ "$skip_autoscaler" = false ]; then
        install_cluster_autoscaler
    fi
    
    # Verify installations
    verify_installations
    
    # Show final status
    show_cluster_status
    
    log_success "Kubernetes cluster setup completed successfully!"
    log_info "You can now deploy your applications using:"
    log_info "  cd ../runner-chart"
    log_info "  helm install app-name . -f values.yaml --namespace $NAMESPACE"
}

# Run main function with all arguments
main "$@"
