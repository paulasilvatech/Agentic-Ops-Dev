#!/bin/bash

# Azure Observability Workshop - Infrastructure Deployment Script
# This script deploys all Azure infrastructure components for the workshop

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if subscription ID is provided
if [ $# -eq 0 ]; then
    error "Please provide your Azure subscription ID as an argument: ./deploy-infrastructure.sh <subscription-id>"
fi

SUBSCRIPTION_ID=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

log "Starting Azure Observability Workshop Infrastructure Deployment"
log "Subscription ID: $SUBSCRIPTION_ID"
log "Project Root: $PROJECT_ROOT"

# Validate Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# Validate Terraform
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed. Please install it from https://www.terraform.io/downloads.html"
fi

# Validate kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed. Please install it from https://kubernetes.io/docs/tasks/tools/"
fi

# Login to Azure
log "Logging into Azure..."
if ! az account show &> /dev/null; then
    az login
fi

# Set subscription
log "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION_ID"

# Verify subscription
CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]; then
    error "Failed to set subscription. Current: $CURRENT_SUB, Expected: $SUBSCRIPTION_ID"
fi

log "Successfully set Azure subscription: $SUBSCRIPTION_ID"

# Initialize Terraform
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
log "Initializing Terraform in $TERRAFORM_DIR..."

cd "$TERRAFORM_DIR"

# Create terraform.tfvars file
log "Creating terraform.tfvars file..."
cat > terraform.tfvars << EOF
subscription_id = "$SUBSCRIPTION_ID"
location = "East US 2"
environment = "workshop"
EOF

# Initialize Terraform
terraform init

# Validate Terraform configuration
log "Validating Terraform configuration..."
terraform validate

# Plan Terraform deployment
log "Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply Terraform deployment
log "Applying Terraform deployment..."
terraform apply tfplan

# Get outputs
log "Retrieving Terraform outputs..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)
ACR_NAME=$(terraform output -raw container_registry_name)
LOG_ANALYTICS_ID=$(terraform output -raw log_analytics_workspace_id)
APP_INSIGHTS_KEY=$(terraform output -raw application_insights_instrumentation_key)

log "Infrastructure deployment completed successfully!"
log "Resource Group: $RESOURCE_GROUP"
log "AKS Cluster: $AKS_CLUSTER"
log "Container Registry: $ACR_NAME"

# Configure kubectl
log "Configuring kubectl for AKS cluster..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing

# Verify kubectl connection
log "Verifying kubectl connection..."
kubectl cluster-info

# Save important values to a file for other scripts
OUTPUTS_FILE="$PROJECT_ROOT/workshop-outputs.env"
log "Saving deployment outputs to $OUTPUTS_FILE..."

cat > "$OUTPUTS_FILE" << EOF
# Azure Observability Workshop - Deployment Outputs
# Generated on $(date)

export SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export RESOURCE_GROUP="$RESOURCE_GROUP"
export AKS_CLUSTER="$AKS_CLUSTER"
export ACR_NAME="$ACR_NAME"
export LOG_ANALYTICS_ID="$LOG_ANALYTICS_ID"
export APP_INSIGHTS_KEY="$APP_INSIGHTS_KEY"
export KUBECONFIG="$HOME/.kube/config"
EOF

log "Deployment outputs saved to $OUTPUTS_FILE"
log "Source this file in your shell: source $OUTPUTS_FILE"

# Deploy Kubernetes monitoring stack
log "Deploying Kubernetes monitoring stack..."
"$SCRIPT_DIR/deploy-monitoring.sh"

log "Infrastructure deployment completed successfully!"
log ""
log "Next steps:"
log "1. Source the outputs file: source $OUTPUTS_FILE"
log "2. Deploy applications: $SCRIPT_DIR/deploy-applications.sh"
log "3. Configure Istio service mesh: $SCRIPT_DIR/deploy-istio.sh"
log ""
log "Access URLs (after port-forwarding):"
log "- Grafana: http://localhost:3000 (admin/ObservabilityWorkshop@2024!)"
log "- Prometheus: http://localhost:9090"
log ""
log "Port forwarding commands:"
log "kubectl port-forward -n monitoring svc/grafana 3000:3000"
log "kubectl port-forward -n monitoring svc/prometheus 9090:9090"