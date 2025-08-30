# DAG Runner Chart - Deployment Guide

This guide explains how to deploy the DAG Runner Chart using the unified terraform infrastructure on AWS EKS.

## Prerequisites

1. **Terraform Infrastructure**: Deploy the unified terraform stack first
2. **kubectl**: Configured to access your EKS cluster
3. **Helm**: Installed for chart deployment

## Deployment Steps

### 1. Deploy Terraform Infrastructure

```bash
cd ../terraform
terraform init
terraform plan
terraform apply
```

### 2. Update kubeconfig

```bash
# Get the kubeconfig update command from terraform
terraform output kubeconfig_update_command

# Example output: aws eks update-kubeconfig --region ap-southeast-1 --name dag-swarm
```

### 3. Verify EKS Connection

```bash
kubectl get nodes
kubectl get namespaces
```

### 4. Deploy Database Secrets to Kubernetes

```bash
# Deploy RDS credentials secret
kubectl apply -f <(terraform output -raw kubernetes_secret_manifest)

# Deploy DocumentDB credentials secret
kubectl apply -f <(terraform output -raw documentdb_kubernetes_secret_manifest)

# Verify secrets are created
kubectl get secrets | grep -E "(rds|docdb)"
```

### 5. Update Service Account IAM Role

```bash
# Get the ECR pull role ARN from terraform
terraform output -raw k8s_ecr_pull_role_arn

# Update values.yaml with this ARN in serviceAccount.annotations
```

### 6. Deploy the Helm Chart

```bash
# Install the chart
helm install dag-runner . -f values.yaml

# Or upgrade if already installed
helm upgrade dag-runner . -f values.yaml
```

### 7. Verify Deployment

```bash
# Check pod status
kubectl get pods -l app=dag-runner

# Check service account
kubectl get serviceaccount dag-runner -o yaml

# Check ingress (if enabled)
kubectl get ingress

# Check logs
kubectl logs -l app=dag-runner
```

## Configuration Details

### Service Account & ECR Access

The chart creates a Kubernetes service account with IAM role annotation for ECR access:

```yaml
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/dag-swarm-k8s-ecr-pull-role"
```

### Database Connections

Database connections use Kubernetes secrets created by terraform:

- **RDS (PostgreSQL)**: `dag-swarm-rds-credentials` secret
- **DocumentDB (MongoDB)**: `dag-swarm-docdb-credentials` secret

### Environment Variables

The chart automatically loads database credentials from secrets:

```yaml
envFromSecrets:
  - dag-swarm-rds-credentials # Contains DATABASE_URL
  - dag-swarm-docdb-credentials # Contains MONGO_URI
```

## Troubleshooting

### ECR Pull Issues

If pods can't pull images from ECR:

1. Verify IAM role is properly attached:

   ```bash
   kubectl describe serviceaccount dag-runner
   ```

2. Check if role has ECR permissions:
   ```bash
   aws iam get-role --role-name dag-swarm-k8s-ecr-pull-role
   ```

### Database Connection Issues

If pods can't connect to databases:

1. Verify secrets exist:

   ```bash
   kubectl get secrets
   kubectl describe secret dag-swarm-rds-credentials
   kubectl describe secret dag-swarm-docdb-credentials
   ```

2. Check secret contents:

   ```bash
   kubectl get secret dag-swarm-rds-credentials -o yaml
   ```

3. Verify database endpoints are accessible from EKS:
   ```bash
   # Get database endpoints from terraform
   terraform output rds_cluster_endpoint
   terraform output documentdb_cluster_endpoint
   ```

### Ingress Issues

If ingress is not working:

1. Verify AWS Load Balancer Controller is installed:

   ```bash
   kubectl get deployment -n kube-system aws-load-balancer-controller
   ```

2. Check ingress status:

   ```bash
   kubectl describe ingress dag-runner
   ```

3. Check ALB creation in AWS console

## Terraform Outputs Reference

Useful terraform outputs for debugging:

```bash
# Infrastructure
terraform output cluster_endpoint
terraform output vpc_id
terraform output private_subnet_ids

# IAM roles
terraform output k8s_ecr_pull_role_arn
terraform output eks_ecr_pull_role_arn

# Databases
terraform output rds_cluster_endpoint
terraform output documentdb_cluster_endpoint

# Secrets
terraform output -raw kubernetes_secret_manifest
terraform output -raw documentdb_kubernetes_secret_manifest
```

## Scaling Configuration

KEDA autoscaling is configured with:

- **Max Replicas**: 5
- **Scale Down Period**: 300 seconds
- **Target Pending Requests**: 5

Adjust these values in `values.yaml` as needed for your workload.
