#!/bin/bash

# Azure SRE Agent Configuration Script
# This script configures AI-powered monitoring with Azure SRE Agent

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if running in Azure
check_azure_environment() {
    print_info "Checking Azure environment..."
    
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    print_success "Azure environment verified. Subscription: $SUBSCRIPTION_ID"
}

# Install Azure SRE Agent prerequisites
install_prerequisites() {
    print_info "Installing prerequisites for Azure SRE Agent..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        print_info "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Add Azure SRE Agent Helm repository
    print_info "Adding Azure SRE Agent Helm repository..."
    helm repo add azure-sre-agent https://microsoft.github.io/azure-sre-agent-helm-charts
    helm repo update
}

# Create namespace and secrets
setup_namespace() {
    print_info "Setting up monitoring namespace..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for Azure Arc if enabled
    kubectl label namespace monitoring azure-arc=enabled --overwrite
}

# Configure Azure credentials
configure_azure_credentials() {
    print_info "Configuring Azure credentials for SRE Agent..."
    
    # Get service principal credentials
    read -p "Enter Azure Service Principal Client ID: " CLIENT_ID
    read -s -p "Enter Azure Service Principal Client Secret: " CLIENT_SECRET
    echo
    
    # Create Kubernetes secret
    kubectl create secret generic azure-sre-agent-credentials \
        --from-literal=clientId="$CLIENT_ID" \
        --from-literal=clientSecret="$CLIENT_SECRET" \
        --from-literal=tenantId="$TENANT_ID" \
        --from-literal=subscriptionId="$SUBSCRIPTION_ID" \
        --namespace monitoring \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Azure credentials configured"
}

# Deploy Azure SRE Agent
deploy_sre_agent() {
    print_info "Deploying Azure SRE Agent..."
    
    # Create values file for Helm
    cat > /tmp/sre-agent-values.yaml << EOF
# Azure SRE Agent Helm Values
agent:
  image:
    repository: mcr.microsoft.com/azure-sre-agent
    tag: latest
    pullPolicy: Always

  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2000m"

azure:
  subscriptionId: "$SUBSCRIPTION_ID"
  tenantId: "$TENANT_ID"
  credentials:
    secretName: azure-sre-agent-credentials

ai:
  anomalyDetection:
    enabled: true
    sensitivity: medium
    algorithms:
      - isolation-forest
      - prophet
      - lstm-autoencoder
    
  predictiveAnalytics:
    enabled: true
    forecasting:
      enabled: true
      horizon: 24h
      
  rootCauseAnalysis:
    enabled: true
    correlationWindow: 5m
    
  intelligentAlerting:
    enabled: true
    suppressDuplicates: true
    groupingWindow: 5m

monitoring:
  prometheus:
    enabled: true
    endpoint: http://prometheus:9090
    
  applicationInsights:
    enabled: true
    connectionString: "$APP_INSIGHTS_CONNECTION_STRING"
    
  logAnalytics:
    enabled: true
    workspaceId: "$LOG_ANALYTICS_WORKSPACE_ID"

automation:
  enabled: true
  requireApproval: false
  actions:
    - name: auto-scale
      trigger: cpu_usage > 80
      action: scale_out
      cooldown: 5m
      
    - name: restart-failed
      trigger: pod_restart_count > 3
      action: restart_pod
      cooldown: 10m

integrations:
  azureDevOps:
    enabled: true
    organization: "$AZURE_DEVOPS_ORG"
    project: "$AZURE_DEVOPS_PROJECT"
    
  github:
    enabled: true
    repository: "$GITHUB_REPOSITORY"
    
  slack:
    enabled: false
    webhookUrl: "$SLACK_WEBHOOK_URL"
    
  teams:
    enabled: true
    webhookUrl: "$TEAMS_WEBHOOK_URL"

serviceAccount:
  create: true
  name: azure-sre-agent
  annotations:
    azure.workload.identity/client-id: "$CLIENT_ID"

rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["pods", "services", "endpoints", "nodes"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["apps"]
      resources: ["deployments", "replicasets", "statefulsets", "daemonsets"]
      verbs: ["get", "list", "watch", "update", "patch"]
    - apiGroups: ["autoscaling"]
      resources: ["horizontalpodautoscalers"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    - apiGroups: ["policy"]
      resources: ["poddisruptionbudgets"]
      verbs: ["get", "list", "watch", "create", "update", "patch"]
    - apiGroups: ["batch"]
      resources: ["jobs", "cronjobs"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["monitoring.coreos.com"]
      resources: ["servicemonitors", "prometheusrules"]
      verbs: ["get", "list", "watch", "create", "update", "patch"]

persistence:
  enabled: true
  storageClass: managed-premium
  size: 20Gi

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics

dashboards:
  enabled: true
  grafana:
    enabled: true
    folder: "AI Monitoring"
    
ingress:
  enabled: false
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: sre-agent.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: sre-agent-tls
      hosts:
        - sre-agent.example.com
EOF

    # Deploy using Helm
    helm upgrade --install azure-sre-agent azure-sre-agent/sre-agent \
        --namespace monitoring \
        --values /tmp/sre-agent-values.yaml \
        --wait \
        --timeout 10m
    
    print_success "Azure SRE Agent deployed successfully"
}

# Configure AI models
configure_ai_models() {
    print_info "Configuring AI models for anomaly detection..."
    
    # Apply custom AI model configurations
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-models-config
  namespace: monitoring
data:
  models.yaml: |
    models:
      - name: latency-anomaly-detector
        type: isolation-forest
        parameters:
          contamination: 0.1
          n_estimators: 100
          max_samples: auto
          bootstrap: true
        features:
          - service_latency_p95
          - service_latency_p99
          - request_rate
          - error_rate
        training:
          schedule: "0 */6 * * *"  # Every 6 hours
          retention: 7d
          
      - name: traffic-predictor
        type: prophet
        parameters:
          changepoint_prior_scale: 0.05
          seasonality_prior_scale: 10
          seasonality_mode: multiplicative
        features:
          - request_rate
          - unique_users
          - bandwidth_usage
        training:
          schedule: "0 0 * * *"  # Daily
          retention: 30d
          
      - name: resource-forecaster
        type: lstm
        parameters:
          hidden_units: 128
          layers: 3
          dropout: 0.2
          learning_rate: 0.001
        features:
          - cpu_usage
          - memory_usage
          - disk_io
          - network_throughput
        training:
          schedule: "0 0 * * 0"  # Weekly
          retention: 90d
          
      - name: error-pattern-detector
        type: dbscan
        parameters:
          eps: 0.5
          min_samples: 5
          metric: euclidean
        features:
          - error_rate
          - error_types
          - service_dependencies
          - trace_patterns
        training:
          schedule: "0 */4 * * *"  # Every 4 hours
          retention: 14d
EOF
    
    print_success "AI models configured"
}

# Configure automation policies
configure_automation_policies() {
    print_info "Configuring automation policies..."
    
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: automation-policies
  namespace: monitoring
data:
  policies.yaml: |
    policies:
      - name: auto-scaling-policy
        description: "Automatically scale services based on AI predictions"
        enabled: true
        conditions:
          - metric: predicted_load
            operator: ">"
            threshold: 80
            duration: 5m
        actions:
          - type: scale_horizontal
            parameters:
              min_replicas: 2
              max_replicas: 10
              target_cpu_utilization: 70
              scale_up_rate: 2
              scale_down_rate: 1
              
      - name: circuit-breaker-policy
        description: "Enable circuit breaker for failing services"
        enabled: true
        conditions:
          - metric: error_rate
            operator: ">"
            threshold: 50
            duration: 2m
        actions:
          - type: enable_circuit_breaker
            parameters:
              failure_threshold: 5
              success_threshold: 2
              timeout: 30s
              half_open_requests: 3
              
      - name: resource-optimization-policy
        description: "Optimize resource allocation based on usage patterns"
        enabled: true
        conditions:
          - metric: resource_waste_percentage
            operator: ">"
            threshold: 30
            duration: 1h
        actions:
          - type: adjust_resources
            parameters:
              cpu_buffer: 20
              memory_buffer: 25
              min_cpu: 100m
              min_memory: 128Mi
              
      - name: predictive-maintenance-policy
        description: "Proactive maintenance based on failure predictions"
        enabled: true
        conditions:
          - metric: failure_probability
            operator: ">"
            threshold: 70
            duration: 10m
        actions:
          - type: rolling_restart
            parameters:
              max_unavailable: 1
              pause_between_pods: 30s
              health_check_timeout: 60s
EOF
    
    print_success "Automation policies configured"
}

# Setup monitoring dashboards
setup_dashboards() {
    print_info "Setting up AI monitoring dashboards..."
    
    # Create Grafana dashboard ConfigMap
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-monitoring-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  ai-monitoring.json: |
    {
      "dashboard": {
        "title": "AI-Powered Monitoring Dashboard",
        "uid": "ai-monitoring",
        "tags": ["ai", "sre-agent", "anomaly-detection"],
        "timezone": "browser",
        "panels": [
          {
            "title": "Anomaly Detection Status",
            "type": "stat",
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
            "targets": [
              {
                "expr": "sre_agent_anomalies_detected_total",
                "refId": "A"
              }
            ]
          },
          {
            "title": "Prediction Accuracy",
            "type": "gauge",
            "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
            "targets": [
              {
                "expr": "sre_agent_prediction_accuracy",
                "refId": "A"
              }
            ]
          },
          {
            "title": "Automated Actions",
            "type": "graph",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
            "targets": [
              {
                "expr": "rate(sre_agent_automation_actions_total[5m])",
                "legendFormat": "{{action_type}}",
                "refId": "A"
              }
            ]
          },
          {
            "title": "Root Cause Analysis",
            "type": "table",
            "gridPos": {"h": 10, "w": 24, "x": 0, "y": 8},
            "targets": [
              {
                "expr": "sre_agent_root_cause_analysis",
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
    
    print_success "AI monitoring dashboards configured"
}

# Verify deployment
verify_deployment() {
    print_info "Verifying Azure SRE Agent deployment..."
    
    # Check pod status
    kubectl wait --for=condition=ready pod -l app=azure-sre-agent -n monitoring --timeout=300s
    
    # Check service endpoints
    kubectl get endpoints -n monitoring azure-sre-agent
    
    # Test API endpoint
    POD_NAME=$(kubectl get pod -n monitoring -l app=azure-sre-agent -o jsonpath="{.items[0].metadata.name}")
    kubectl exec -n monitoring $POD_NAME -- curl -s http://localhost:8080/health
    
    print_success "Azure SRE Agent is running and healthy"
}

# Main execution
main() {
    print_info "Starting Azure SRE Agent configuration..."
    
    check_azure_environment
    install_prerequisites
    setup_namespace
    configure_azure_credentials
    deploy_sre_agent
    configure_ai_models
    configure_automation_policies
    setup_dashboards
    verify_deployment
    
    print_success "Azure SRE Agent configuration completed successfully!"
    print_info "Access the AI monitoring dashboard at: http://localhost:3000/d/ai-monitoring"
    print_info "Check agent logs: kubectl logs -n monitoring -l app=azure-sre-agent -f"
}

# Run main function
main "$@" 