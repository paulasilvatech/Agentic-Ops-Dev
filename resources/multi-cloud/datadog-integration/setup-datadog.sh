#!/bin/bash

# Datadog Integration Script for Multi-Cloud Observability
# This script configures Datadog monitoring across Azure, AWS, and GCP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Required environment variables
DATADOG_API_KEY="${DATADOG_API_KEY:-}"
DATADOG_APP_KEY="${DATADOG_APP_KEY:-}"
DATADOG_SITE="${DATADOG_SITE:-datadoghq.com}"
CLUSTER_NAME="${CLUSTER_NAME:-}"
ENVIRONMENT="${ENVIRONMENT:-production}"

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

# Validate environment variables
validate_env() {
    print_info "Validating environment variables..."
    
    if [ -z "$DATADOG_API_KEY" ]; then
        print_error "DATADOG_API_KEY is not set"
        exit 1
    fi
    
    if [ -z "$DATADOG_APP_KEY" ]; then
        print_error "DATADOG_APP_KEY is not set"
        exit 1
    fi
    
    if [ -z "$CLUSTER_NAME" ]; then
        print_error "CLUSTER_NAME is not set"
        exit 1
    fi
    
    print_success "Environment variables validated"
}

# Install Datadog Helm repository
install_datadog_helm() {
    print_info "Installing Datadog Helm repository..."
    
    helm repo add datadog https://helm.datadoghq.com
    helm repo update
    
    print_success "Datadog Helm repository added"
}

# Create Datadog namespace
create_namespace() {
    print_info "Creating Datadog namespace..."
    
    kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for monitoring
    kubectl label namespace datadog monitoring=datadog --overwrite
    
    print_success "Datadog namespace created"
}

# Create Datadog secrets
create_secrets() {
    print_info "Creating Datadog secrets..."
    
    kubectl create secret generic datadog-agent \
        --from-literal="api-key=$DATADOG_API_KEY" \
        --from-literal="app-key=$DATADOG_APP_KEY" \
        --namespace datadog \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Datadog secrets created"
}

# Deploy Datadog Agent
deploy_datadog_agent() {
    print_info "Deploying Datadog Agent..."
    
    # Create values file
    cat > /tmp/datadog-values.yaml << EOF
# Datadog Agent Configuration
targetSystem: "linux"

datadog:
  apiKey: 
    existingSecret: datadog-agent
  appKey:
    existingSecret: datadog-agent
  
  # Site configuration
  site: $DATADOG_SITE
  
  # Cluster name
  clusterName: $CLUSTER_NAME
  
  # Tags
  tags:
    - "env:$ENVIRONMENT"
    - "cluster:$CLUSTER_NAME"
    - "managed_by:azure_arc"
  
  # Log collection
  logs:
    enabled: true
    containerCollectAll: true
    containerCollectUsingFiles: false
  
  # APM
  apm:
    enabled: true
    portEnabled: true
    socketEnabled: true
  
  # Process monitoring
  processAgent:
    enabled: true
    processCollection: true
  
  # Network monitoring
  networkMonitoring:
    enabled: true
  
  # Security monitoring
  securityAgent:
    compliance:
      enabled: true
    runtime:
      enabled: true
      syscallMonitor:
        enabled: true
  
  # Cluster checks
  clusterChecks:
    enabled: true
  
  # Prometheus scraping
  prometheusScrape:
    enabled: true
    serviceEndpoints: true
    additionalConfigs:
      - configurations:
          - prometheus_url: http://prometheus:9090/federate
            namespace: monitoring
            metrics:
              - "*"
  
  # Custom metrics
  kubeStateMetricsCore:
    enabled: true
  
  # OpenTelemetry
  otlp:
    receiver:
      protocols:
        grpc:
          enabled: true
        http:
          enabled: true

clusterAgent:
  enabled: true
  replicas: 2
  
  # RBAC
  rbac:
    create: true
  
  # Metrics provider
  metricsProvider:
    enabled: true
  
  # External metrics
  externalMetrics:
    enabled: true
  
  # Admission controller
  admissionController:
    enabled: true
    mutateUnlabelled: true

agents:
  # Resources
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 512Mi
  
  # Volume mounts
  volumeMounts:
    - name: dockersocket
      mountPath: /var/run/docker.sock
    - name: proc
      mountPath: /host/proc
      readOnly: true
    - name: cgroup
      mountPath: /host/sys/fs/cgroup
      readOnly: true
  
  # Tolerations for all nodes
  tolerations:
    - operator: Exists

# Enable kube-state-metrics
kubeStateMetricsCore:
  enabled: true

# Persistent volume for logs
persistence:
  enabled: true
  storageClass: managed-premium
  size: 10Gi
EOF
    
    # Deploy using Helm
    helm upgrade --install datadog-agent datadog/datadog \
        --namespace datadog \
        --values /tmp/datadog-values.yaml \
        --wait \
        --timeout 10m
    
    print_success "Datadog Agent deployed"
}

# Configure cloud integrations
configure_cloud_integrations() {
    print_info "Configuring cloud integrations..."
    
    # Azure integration
    cat > /tmp/azure-integration.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-azure-integration
  namespace: datadog
data:
  azure.yaml: |
    init_config:
    instances:
      - tenant_id: ${AZURE_TENANT_ID}
        client_id: ${AZURE_CLIENT_ID}
        client_secret: ${AZURE_CLIENT_SECRET}
        subscription_id: ${AZURE_SUBSCRIPTION_ID}
        
        # Resource filters
        resource_filter:
          - type: "Microsoft.ContainerService/managedClusters"
          - type: "Microsoft.Compute/virtualMachines"
          - type: "Microsoft.Storage/storageAccounts"
          - type: "Microsoft.Network/loadBalancers"
          - type: "Microsoft.Network/applicationGateways"
          - type: "Microsoft.Sql/servers/databases"
          - type: "Microsoft.Cache/Redis"
          
        # Collect metrics
        collect_metrics: true
        
        # Collect logs
        collect_logs: true
        
        # Tags
        tags:
          - "cloud:azure"
          - "integration:azure"
EOF
    
    # AWS integration
    cat > /tmp/aws-integration.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-aws-integration
  namespace: datadog
data:
  aws.yaml: |
    init_config:
    instances:
      - aws_access_key_id: ${AWS_ACCESS_KEY_ID}
        aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY}
        aws_region: ${AWS_REGION}
        
        # Services to monitor
        services:
          - eks
          - ec2
          - elb
          - rds
          - s3
          - cloudwatch
          - lambda
          - dynamodb
          - sqs
          - sns
          
        # Tags
        tags:
          - "cloud:aws"
          - "integration:aws"
EOF
    
    # GCP integration
    cat > /tmp/gcp-integration.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-gcp-integration
  namespace: datadog
data:
  gcp.yaml: |
    init_config:
    instances:
      - project_id: ${GCP_PROJECT_ID}
        private_key_id: ${GCP_PRIVATE_KEY_ID}
        private_key: ${GCP_PRIVATE_KEY}
        client_email: ${GCP_CLIENT_EMAIL}
        client_id: ${GCP_CLIENT_ID}
        
        # Services to monitor
        services:
          - gke
          - compute
          - storage
          - bigquery
          - pubsub
          - cloudsql
          - loadbalancing
          - cloudrun
          
        # Tags
        tags:
          - "cloud:gcp"
          - "integration:gcp"
EOF
    
    # Apply configurations
    kubectl apply -f /tmp/azure-integration.yaml
    kubectl apply -f /tmp/aws-integration.yaml
    kubectl apply -f /tmp/gcp-integration.yaml
    
    print_success "Cloud integrations configured"
}

# Configure custom dashboards
setup_dashboards() {
    print_info "Setting up Datadog dashboards..."
    
    # Create multi-cloud dashboard using Datadog API
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/dashboard" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "title": "Multi-Cloud Observability - ${CLUSTER_NAME}",
  "description": "Unified view of Azure, AWS, and GCP resources",
  "widgets": [
    {
      "definition": {
        "type": "query_value",
        "requests": [
          {
            "q": "sum:kubernetes.pods.running{cluster_name:${CLUSTER_NAME}}",
            "aggregator": "last"
          }
        ],
        "title": "Running Pods",
        "precision": 0
      },
      "layout": {"x": 0, "y": 0, "width": 3, "height": 2}
    },
    {
      "definition": {
        "type": "timeseries",
        "requests": [
          {
            "q": "avg:kubernetes.cpu.usage.total{cluster_name:${CLUSTER_NAME}} by {node}",
            "display_type": "line",
            "style": {
              "palette": "dog_classic",
              "line_type": "solid",
              "line_width": "normal"
            }
          }
        ],
        "title": "CPU Usage by Node"
      },
      "layout": {"x": 3, "y": 0, "width": 6, "height": 3}
    },
    {
      "definition": {
        "type": "heatmap",
        "requests": [
          {
            "q": "avg:trace.express.request{env:${ENVIRONMENT}} by {resource_name}.as_count()",
            "style": {
              "palette": "dog_classic"
            }
          }
        ],
        "title": "Request Heatmap"
      },
      "layout": {"x": 0, "y": 2, "width": 6, "height": 3}
    },
    {
      "definition": {
        "type": "log_stream",
        "query": "source:kubernetes cluster_name:${CLUSTER_NAME} @level:ERROR",
        "columns": ["timestamp", "service", "message"],
        "title": "Error Logs"
      },
      "layout": {"x": 6, "y": 3, "width": 6, "height": 4}
    }
  ],
  "layout_type": "free",
  "is_read_only": false,
  "notify_list": []
}
EOF
    
    print_success "Dashboards configured"
}

# Configure monitors and alerts
setup_monitors() {
    print_info "Setting up Datadog monitors..."
    
    # High error rate monitor
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/monitor" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "name": "[${CLUSTER_NAME}] High Error Rate",
  "type": "query alert",
  "query": "sum(last_5m):sum:trace.express.request.errors{env:${ENVIRONMENT},cluster_name:${CLUSTER_NAME}}.as_count() / sum:trace.express.request.hits{env:${ENVIRONMENT},cluster_name:${CLUSTER_NAME}}.as_count() > 0.05",
  "message": "Error rate is above 5% on cluster ${CLUSTER_NAME}\\n\\nCluster: ${CLUSTER_NAME}\\nEnvironment: ${ENVIRONMENT}\\n\\n@slack-alerts",
  "tags": ["cluster:${CLUSTER_NAME}", "env:${ENVIRONMENT}"],
  "options": {
    "thresholds": {
      "critical": 0.05,
      "warning": 0.03
    },
    "notify_no_data": false,
    "notify_audit": true
  }
}
EOF
    
    # Pod restart monitor
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/monitor" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "name": "[${CLUSTER_NAME}] Excessive Pod Restarts",
  "type": "query alert",
  "query": "sum(last_10m):sum:kubernetes.containers.restarts{cluster_name:${CLUSTER_NAME}} by {pod_name}.as_count() > 5",
  "message": "Pod {{pod_name}} has restarted more than 5 times in the last 10 minutes\\n\\nCluster: ${CLUSTER_NAME}\\n\\n@pagerduty",
  "tags": ["cluster:${CLUSTER_NAME}", "env:${ENVIRONMENT}"],
  "options": {
    "thresholds": {
      "critical": 5,
      "warning": 3
    }
  }
}
EOF
    
    # Multi-cloud cost anomaly
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/monitor" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "name": "[Multi-Cloud] Cost Anomaly Detection",
  "type": "query alert",
  "query": "avg(last_4h):anomalies(avg:aws.billing.estimated_charges{*} + avg:azure.cost_management.actual_cost{*} + avg:gcp.billing.cost{*}, 'basic', 2) >= 1",
  "message": "Anomaly detected in cloud spending\\n\\nPlease investigate cloud costs across all providers\\n\\n@finance-team",
  "tags": ["multi-cloud", "cost-management"],
  "options": {
    "threshold_windows": {
      "trigger_window": "last_4h",
      "recovery_window": "last_1h"
    }
  }
}
EOF
    
    print_success "Monitors configured"
}

# Configure APM and tracing
setup_apm() {
    print_info "Configuring APM and distributed tracing..."
    
    # Create APM configuration
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-apm-config
  namespace: applications
data:
  dd-config.yaml: |
    # Datadog APM Configuration
    apm_config:
      enabled: true
      env: ${ENVIRONMENT}
      service_mapping:
        - from: user-service
          to: user-api
        - from: order-service
          to: order-api
      
    # Trace sampling
    trace_sampling:
      rules:
        - service: "user-api"
          sample_rate: 0.5
        - service: "order-api"
          sample_rate: 0.5
        - service: "*"
          sample_rate: 0.1
    
    # Service catalog
    service_catalog:
      - name: user-api
        team: backend
        tier: api
        languages: ["dotnet"]
      - name: order-api
        team: backend
        tier: api
        languages: ["dotnet"]
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: datadog-tracing-env
  namespace: applications
data:
  DD_AGENT_HOST: "datadog-agent.datadog.svc.cluster.local"
  DD_TRACE_AGENT_PORT: "8126"
  DD_ENV: "${ENVIRONMENT}"
  DD_SERVICE: "$(POD_NAME)"
  DD_VERSION: "$(IMAGE_TAG)"
  DD_LOGS_INJECTION: "true"
  DD_TRACE_SAMPLE_RATE: "0.1"
  DD_PROFILING_ENABLED: "true"
  DD_APPSEC_ENABLED: "true"
EOF
    
    # Patch application deployments to include APM
    for app in user-service order-service dotnet-sample; do
        kubectl patch deployment $app -n applications --type='json' -p='[
          {
            "op": "add",
            "path": "/spec/template/spec/containers/0/env/-",
            "value": {
              "name": "DD_AGENT_HOST",
              "valueFrom": {
                "fieldRef": {
                  "fieldPath": "status.hostIP"
                }
              }
            }
          },
          {
            "op": "add",
            "path": "/spec/template/spec/containers/0/env/-",
            "value": {
              "name": "DD_ENV",
              "value": "'${ENVIRONMENT}'"
            }
          },
          {
            "op": "add",
            "path": "/spec/template/spec/containers/0/env/-",
            "value": {
              "name": "DD_SERVICE",
              "value": "'$app'"
            }
          },
          {
            "op": "add",
            "path": "/spec/template/spec/containers/0/env/-",
            "value": {
              "name": "DD_LOGS_INJECTION",
              "value": "true"
            }
          }
        ]'
    done
    
    print_success "APM and tracing configured"
}

# Configure log pipelines
setup_log_pipelines() {
    print_info "Setting up log pipelines..."
    
    # Create log processing pipeline
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/logs/config/pipelines" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "name": "Multi-Cloud Kubernetes Logs",
  "is_enabled": true,
  "filter": {
    "query": "source:kubernetes cluster_name:${CLUSTER_NAME}"
  },
  "processors": [
    {
      "type": "grok-parser",
      "name": "Parse Kubernetes logs",
      "is_enabled": true,
      "source": "message",
      "samples": [],
      "grok": {
        "support_rules": "",
        "match_rules": "rule %{date(\"yyyy-MM-dd HH:mm:ss\"):timestamp} \\[%{word:level}\\] %{data:message}"
      }
    },
    {
      "type": "status-remapper",
      "name": "Define log status",
      "is_enabled": true,
      "sources": ["level"]
    },
    {
      "type": "attribute-remapper",
      "name": "Map pod_name to service",
      "is_enabled": true,
      "sources": ["pod_name"],
      "target": "service",
      "target_type": "attribute",
      "preserve_source": true
    }
  ]
}
EOF
    
    print_success "Log pipelines configured"
}

# Configure SLOs
setup_slos() {
    print_info "Setting up Service Level Objectives..."
    
    # Create SLO for availability
    curl -X POST "https://api.${DATADOG_SITE}/api/v1/slo" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -H "DD-APPLICATION-KEY: ${DATADOG_APP_KEY}" \
        -d @- << EOF
{
  "name": "API Availability SLO",
  "description": "99.9% availability for all APIs",
  "tags": ["cluster:${CLUSTER_NAME}", "env:${ENVIRONMENT}"],
  "thresholds": [
    {
      "timeframe": "30d",
      "target": 99.9,
      "warning": 99.95
    }
  ],
  "type": "metric",
  "query": {
    "numerator": "sum:trace.express.request{cluster_name:${CLUSTER_NAME},!http.status_code:5*}.as_count()",
    "denominator": "sum:trace.express.request{cluster_name:${CLUSTER_NAME}}.as_count()"
  }
}
EOF
    
    print_success "SLOs configured"
}

# Verify installation
verify_installation() {
    print_info "Verifying Datadog installation..."
    
    # Check agent status
    kubectl wait --for=condition=ready pod -l app=datadog-agent -n datadog --timeout=300s
    
    # Get agent status
    POD_NAME=$(kubectl get pod -n datadog -l app=datadog-agent -o jsonpath="{.items[0].metadata.name}")
    kubectl exec -n datadog $POD_NAME -- agent status
    
    # Check cluster agent
    kubectl wait --for=condition=ready pod -l app=datadog-cluster-agent -n datadog --timeout=300s
    
    print_success "Datadog installation verified"
}

# Generate integration report
generate_report() {
    print_info "Generating Datadog integration report..."
    
    cat > datadog-integration-report.md << EOF
# Datadog Multi-Cloud Integration Report

**Date:** $(date)
**Cluster:** $CLUSTER_NAME
**Environment:** $ENVIRONMENT
**Datadog Site:** $DATADOG_SITE

## Installation Summary

### Components Deployed
- ✅ Datadog Agent (DaemonSet)
- ✅ Datadog Cluster Agent
- ✅ APM and Tracing
- ✅ Log Collection
- ✅ Metrics Collection
- ✅ Network Monitoring
- ✅ Security Monitoring

### Cloud Integrations
- ✅ Azure Monitor Integration
- ✅ AWS CloudWatch Integration
- ✅ GCP Stackdriver Integration

### Features Configured
- ✅ Custom Dashboards
- ✅ Monitors and Alerts
- ✅ Log Processing Pipelines
- ✅ Service Level Objectives
- ✅ APM Service Mapping

## Access Information

- **Datadog Dashboard:** https://app.$DATADOG_SITE
- **APM Service Map:** https://app.$DATADOG_SITE/apm/services
- **Log Explorer:** https://app.$DATADOG_SITE/logs
- **Infrastructure Map:** https://app.$DATADOG_SITE/infrastructure

## Next Steps

1. Configure additional integrations as needed
2. Customize dashboards for your specific use cases
3. Set up notification channels (Slack, PagerDuty, etc.)
4. Configure cost allocation tags
5. Enable RUM (Real User Monitoring) if applicable

## Useful Commands

\`\`\`bash
# Check agent status
kubectl exec -n datadog -it $(kubectl get pods -n datadog -l app=datadog-agent -o jsonpath='{.items[0].metadata.name}') -- agent status

# View agent logs
kubectl logs -n datadog -l app=datadog-agent

# Check cluster agent
kubectl logs -n datadog -l app=datadog-cluster-agent

# Test APM connectivity
kubectl exec -n applications -it <pod-name> -- curl http://datadog-agent.datadog.svc.cluster.local:8126/v0.3/traces
\`\`\`
EOF
    
    print_success "Report generated: datadog-integration-report.md"
}

# Main execution
main() {
    print_info "Starting Datadog multi-cloud integration..."
    
    validate_env
    install_datadog_helm
    create_namespace
    create_secrets
    deploy_datadog_agent
    configure_cloud_integrations
    setup_dashboards
    setup_monitors
    setup_apm
    setup_log_pipelines
    setup_slos
    verify_installation
    generate_report
    
    print_success "Datadog integration completed successfully!"
    print_info "Access your dashboards at: https://app.$DATADOG_SITE"
}

# Run main function
main "$@" 