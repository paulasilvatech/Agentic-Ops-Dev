#!/bin/bash

# Port forward Prometheus for workshop access
# This script sets up port forwarding for Prometheus UI access

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

log "Starting Prometheus port forwarding..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    warn "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if Prometheus pod exists
if ! kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus &> /dev/null; then
    warn "Prometheus pod not found in monitoring namespace"
    echo "Please ensure the monitoring stack is deployed first:"
    echo "  ./deploy-monitoring.sh"
    exit 1
fi

# Wait for Prometheus pod to be ready
log "Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Start port forwarding
log "Starting port forwarding for Prometheus..."
log "Prometheus will be accessible at: http://localhost:9090"
log "Use the web UI to explore metrics and run PromQL queries"
log ""
log "Example queries to try:"
log "  - up (show all targets status)"
log "  - rate(http_requests_total[5m]) (request rate)"
log "  - container_memory_usage_bytes (memory usage)"
log ""
log "To stop port forwarding, press Ctrl+C"
log ""

# Port forward (this will run in foreground)
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# This line will only execute if port-forward is stopped
log "Prometheus port forwarding stopped"