# Complete Azure Observability Workshop Guide - Part 5
## Advanced Workshop - Enterprise-Scale Observability Setup (2 hours)

### Prerequisites Check
Before starting the Advanced Workshop, ensure you have completed Parts 1-4 and have:
- ✅ Intermediate Workshop completed successfully with working microservices
- ✅ Multi-cloud monitoring integration functional (Azure + Datadog + Prometheus)
- ✅ CI/CD pipelines with deployment monitoring and rollback capabilities
- ✅ Security monitoring with Defender and Sentinel integration
- ✅ Understanding of distributed tracing and enterprise observability patterns

### New Prerequisites for Advanced Level
- **Multi-Cloud Accounts**: AWS and GCP accounts with credits available
- **Kubernetes Experience**: Familiarity with K8s concepts and kubectl
- **Terraform Knowledge**: Infrastructure as Code experience
- **Enterprise Networking**: Understanding of VPNs, private endpoints, hybrid connectivity
- **Advanced Security**: Zero-trust principles, compliance requirements (SOC2, GDPR)

### Advanced Workshop Overview
This workshop demonstrates enterprise-scale observability solutions used by Fortune 500 companies:
- **Enterprise-scale architecture** patterns for global organizations
- **AI-enhanced SRE Agent** implementation with predictive analytics
- **Multi-cloud Kubernetes** monitoring with centralized Azure hub
- **Infrastructure as Code** with comprehensive observability automation
- **Advanced troubleshooting** scenarios and challenge labs
- **Compliance and governance** for regulated industries

---

## Module 1.1: Multi-Cloud Kubernetes Infrastructure Setup (60 minutes)

### Step 1: Enterprise Infrastructure as Code Setup
**Time Required**: 30 minutes

1. **Create Enterprise-Scale Terraform Configuration**:

Create the directory structure:
```bash
mkdir -p infrastructure/terraform/{modules,environments}
cd infrastructure/terraform
```

Create `main.tf`:
```hcl
# main.tf - Enterprise Multi-Cloud Kubernetes Setup
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Provider configurations
provider "azurerm" {
  features {}
}

provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "enterprise"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "organization" {
  description = "Organization name"
  type        = string
  default     = "workshop-corp"
}

# Azure Resources - Central Observability Hub
resource "azurerm_resource_group" "observability_hub" {
  name     = "${var.organization}-observability-${var.environment}-rg"
  location = "East US"

  tags = {
    Environment    = var.environment
    Purpose        = "Enterprise Observability Hub"
    CostCenter     = "IT-Operations"
    Owner          = "Platform-Team"
    Compliance     = "SOC2"
  }
}

# Enterprise Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "enterprise_logs" {
  name                = "${var.organization}-logs-${var.environment}"
  location            = azurerm_resource_group.observability_hub.location
  resource_group_name = azurerm_resource_group.observability_hub.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  daily_quota_gb      = 100

  tags = azurerm_resource_group.observability_hub.tags
}

# Enterprise Application Insights
resource "azurerm_application_insights" "enterprise_insights" {
  name                = "${var.organization}-insights-${var.environment}"
  location            = azurerm_resource_group.observability_hub.location
  resource_group_name = azurerm_resource_group.observability_hub.name
  workspace_id        = azurerm_log_analytics_workspace.enterprise_logs.id
  application_type    = "web"
  sampling_percentage = 100

  tags = azurerm_resource_group.observability_hub.tags
}

# Azure Kubernetes Service (AKS) - Primary Cluster
resource "azurerm_kubernetes_cluster" "aks_primary" {
  name                = "${var.organization}-aks-${var.environment}"
  location            = azurerm_resource_group.observability_hub.location
  resource_group_name = azurerm_resource_group.observability_hub.name
  dns_prefix          = "${var.organization}-aks-${var.environment}"
  kubernetes_version  = "1.28.3"

  default_node_pool {
    name                = "system"
    node_count          = 3
    vm_size            = "Standard_D4s_v3"
    type               = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count          = 2
    max_count          = 10
    os_disk_size_gb    = 50
    
    upgrade_settings {
      max_surge = "33%"
    }
  }

  # Enable monitoring addon
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.enterprise_logs.id
  }

  # Enable Azure Policy addon
  azure_policy_enabled = true

  # Network configuration
  network_profile {
    network_plugin      = "azure"
    network_policy      = "azure"
    dns_service_ip      = "10.254.0.10"
    docker_bridge_cidr  = "172.17.0.1/16"
    service_cidr        = "10.254.0.0/16"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable advanced features
  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  tags = azurerm_resource_group.observability_hub.tags
}

# Additional node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "workload_nodes" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_primary.id
  vm_size              = "Standard_D4s_v3"
  node_count           = 2
  enable_auto_scaling  = true
  min_count           = 1
  max_count           = 20
  
  node_labels = {
    "workload-type" = "general"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = azurerm_resource_group.observability_hub.tags
}

# Output important values
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks_primary.name
}

output "aks_resource_group" {
  value = azurerm_resource_group.observability_hub.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.enterprise_logs.workspace_id
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.enterprise_insights.instrumentation_key
  sensitive = true
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.enterprise_insights.connection_string
  sensitive = true
}
```

2. **Deploy Enterprise Infrastructure**:
```bash
# Initialize and apply Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars << EOF
environment = "enterprise"
organization = "workshop-corp"
gcp_project_id = "your-gcp-project-id"  # Optional
aws_region = "us-east-1"  # Optional if you have AWS account
EOF

# Plan and apply
terraform plan
terraform apply -auto-approve

# Get cluster credentials
RESOURCE_GROUP=$(terraform output -raw aks_resource_group)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

### Step 2: Core Observability Stack Deployment
**Time Required**: 30 minutes

1. **Deploy Prometheus and Grafana Stack**:

Create `k8s-manifests/observability-stack.yaml`:
```yaml
# Observability Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: observability
  labels:
    name: observability
    tier: platform
---
# Prometheus ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: observability
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
      external_labels:
        cluster: 'aks-enterprise'
        environment: 'enterprise'
        
    rule_files:
      - "alert_rules.yml"
      
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093
              
    scrape_configs:
      # Kubernetes API servers
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https

      # Kubernetes nodes
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
        - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
          
      # Kubernetes pods
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
          action: replace
          target_label: __metrics_path__
          regex: (.+)
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          action: replace
          regex: ([^:]+)(?::\d+)?;(\d+)
          replacement: $1:$2
          target_label: __address__

  alert_rules.yml: |
    groups:
    - name: enterprise.rules
      rules:
      # High CPU usage
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage is above 80% for more than 5 minutes"
          
      # High memory usage
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
        for: 5m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% for more than 5 minutes"
          
      # Pod restart rate
      - alert: HighPodRestartRate
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
          team: development
        annotations:
          summary: "High pod restart rate"
          description: "Pod {{ $labels.pod }} is restarting frequently"
          
      # Service down
      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
          team: platform
        annotations:
          summary: "Service is down"
          description: "Service {{ $labels.job }} has been down for more than 2 minutes"
---
# Prometheus Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: observability
  labels:
    app: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:v2.47.0
        ports:
        - containerPort: 9090
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus/'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--storage.tsdb.retention.time=30d'
          - '--web.enable-lifecycle'
          - '--web.external-url=http://prometheus:9090'
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus/
        - name: prometheus-storage-volume
          mountPath: /prometheus/
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
      - name: prometheus-storage-volume
        emptyDir: {}
---
# Prometheus Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: observability
---
# Prometheus ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
# Prometheus ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: observability
---
# Prometheus Service
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: observability
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
spec:
  type: LoadBalancer
  ports:
  - port: 9090
    protocol: TCP
    targetPort: 9090
  selector:
    app: prometheus
---
# Grafana Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.1.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "enterprise123"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_INSTALL_PLUGINS
          value: "grafana-azure-monitor-datasource"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
# Grafana Service
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: observability
spec:
  type: LoadBalancer
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
  selector:
    app: grafana
```

2. **Deploy Observability Stack**:
```bash
# Create k8s manifests directory
mkdir -p k8s-manifests
cd k8s-manifests

# Apply the observability stack
kubectl apply -f observability-stack.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n observability --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n observability --timeout=300s

# Get service URLs
kubectl get services -n observability

# Port forward to access services locally
kubectl port-forward -n observability svc/prometheus 9090:9090 &
kubectl port-forward -n observability svc/grafana 3000:3000 &

echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000 (admin/enterprise123)"
```

3. **Configure Azure Monitor Integration**:

Create `azure-monitor-integration.yaml`:
```yaml
# Azure Monitor Agent DaemonSet
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: azure-monitor-agent
  namespace: observability
spec:
  selector:
    matchLabels:
      app: azure-monitor-agent
  template:
    metadata:
      labels:
        app: azure-monitor-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: azure-monitor-agent
        image: mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.4
        env:
        - name: APPLICATIONINSIGHTS_CONNECTION_STRING
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: connection-string
        - name: CLUSTER_NAME
          value: "aks-enterprise"
        - name: CONTROLLER_TYPE
          value: "DaemonSet"
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        - name: var-log
          mountPath: /var/log
          readOnly: true
        - name: var-lib-docker-containers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      - name: var-log
        hostPath:
          path: /var/log
      - name: var-lib-docker-containers
        hostPath:
          path: /var/lib/docker/containers
---
# Secret for Azure Monitor connection
apiVersion: v1
kind: Secret
metadata:
  name: azure-secrets
  namespace: observability
type: Opaque
data:
  connection-string: # Base64 encoded Application Insights connection string
```

4. **Update secret with actual connection string**:
```bash
# Get the connection string from Terraform output
CONNECTION_STRING=$(terraform output -raw application_insights_connection_string)
CONNECTION_STRING_B64=$(echo -n "$CONNECTION_STRING" | base64 -w 0)

# Update the secret file
sed -i "s/connection-string: .*/connection-string: $CONNECTION_STRING_B64/" azure-monitor-integration.yaml

# Apply the integration
kubectl apply -f azure-monitor-integration.yaml
```

**✅ Checkpoint**: Enterprise Kubernetes cluster should be running with comprehensive monitoring stack

---

## Next Steps

In **Part 6**, we will continue with:
- **Module 1.2**: Service Mesh Advanced Observability (Istio setup with distributed tracing)
- **Module 2**: AI-Enhanced SRE Agent Implementation
- **Module 3**: Multi-Cloud Integration with AWS/GCP

The enterprise foundation is now ready for advanced observability features!

---

## Validation Commands

Before proceeding to Part 6, validate your setup:

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check observability stack
kubectl get pods -n observability
kubectl get services -n observability

# Test Prometheus metrics
curl http://localhost:9090/api/v1/query?query=up

# Test Grafana access
curl -u admin:enterprise123 http://localhost:3000/api/health

# Check Azure Monitor integration
kubectl logs -n observability daemonset/azure-monitor-agent --tail=50
```

All services should be running successfully before continuing to Part 6.
