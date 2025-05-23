#!/bin/bash

# Azure Observability Workshop - Complete Deployment Script
# This is the main script that deploys the entire workshop environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║           Azure Observability Workshop Deployment               ║
    ║                                                                  ║
    ║    Complete automation for Azure Monitor, AKS, Prometheus,      ║
    ║              Grafana, Jaeger, and sample applications           ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

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

step() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] STEP: $1${NC}"
}

# Help function
show_help() {
    echo "Azure Observability Workshop Deployment Script"
    echo ""
    echo "Usage: $0 <subscription-id> [options]"
    echo ""
    echo "Arguments:"
    echo "  subscription-id    Your Azure subscription ID (required)"
    echo ""
    echo "Options:"
    echo "  --skip-infrastructure    Skip infrastructure deployment (useful for redeployment)"
    echo "  --skip-monitoring        Skip monitoring stack deployment"
    echo "  --skip-applications      Skip application deployment"
    echo "  --skip-istio            Skip Istio service mesh deployment"
    echo "  --quick                 Quick deployment (minimal components)"
    echo "  --help, -h              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 12345678-1234-1234-1234-123456789012"
    echo "  $0 12345678-1234-1234-1234-123456789012 --skip-infrastructure"
    echo "  $0 12345678-1234-1234-1234-123456789012 --quick"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and logged in"
    echo "  - Terraform installed"
    echo "  - kubectl installed"
    echo "  - Docker installed"
    echo ""
}

# Parse command line arguments
SUBSCRIPTION_ID=""
SKIP_INFRASTRUCTURE=false
SKIP_MONITORING=false
SKIP_APPLICATIONS=false
SKIP_ISTIO=false
QUICK_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-infrastructure)
            SKIP_INFRASTRUCTURE=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --skip-applications)
            SKIP_APPLICATIONS=true
            shift
            ;;
        --skip-istio)
            SKIP_ISTIO=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        -*)
            error "Unknown option $1"
            ;;
        *)
            if [ -z "$SUBSCRIPTION_ID" ]; then
                SUBSCRIPTION_ID="$1"
            else
                error "Multiple subscription IDs provided"
            fi
            shift
            ;;
    esac
done

# Check if subscription ID is provided
if [ -z "$SUBSCRIPTION_ID" ]; then
    print_banner
    echo ""
    error "Please provide your Azure subscription ID. Use --help for more information."
fi

# Validate subscription ID format
if ! [[ $SUBSCRIPTION_ID =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    error "Invalid subscription ID format. Expected format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
fi

# Set quick mode defaults
if [ "$QUICK_MODE" = true ]; then
    SKIP_ISTIO=true
    info "Quick mode enabled - Istio deployment will be skipped"
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

print_banner

log "Starting Azure Observability Workshop deployment"
log "Subscription ID: $SUBSCRIPTION_ID"
log "Project Root: $PROJECT_ROOT"

# Check prerequisites
step "Checking prerequisites..."

info "Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

info "Checking Terraform..."
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed. Please install it from https://www.terraform.io/downloads.html"
fi

info "Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed. Please install it from https://kubernetes.io/docs/tasks/tools/"
fi

info "Checking Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install it from https://docs.docker.com/get-docker/"
fi

log "All prerequisites satisfied!"

# Check if user is logged into Azure
info "Checking Azure login status..."
if ! az account show &> /dev/null; then
    warn "Not logged into Azure. Please login when prompted."
    az login
fi

# Start deployment timer
START_TIME=$(date +%s)

# Step 1: Deploy Infrastructure
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    step "1/4 - Deploying Azure Infrastructure (Terraform)"
    log "This will create: Resource Groups, AKS cluster, Log Analytics, Application Insights, Key Vault, ACR"
    
    chmod +x "$SCRIPT_DIR/scripts/deploy-infrastructure.sh"
    "$SCRIPT_DIR/scripts/deploy-infrastructure.sh" "$SUBSCRIPTION_ID"
    
    log "Infrastructure deployment completed!"
else
    warn "Skipping infrastructure deployment"
fi

# Step 2: Deploy Monitoring Stack
if [ "$SKIP_MONITORING" = false ]; then
    step "2/4 - Deploying Monitoring Stack"
    log "This will deploy: Prometheus, Grafana, Jaeger, AlertManager"
    
    chmod +x "$SCRIPT_DIR/scripts/deploy-monitoring.sh"
    "$SCRIPT_DIR/scripts/deploy-monitoring.sh"
    
    log "Monitoring stack deployment completed!"
else
    warn "Skipping monitoring stack deployment"
fi

# Step 3: Deploy Applications
if [ "$SKIP_APPLICATIONS" = false ]; then
    step "3/4 - Building and Deploying Applications"
    log "This will build and deploy: .NET Sample App, User Service, Order Service"
    
    chmod +x "$SCRIPT_DIR/scripts/deploy-applications.sh"
    "$SCRIPT_DIR/scripts/deploy-applications.sh"
    
    log "Applications deployment completed!"
else
    warn "Skipping applications deployment"
fi

# Step 4: Deploy Istio Service Mesh (optional)
if [ "$SKIP_ISTIO" = false ]; then
    step "4/4 - Deploying Istio Service Mesh"
    log "This will deploy: Istio control plane, ingress gateway, traffic management"
    
    if [ -f "$SCRIPT_DIR/scripts/deploy-istio.sh" ]; then
        chmod +x "$SCRIPT_DIR/scripts/deploy-istio.sh"
        "$SCRIPT_DIR/scripts/deploy-istio.sh"
        log "Istio deployment completed!"
    else
        warn "Istio deployment script not found, skipping..."
    fi
else
    warn "Skipping Istio service mesh deployment"
fi

# Calculate deployment time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Final summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    DEPLOYMENT COMPLETED!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Total deployment time: ${MINUTES}m ${SECONDS}s"

# Load outputs
OUTPUTS_FILE="$PROJECT_ROOT/workshop-outputs.env"
if [ -f "$OUTPUTS_FILE" ]; then
    source "$OUTPUTS_FILE"
    
    echo -e "${BLUE}Deployed Resources:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "• Resource Group: ${RESOURCE_GROUP:-Unknown}"
    echo "• AKS Cluster: ${AKS_CLUSTER:-Unknown}"
    echo "• Container Registry: ${ACR_NAME:-Unknown}"
    echo "• Location: East US 2"
    echo ""
fi

echo -e "${BLUE}Deployed Components:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    echo "✓ Azure Infrastructure (Terraform)"
    echo "  - AKS Cluster with monitoring"
    echo "  - Log Analytics Workspace"
    echo "  - Application Insights"
    echo "  - Azure Container Registry"
    echo "  - Key Vault"
fi

if [ "$SKIP_MONITORING" = false ]; then
    echo "✓ Monitoring Stack"
    echo "  - Prometheus (metrics collection)"
    echo "  - Grafana (dashboards)"
    echo "  - Jaeger (distributed tracing)"
fi

if [ "$SKIP_APPLICATIONS" = false ]; then
    echo "✓ Sample Applications"
    echo "  - .NET Sample Application"
    echo "  - User Service (microservice)"
    echo "  - Order Service (microservice)"
fi

if [ "$SKIP_ISTIO" = false ]; then
    echo "✓ Istio Service Mesh"
    echo "  - Istio control plane"
    echo "  - Traffic management"
    echo "  - Security policies"
fi

echo ""
echo -e "${BLUE}Access URLs (requires port-forwarding):${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Grafana:    http://localhost:3000 (admin/ObservabilityWorkshop@2024!)"
echo "• Prometheus: http://localhost:9090"
echo "• Jaeger:     http://localhost:16686"
echo "• Main App:   http://localhost:8080"
echo ""

echo -e "${BLUE}Quick Start Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "# Source environment variables:"
echo "source $OUTPUTS_FILE"
echo ""
echo "# Start port-forwarding for UIs:"
echo "$SCRIPT_DIR/scripts/helpers/port-forward-grafana.sh &"
echo "$SCRIPT_DIR/scripts/helpers/port-forward-prometheus.sh &"
echo "$SCRIPT_DIR/scripts/helpers/port-forward-jaeger.sh &"
echo ""
echo "# Generate load for testing:"
echo "$SCRIPT_DIR/scripts/helpers/generate-load.sh"
echo ""
echo "# View running pods:"
echo "kubectl get pods --all-namespaces"
echo ""

echo -e "${BLUE}Workshop Sections Covered:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Part 1: Azure Monitor & Application Insights"
echo "• Part 2: Dashboards & Intelligent Alerting"
echo "• Part 3: Microservices & Distributed Tracing"
echo "• Part 4: CI/CD Integration"
echo "• Part 5: Enterprise Infrastructure"
echo "• Part 6: Service Mesh Observability"
echo "• Part 7: Multi-cloud Integration"
echo "• Part 8: Security & Compliance"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Follow the workshop documentation in the docs/ directory"
echo "2. Access Grafana and explore the pre-configured dashboards"
echo "3. Run the load generator to see metrics in action"
echo "4. Experiment with the KQL queries in Azure Monitor"
echo "5. Explore distributed traces in Jaeger"
echo ""

echo -e "${GREEN}Happy learning!${NC}"
echo ""

# Cleanup function for graceful exit
cleanup() {
    log "Cleaning up background processes..."
    # Kill any background port-forwarding processes
    pkill -f "kubectl port-forward" 2>/dev/null || true
}

trap cleanup EXIT