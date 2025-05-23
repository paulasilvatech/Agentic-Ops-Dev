#!/bin/bash

# Azure Observability Workshop - Quick Start Script
# This script provides a simplified entry point for workshop participants

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
    ║              Azure Observability Workshop                       ║
    ║                     Quick Start                                  ║
    ║                                                                  ║
    ║        Complete deployment in just a few minutes!              ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

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
    echo "Azure Observability Workshop - Quick Start"
    echo ""
    echo "This script helps you get started with the workshop quickly."
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  deploy <subscription-id>    Deploy complete workshop environment"
    echo "  start                       Start workshop environment (port forwarding)"
    echo "  status                      Check deployment status"
    echo "  cleanup                     Clean up all resources"
    echo "  help                        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy 12345678-1234-1234-1234-123456789012"
    echo "  $0 start"
    echo "  $0 status"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure subscription and CLI logged in"
    echo "  - Terraform, kubectl, Docker installed"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("Azure CLI")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("Docker")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
    fi
    
    log "All prerequisites satisfied!"
}

# Deploy function
deploy_workshop() {
    local subscription_id=$1
    
    if [ -z "$subscription_id" ]; then
        error "Please provide your Azure subscription ID"
    fi
    
    step "Starting workshop deployment..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Run the main deployment script
    log "Running complete deployment script..."
    chmod +x "$SCRIPT_DIR/deploy-workshop.sh"
    "$SCRIPT_DIR/deploy-workshop.sh" "$subscription_id"
    
    log "Workshop deployment completed!"
    
    # Automatically start the environment
    log "Starting workshop environment..."
    start_environment
}

# Start environment function
start_environment() {
    step "Starting workshop environment..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Check if deployment exists
    if [ ! -f "$SCRIPT_DIR/workshop-outputs.env" ]; then
        warn "Workshop not deployed yet. Please run deployment first:"
        echo "  $0 deploy <subscription-id>"
        exit 1
    fi
    
    # Start the environment
    log "Starting all services..."
    chmod +x "$SCRIPT_DIR/scripts/helpers/start-workshop-env.sh"
    "$SCRIPT_DIR/scripts/helpers/start-workshop-env.sh"
}

# Status check function
check_status() {
    step "Checking workshop deployment status..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Check if outputs file exists
    if [ ! -f "$SCRIPT_DIR/workshop-outputs.env" ]; then
        warn "Workshop not deployed"
        echo "Run: $0 deploy <subscription-id>"
        exit 1
    fi
    
    # Source outputs
    source "$SCRIPT_DIR/workshop-outputs.env"
    
    log "Workshop is deployed!"
    echo ""
    echo -e "${BLUE}Deployment Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "• Subscription: ${SUBSCRIPTION_ID:-Unknown}"
    echo "• Resource Group: ${RESOURCE_GROUP:-Unknown}"
    echo "• AKS Cluster: ${AKS_CLUSTER:-Unknown}"
    echo "• Container Registry: ${ACR_NAME:-Unknown}"
    echo ""
    
    # Check if kubectl is configured
    if kubectl cluster-info &> /dev/null; then
        log "kubectl is configured"
        
        # Check cluster status
        echo -e "${BLUE}Cluster Status:${NC}"
        kubectl get nodes --no-headers | while read line; do
            echo "• $line"
        done
        echo ""
        
        # Check namespaces
        echo -e "${BLUE}Namespaces:${NC}"
        kubectl get namespaces --no-headers | grep -E "(monitoring|applications|istio)" | while read line; do
            echo "• $line"
        done
        echo ""
        
    else
        warn "kubectl not configured for this cluster"
        echo "Run: az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER"
    fi
    
    echo -e "${BLUE}Next Steps:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "• Start environment: $0 start"
    echo "• Access Grafana: http://localhost:3000 (after starting)"
    echo "• Follow workshop: docs/observability_workshop_part-01.md"
}

# Cleanup function
cleanup_workshop() {
    step "Cleaning up workshop resources..."
    
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Check if outputs file exists
    if [ ! -f "$SCRIPT_DIR/workshop-outputs.env" ]; then
        warn "No deployment found to clean up"
        exit 0
    fi
    
    # Source outputs
    source "$SCRIPT_DIR/workshop-outputs.env"
    
    # Confirm deletion
    echo -e "${YELLOW}This will delete ALL workshop resources including:${NC}"
    echo "• Resource Group: ${RESOURCE_GROUP:-Unknown}"
    echo "• AKS Cluster: ${AKS_CLUSTER:-Unknown}"
    echo "• All data, dashboards, and configurations"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log "Cleanup cancelled"
        exit 0
    fi
    
    # Kill any running port forwards
    log "Stopping port forwarding..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    
    # Delete resource group (this will delete everything)
    if [ -n "${RESOURCE_GROUP:-}" ]; then
        log "Deleting resource group: $RESOURCE_GROUP"
        az group delete --name "$RESOURCE_GROUP" --yes --no-wait
        log "Resource group deletion initiated"
    fi
    
    # Clean up local files
    if [ -f "$SCRIPT_DIR/workshop-outputs.env" ]; then
        rm "$SCRIPT_DIR/workshop-outputs.env"
        log "Cleaned up local configuration files"
    fi
    
    # Clean up terraform state
    if [ -d "$SCRIPT_DIR/terraform" ]; then
        cd "$SCRIPT_DIR/terraform"
        if [ -f "terraform.tfstate" ]; then
            rm -f terraform.tfstate*
            rm -f tfplan
            log "Cleaned up Terraform state"
        fi
    fi
    
    log "Cleanup completed!"
    log "Note: Resource deletion may take several minutes to complete in Azure"
}

# Main script logic
print_banner

case "${1:-help}" in
    "deploy")
        check_prerequisites
        deploy_workshop "${2:-}"
        ;;
    "start")
        start_environment
        ;;
    "status")
        check_status
        ;;
    "cleanup")
        cleanup_workshop
        ;;
    "help"|*)
        show_help
        exit 0
        ;;
esac