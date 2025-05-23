#!/bin/bash

# Start Workshop Environment - All-in-one script
# This script starts all necessary port-forwarding for the workshop environment

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art Banner
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════════════════════════╗
    ║                                                                  ║
    ║              Azure Observability Workshop                       ║
    ║                 Environment Startup                             ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

print_banner

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

log "Starting Azure Observability Workshop Environment"

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    error "kubectl is not configured or cluster is not accessible"
fi

log "Kubernetes cluster is accessible"

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    error "Monitoring namespace not found. Please deploy the monitoring stack first."
fi

log "Monitoring namespace exists"

# Check if applications namespace exists
if ! kubectl get namespace applications &> /dev/null; then
    warn "Applications namespace not found. Some services may not be available."
fi

# Function to start port forwarding in background
start_port_forward() {
    local service=$1
    local namespace=$2
    local local_port=$3
    local remote_port=$4
    local description=$5
    
    # Kill existing port forward if running
    pkill -f "kubectl port-forward.*${service}" 2>/dev/null || true
    sleep 2
    
    # Check if service exists
    if ! kubectl get svc "${service}" -n "${namespace}" &> /dev/null; then
        warn "Service ${service} not found in namespace ${namespace}"
        return 1
    fi
    
    log "Starting port forward for ${description}..."
    kubectl port-forward -n "${namespace}" "svc/${service}" "${local_port}:${remote_port}" &
    
    # Give it a moment to start
    sleep 3
    
    # Verify port forward is working
    if curl -s --connect-timeout 5 "http://localhost:${local_port}" &> /dev/null; then
        log "${description} is accessible at http://localhost:${local_port}"
        return 0
    else
        warn "${description} port forward may not be working properly"
        return 1
    fi
}

# Start all port forwards
log "Starting port forwarding for all services..."

# Grafana (Monitoring Dashboard)
start_port_forward "grafana" "monitoring" "3000" "3000" "Grafana Dashboard"

# Prometheus (Metrics Database)
start_port_forward "prometheus" "monitoring" "9090" "9090" "Prometheus Metrics"

# Jaeger (Distributed Tracing)
if kubectl get svc jaeger-query -n monitoring &> /dev/null; then
    start_port_forward "jaeger-query" "monitoring" "16686" "16686" "Jaeger Tracing"
else
    warn "Jaeger service not found, skipping..."
fi

# Main Application (if deployed)
if kubectl get svc dotnet-sample-app -n applications &> /dev/null; then
    start_port_forward "dotnet-sample-app" "applications" "8080" "80" "Sample Application"
else
    warn "Sample application not found, skipping..."
fi

# AlertManager (if deployed)
if kubectl get svc alertmanager -n monitoring &> /dev/null; then
    start_port_forward "alertmanager" "monitoring" "9093" "9093" "AlertManager"
fi

log "Workshop environment is ready!"
echo ""

# Display access information
echo -e "${BLUE}Access URLs:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Grafana Dashboard:     http://localhost:3000"
echo "  └── Credentials: admin / ObservabilityWorkshop@2024!"
echo "Prometheus Metrics:    http://localhost:9090"
echo "Jaeger Tracing:        http://localhost:16686"
echo "Sample Application:    http://localhost:8080"
echo "AlertManager:          http://localhost:9093"
echo ""

echo -e "${BLUE}Useful Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Generate load: ${SCRIPT_DIR}/generate-load.sh"
echo "• View pods:     kubectl get pods --all-namespaces"
echo "• View logs:     kubectl logs -n applications deployment/dotnet-sample-app -f"
echo "• Stop all:      pkill -f 'kubectl port-forward'"
echo ""

echo -e "${BLUE}Workshop Documentation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Introduction:  docs/observability_introduction.md"
echo "• Part 1:        docs/observability_workshop_part-01.md"
echo "• Part 2:        docs/observability_workshop_part-02.md"
echo "• Troubleshoot:  docs/observability_troubleshooting_guide.md"
echo ""

echo -e "${YELLOW}Tips:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Wait a few minutes for metrics to start appearing"
echo "• Generate some traffic to see interesting data"
echo "• All services are running in background"
echo "• Press Ctrl+C to stop this script (services will continue)"
echo ""

# Cleanup function
cleanup() {
    log "Cleaning up port forwarding processes..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    log "Cleanup completed"
}

# Handle script termination
trap cleanup EXIT

# Keep script running
log "Workshop environment is running. Press Ctrl+C to stop all port forwards."
while true; do
    sleep 30
    # Check if any port forwards died and restart them
    if ! pgrep -f "kubectl port-forward.*grafana" > /dev/null; then
        warn "Grafana port forward died, restarting..."
        start_port_forward "grafana" "monitoring" "3000" "3000" "Grafana Dashboard"
    fi
done