#!/bin/bash

# Port forward Jaeger for workshop access
# This script sets up port forwarding for Jaeger tracing UI access

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

log "Starting Jaeger port forwarding..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    warn "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Check if Jaeger pod exists
if ! kubectl get pod -n monitoring -l app.kubernetes.io/name=jaeger &> /dev/null; then
    warn "Jaeger pod not found in monitoring namespace"
    echo "Please ensure the monitoring stack is deployed first:"
    echo "  ./deploy-monitoring.sh"
    exit 1
fi

# Wait for Jaeger pod to be ready
log "Waiting for Jaeger pod to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=jaeger -n monitoring --timeout=300s

# Start port forwarding
log "Starting port forwarding for Jaeger..."
log "Jaeger will be accessible at: http://localhost:16686"
log "Use the web UI to explore distributed traces"
log ""
log "Features to explore:"
log "  - Search traces by service name"
log "  - View trace timelines and spans"
log "  - Analyze service dependencies"
log "  - Compare trace performance"
log ""
log "To stop port forwarding, press Ctrl+C"
log ""

# Port forward (this will run in foreground)
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686

# This line will only execute if port-forward is stopped
log "Jaeger port forwarding stopped"