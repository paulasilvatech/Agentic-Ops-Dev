#!/bin/bash

# Port forward Grafana for workshop access
# This script sets up port forwarding for Grafana UI access

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

log "🎨 Starting Grafana port forwarding..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    warn "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if Grafana pod exists
if ! kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana &> /dev/null; then
    warn "Grafana pod not found in monitoring namespace"
    echo "Please ensure the monitoring stack is deployed first:"
    echo "  ./deploy-monitoring.sh"
    exit 1
fi

# Wait for Grafana pod to be ready
log "Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Start port forwarding
log "Starting port forwarding for Grafana..."
log "🌐 Grafana will be accessible at: http://localhost:3000"
log "📋 Default credentials: admin / ObservabilityWorkshop@2024!"
log ""
log "💡 To stop port forwarding, press Ctrl+C"
log ""

# Port forward (this will run in foreground)
kubectl port-forward -n monitoring svc/grafana 3000:3000

# This line will only execute if port-forward is stopped
log "Grafana port forwarding stopped"