#!/bin/bash

# Azure Observability Workshop - Monitoring Stack Deployment Script
# This script deploys Prometheus, Grafana, and related monitoring components

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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
KUBERNETES_DIR="$PROJECT_ROOT/kubernetes"

log "Starting monitoring stack deployment..."

# Check if kubectl is available and connected
if ! kubectl cluster-info &> /dev/null; then
    error "kubectl is not configured or cluster is not accessible"
fi

# Create monitoring namespace and RBAC
log "Creating monitoring namespace and RBAC..."
kubectl apply -f "$KUBERNETES_DIR/prometheus/namespace.yaml"

# Deploy Prometheus configuration
log "Deploying Prometheus configuration..."
kubectl apply -f "$KUBERNETES_DIR/prometheus/prometheus-config.yaml"
kubectl apply -f "$KUBERNETES_DIR/prometheus/prometheus-rules.yaml"

# Deploy Prometheus
log "Deploying Prometheus..."
kubectl apply -f "$KUBERNETES_DIR/prometheus/prometheus-deployment.yaml"

# Wait for Prometheus to be ready
log "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring

# Deploy Grafana
log "Deploying Grafana dashboards configuration..."
kubectl apply -f "$KUBERNETES_DIR/grafana/grafana-dashboards.yaml"

log "Deploying Grafana..."
kubectl apply -f "$KUBERNETES_DIR/grafana/grafana-deployment.yaml"

# Wait for Grafana to be ready
log "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Deploy Jaeger for distributed tracing
log "Deploying Jaeger for distributed tracing..."
kubectl create namespace jaeger-system --dry-run=client -o yaml | kubectl apply -f -

# Deploy Jaeger using the official Jaeger operator or simple deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: jaeger-system
  labels:
    app: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.48
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
        ports:
        - containerPort: 16686
          name: ui
        - containerPort: 14268
          name: collector
        - containerPort: 4317
          name: otlp-grpc
        - containerPort: 4318
          name: otlp-http
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-collector
  namespace: jaeger-system
  labels:
    app: jaeger
spec:
  ports:
  - port: 14268
    targetPort: 14268
    name: collector
  - port: 4317
    targetPort: 4317
    name: otlp-grpc
  - port: 4318
    targetPort: 4318
    name: otlp-http
  selector:
    app: jaeger
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger-ui
  namespace: jaeger-system
  labels:
    app: jaeger
spec:
  ports:
  - port: 16686
    targetPort: 16686
    name: ui
  selector:
    app: jaeger
EOF

# Wait for Jaeger to be ready
log "Waiting for Jaeger to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/jaeger -n jaeger-system

# Verify all components are running
log "Verifying monitoring stack deployment..."

info "Checking Prometheus..."
kubectl get pods -n monitoring -l app=prometheus

info "Checking Grafana..."
kubectl get pods -n monitoring -l app=grafana

info "Checking Jaeger..."
kubectl get pods -n jaeger-system -l app=jaeger

# Create port-forward helper scripts
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
mkdir -p "$SCRIPTS_DIR/helpers"

log "Creating port-forward helper scripts..."

# Grafana port-forward script
cat > "$SCRIPTS_DIR/helpers/port-forward-grafana.sh" << 'EOF'
#!/bin/bash
echo "Port-forwarding Grafana to http://localhost:3000"
echo "Username: admin"
echo "Password: ObservabilityWorkshop@2024!"
echo "Press Ctrl+C to stop"
kubectl port-forward -n monitoring svc/grafana 3000:3000
EOF

# Prometheus port-forward script
cat > "$SCRIPTS_DIR/helpers/port-forward-prometheus.sh" << 'EOF'
#!/bin/bash
echo "Port-forwarding Prometheus to http://localhost:9090"
echo "Press Ctrl+C to stop"
kubectl port-forward -n monitoring svc/prometheus 9090:9090
EOF

# Jaeger port-forward script
cat > "$SCRIPTS_DIR/helpers/port-forward-jaeger.sh" << 'EOF'
#!/bin/bash
echo "Port-forwarding Jaeger UI to http://localhost:16686"
echo "Press Ctrl+C to stop"
kubectl port-forward -n jaeger-system svc/jaeger-ui 16686:16686
EOF

# Make scripts executable
chmod +x "$SCRIPTS_DIR/helpers"/*.sh

# Output service information
log "Getting service information..."
kubectl get services -n monitoring
kubectl get services -n jaeger-system

log "Monitoring stack deployment completed successfully!"
log ""
log "Deployed components:"
log "✓ Prometheus (metrics collection and alerting)"
log "✓ Grafana (visualization and dashboards)"
log "✓ Jaeger (distributed tracing)"
log ""
log "Access URLs (requires port-forwarding):"
log "- Grafana: http://localhost:3000 (admin/ObservabilityWorkshop@2024!)"
log "- Prometheus: http://localhost:9090"
log "- Jaeger: http://localhost:16686"
log ""
log "Port-forwarding helper scripts created in $SCRIPTS_DIR/helpers/"
log "- $SCRIPTS_DIR/helpers/port-forward-grafana.sh"
log "- $SCRIPTS_DIR/helpers/port-forward-prometheus.sh"
log "- $SCRIPTS_DIR/helpers/port-forward-jaeger.sh"
log ""
log "To start port-forwarding, run one of the helper scripts or use kubectl directly:"
log "kubectl port-forward -n monitoring svc/grafana 3000:3000"
log "kubectl port-forward -n monitoring svc/prometheus 9090:9090"
log "kubectl port-forward -n jaeger-system svc/jaeger-ui 16686:16686"