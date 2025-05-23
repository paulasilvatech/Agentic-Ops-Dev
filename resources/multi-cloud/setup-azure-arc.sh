#!/bin/bash

# Azure Arc Setup Script for Multi-Cloud Container Management
# This script configures Azure Arc for Kubernetes clusters across multiple clouds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
CLUSTER_NAME=""
RESOURCE_GROUP=""
LOCATION="eastus2"
CLOUD_PROVIDER=""
ENABLE_GITOPS="true"
ENABLE_MONITORING="true"
ENABLE_DEFENDER="true"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
usage() {
    echo "Usage: $0 --cluster-name <name> --resource-group <rg> --cloud <azure|aws|gcp> [options]"
    echo ""
    echo "Required:"
    echo "  --cluster-name     Name of the Kubernetes cluster"
    echo "  --resource-group   Azure resource group name"
    echo "  --cloud           Cloud provider (azure, aws, gcp)"
    echo ""
    echo "Options:"
    echo "  --location        Azure region (default: eastus2)"
    echo "  --enable-gitops   Enable GitOps (default: true)"
    echo "  --enable-monitoring Enable Azure Monitor (default: true)"
    echo "  --enable-defender Enable Microsoft Defender (default: true)"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --cloud)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        --location)
            LOCATION="$2"
            shift 2
            ;;
        --enable-gitops)
            ENABLE_GITOPS="$2"
            shift 2
            ;;
        --enable-monitoring)
            ENABLE_MONITORING="$2"
            shift 2
            ;;
        --enable-defender)
            ENABLE_DEFENDER="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$CLUSTER_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$CLOUD_PROVIDER" ]; then
    print_error "Missing required parameters"
    usage
fi

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        exit 1
    }
    
    # Check cloud-specific CLIs
    case $CLOUD_PROVIDER in
        aws)
            if ! command -v aws &> /dev/null; then
                print_error "AWS CLI is not installed"
                exit 1
            fi
            ;;
        gcp)
            if ! command -v gcloud &> /dev/null; then
                print_error "Google Cloud SDK is not installed"
                exit 1
            fi
            ;;
    esac
    
    print_success "All prerequisites met"
}

# Login to Azure
azure_login() {
    print_info "Checking Azure authentication..."
    
    if ! az account show &>/dev/null; then
        print_info "Please login to Azure..."
        az login
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_success "Logged in to Azure subscription: $SUBSCRIPTION_ID"
}

# Create resource group if not exists
create_resource_group() {
    print_info "Creating resource group if not exists..."
    
    if az group show --name $RESOURCE_GROUP &>/dev/null; then
        print_info "Resource group $RESOURCE_GROUP already exists"
    else
        az group create --name $RESOURCE_GROUP --location $LOCATION
        print_success "Resource group $RESOURCE_GROUP created"
    fi
}

# Register Azure providers
register_providers() {
    print_info "Registering required Azure providers..."
    
    providers=(
        "Microsoft.Kubernetes"
        "Microsoft.KubernetesConfiguration"
        "Microsoft.ExtendedLocation"
        "Microsoft.Monitor"
        "Microsoft.OperationsManagement"
        "Microsoft.Security"
    )
    
    for provider in "${providers[@]}"; do
        print_info "Registering $provider..."
        az provider register --namespace $provider --wait
    done
    
    print_success "All providers registered"
}

# Install Azure Arc extensions
install_arc_extensions() {
    print_info "Installing Azure Arc CLI extensions..."
    
    extensions=(
        "connectedk8s"
        "k8s-configuration"
        "k8s-extension"
        "customlocation"
    )
    
    for ext in "${extensions[@]}"; do
        az extension add --name $ext --upgrade --yes
    done
    
    print_success "Azure Arc extensions installed"
}

# Get cluster credentials based on cloud provider
get_cluster_credentials() {
    print_info "Getting cluster credentials for $CLOUD_PROVIDER..."
    
    case $CLOUD_PROVIDER in
        azure)
            az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
            ;;
        aws)
            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
            ;;
        gcp)
            gcloud container clusters get-credentials $CLUSTER_NAME --zone $GCP_ZONE --project $GCP_PROJECT
            ;;
        *)
            print_error "Unsupported cloud provider: $CLOUD_PROVIDER"
            exit 1
            ;;
    esac
    
    # Verify connection
    kubectl cluster-info
    print_success "Connected to cluster $CLUSTER_NAME"
}

# Connect cluster to Azure Arc
connect_to_arc() {
    print_info "Connecting cluster $CLUSTER_NAME to Azure Arc..."
    
    # Create Arc namespace
    kubectl create namespace azure-arc --dry-run=client -o yaml | kubectl apply -f -
    
    # Connect cluster
    az connectedk8s connect \
        --name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --tags "Environment=Production" "CloudProvider=$CLOUD_PROVIDER" \
        --correlation-id "$(uuidgen)"
    
    # Wait for connection
    print_info "Waiting for Arc connection to be ready..."
    az connectedk8s show \
        --name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --query "connectivityStatus" -o tsv
    
    print_success "Cluster connected to Azure Arc"
}

# Enable GitOps
enable_gitops() {
    if [ "$ENABLE_GITOPS" != "true" ]; then
        print_info "Skipping GitOps configuration"
        return
    fi
    
    print_info "Enabling GitOps on Arc-enabled cluster..."
    
    # Create GitOps configuration
    cat > /tmp/gitops-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: gitops-config
  namespace: azure-arc
data:
  repository.url: "https://github.com/Azure-Samples/arc-k8s-demo"
  repository.branch: "main"
  repository.path: "./releases/prod"
  sync.policy: "automated"
  sync.prune: "true"
  sync.selfHeal: "true"
EOF
    
    kubectl apply -f /tmp/gitops-config.yaml
    
    # Install Flux extension
    az k8s-extension create \
        --name flux \
        --cluster-name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --cluster-type connectedClusters \
        --extension-type microsoft.flux \
        --scope cluster \
        --release-namespace flux-system \
        --configuration-settings multiTenancy.enforce=false
    
    print_success "GitOps enabled with Flux"
}

# Enable Azure Monitor
enable_azure_monitor() {
    if [ "$ENABLE_MONITORING" != "true" ]; then
        print_info "Skipping Azure Monitor configuration"
        return
    fi
    
    print_info "Enabling Azure Monitor for containers..."
    
    # Create Log Analytics workspace if not exists
    WORKSPACE_NAME="law-${CLUSTER_NAME}"
    WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group $RESOURCE_GROUP \
        --workspace-name $WORKSPACE_NAME \
        --query id -o tsv 2>/dev/null || echo "")
    
    if [ -z "$WORKSPACE_ID" ]; then
        print_info "Creating Log Analytics workspace..."
        WORKSPACE_ID=$(az monitor log-analytics workspace create \
            --resource-group $RESOURCE_GROUP \
            --workspace-name $WORKSPACE_NAME \
            --location $LOCATION \
            --query id -o tsv)
    fi
    
    # Install Azure Monitor extension
    az k8s-extension create \
        --name azuremonitor-containers \
        --cluster-name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --cluster-type connectedClusters \
        --extension-type Microsoft.AzureMonitor.Containers \
        --configuration-settings logAnalyticsWorkspaceResourceID=$WORKSPACE_ID
    
    # Create monitoring namespace
    kubectl create namespace azure-monitor --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy container insights
    cat > /tmp/container-insights.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: container-azm-ms-agentconfig
  namespace: azure-monitor
data:
  schema-version: v1
  config-version: ver1
  log-data-collection-settings: |-
    [log_collection_settings]
       [log_collection_settings.stdout]
          enabled = true
          max_stdout_entries_per_second = 100
       [log_collection_settings.stderr]
          enabled = true
          max_stderr_entries_per_second = 100
       [log_collection_settings.env_var]
          enabled = true
  prometheus-data-collection-settings: |-
    [prometheus_data_collection_settings.cluster]
        interval = "1m"
        monitor_kubernetes_pods = true
        monitor_kubernetes_pods_namespaces = ["default", "kube-system", "applications", "monitoring"]
    [prometheus_data_collection_settings.node]
        interval = "1m"
EOF
    
    kubectl apply -f /tmp/container-insights.yaml
    
    print_success "Azure Monitor enabled"
}

# Enable Microsoft Defender
enable_defender() {
    if [ "$ENABLE_DEFENDER" != "true" ]; then
        print_info "Skipping Microsoft Defender configuration"
        return
    fi
    
    print_info "Enabling Microsoft Defender for cloud..."
    
    # Enable Defender for containers
    az security pricing create \
        --name Containers \
        --tier Standard
    
    # Install Defender extension
    az k8s-extension create \
        --name microsoft-defender \
        --cluster-name $CLUSTER_NAME \
        --resource-group $RESOURCE_GROUP \
        --cluster-type connectedClusters \
        --extension-type microsoft.azuredefender.kubernetes \
        --configuration-settings logAnalyticsWorkspaceResourceId=$WORKSPACE_ID
    
    # Create security policies
    cat > /tmp/security-policies.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: defender-security-policies
  namespace: azure-arc
data:
  policies: |
    - name: "container-no-privilege"
      description: "Containers should not run privileged"
      severity: "high"
      enabled: true
    - name: "container-readonly-root"
      description: "Container root filesystem should be read-only"
      severity: "medium"
      enabled: true
    - name: "pod-security-policy"
      description: "Pods should follow security best practices"
      severity: "high"
      enabled: true
EOF
    
    kubectl apply -f /tmp/security-policies.yaml
    
    print_success "Microsoft Defender enabled"
}

# Configure multi-cloud networking
configure_networking() {
    print_info "Configuring multi-cloud networking..."
    
    # Apply network policies
    cat > /tmp/network-policies.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: arc-agent-network-policy
  namespace: azure-arc
spec:
  podSelector:
    matchLabels:
      app: azure-arc-agent
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: azure-arc
    - namespaceSelector:
        matchLabels:
          name: azure-monitor
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 9090
EOF
    
    kubectl apply -f /tmp/network-policies.yaml
    
    print_success "Network policies configured"
}

# Setup observability integration
setup_observability() {
    print_info "Setting up observability integration..."
    
    # Create service monitors for Arc agents
    cat > /tmp/arc-service-monitors.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: azure-arc-agents
  namespace: azure-arc
spec:
  selector:
    matchLabels:
      app: azure-arc-agent
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: arc-flux-system
  namespace: flux-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: flux
  endpoints:
  - port: http-prom
    interval: 30s
    path: /metrics
EOF
    
    kubectl apply -f /tmp/arc-service-monitors.yaml
    
    # Create Grafana dashboards for Arc
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: arc-grafana-dashboards
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  azure-arc-overview.json: |
    {
      "dashboard": {
        "title": "Azure Arc Multi-Cloud Overview",
        "uid": "arc-overview",
        "tags": ["azure-arc", "multi-cloud"],
        "panels": [
          {
            "title": "Connected Clusters",
            "type": "stat",
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
            "targets": [
              {
                "expr": "count(up{job=\"azure-arc-agent\"})",
                "refId": "A"
              }
            ]
          },
          {
            "title": "GitOps Sync Status",
            "type": "table",
            "gridPos": {"h": 8, "w": 18, "x": 6, "y": 0},
            "targets": [
              {
                "expr": "flux_sync_status",
                "format": "table",
                "instant": true,
                "refId": "A"
              }
            ]
          }
        ]
      }
    }
EOF
    
    print_success "Observability integration configured"
}

# Generate connection report
generate_report() {
    print_info "Generating Arc connection report..."
    
    REPORT_FILE="arc-connection-report-${CLUSTER_NAME}.md"
    
    cat > $REPORT_FILE << EOF
# Azure Arc Connection Report

**Date:** $(date)
**Cluster Name:** $CLUSTER_NAME
**Cloud Provider:** $CLOUD_PROVIDER
**Resource Group:** $RESOURCE_GROUP
**Location:** $LOCATION

## Connection Status

\`\`\`
$(az connectedk8s show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --output table)
\`\`\`

## Enabled Features

- GitOps: $ENABLE_GITOPS
- Azure Monitor: $ENABLE_MONITORING
- Microsoft Defender: $ENABLE_DEFENDER

## Extensions Installed

\`\`\`
$(az k8s-extension list --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --cluster-type connectedClusters --output table)
\`\`\`

## Next Steps

1. Configure GitOps repositories for application deployment
2. Set up Azure Policy for governance
3. Configure cost management and billing
4. Implement RBAC and security policies
5. Set up monitoring alerts and dashboards

## Useful Commands

\`\`\`bash
# View Arc agents
kubectl get pods -n azure-arc

# Check GitOps configurations
kubectl get gitconfigs -A

# View monitoring metrics
kubectl get servicemonitors -A

# Check security policies
kubectl get networkpolicies -A
\`\`\`
EOF
    
    print_success "Report generated: $REPORT_FILE"
}

# Main execution
main() {
    print_info "Starting Azure Arc setup for $CLUSTER_NAME on $CLOUD_PROVIDER..."
    
    check_prerequisites
    azure_login
    create_resource_group
    register_providers
    install_arc_extensions
    get_cluster_credentials
    connect_to_arc
    enable_gitops
    enable_azure_monitor
    enable_defender
    configure_networking
    setup_observability
    generate_report
    
    print_success "Azure Arc setup completed successfully!"
    print_info "Cluster $CLUSTER_NAME is now Arc-enabled and ready for multi-cloud management"
    print_info "Access the Azure Portal to manage your Arc-enabled cluster"
}

# Run main function
main 