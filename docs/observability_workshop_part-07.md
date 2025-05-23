# Complete Azure Observability Workshop Guide - Part 7
## Multi-Cloud Integration & Advanced Troubleshooting (2.5 hours)

### Prerequisites Check
Before starting Part 7, ensure you have completed Parts 5-6 and have:
- ✅ Enterprise Kubernetes cluster with Istio service mesh running
- ✅ Prometheus, Grafana, Jaeger, and Kiali operational
- ✅ Azure Monitor integration configured
- ✅ SRE Agent simulator deployed
- ✅ Intelligent alerting rules configured and active

---

## Module 3: Multi-Cloud Integration (90 minutes)

### Step 1: AWS Integration Setup (Optional - requires AWS account)
**Time Required**: 45 minutes

1. **Setup AWS EKS Integration**:

Create `aws-integration/eks-setup.tf`:
```hcl
# AWS EKS Integration for Multi-Cloud Observability
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "workshop-eks-enterprise"
}

# VPC for EKS
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Subnets
resource "aws_subnet" "eks_subnet" {
  count = 2

  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.1.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table
resource "aws_route_table" "eks_rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "${var.cluster_name}-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "eks_rta" {
  count = 2

  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_rt.id
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = aws_subnet.eks_subnet[*].id
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name = var.cluster_name
    Environment = "enterprise"
    Cloud = "aws"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.eks_subnet[*].id
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy,
  ]

  tags = {
    Environment = "enterprise"
    Cloud = "aws"
  }
}

# Output EKS details
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}
```

2. **Deploy AWS Integration (if AWS account available)**:
```bash
# Create AWS integration directory
mkdir -p aws-integration
cd aws-integration

# Apply AWS EKS setup (only if you have AWS account)
terraform init
terraform plan
terraform apply -auto-approve

# Get EKS credentials
aws eks update-kubeconfig --region us-east-1 --name workshop-eks-enterprise

# Switch back to AKS context
kubectl config use-context aks-enterprise  # Your AKS context name
```

### Step 2: Multi-Cloud Monitoring Integration
**Time Required**: 45 minutes

1. **Setup Cross-Cloud Metrics Collection**:

Create `multi-cloud-monitoring.yaml`:
```yaml
# Multi-Cloud Prometheus Federation Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-federation-config
  namespace: observability
data:
  prometheus-federation.yml: |
    global:
      scrape_interval: 30s
      evaluation_interval: 30s
      external_labels:
        cluster: 'azure-hub'
        region: 'eastus'
        cloud: 'azure'
        
    scrape_configs:
    # Federate from AWS EKS Prometheus (if available)
    - job_name: 'federate-aws-eks'
      scrape_interval: 60s
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~"kubernetes-.*"}'
          - '{job=~"node-exporter"}'
          - '{job=~"application-.*"}'
          - 'up'
          - 'node_cpu_seconds_total'
          - 'node_memory_MemTotal_bytes'
          - 'node_memory_MemAvailable_bytes'
          - 'container_cpu_usage_seconds_total'
          - 'container_memory_working_set_bytes'
      static_configs:
        - targets:
          - 'aws-prometheus.example.com:9090'  # Replace with actual EKS Prometheus endpoint
      relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 'aws-prometheus.example.com:9090'
      - target_label: cloud
        replacement: 'aws'
        
    # Federate from GCP GKE Prometheus (if available)  
    - job_name: 'federate-gcp-gke'
      scrape_interval: 60s
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~"kubernetes-.*"}'
          - '{job=~"node-exporter"}'
          - 'up'
      static_configs:
        - targets:
          - 'gcp-prometheus.example.com:9090'  # Replace with actual GKE Prometheus endpoint
      relabel_configs:
      - target_label: cloud
        replacement: 'gcp'
        
    # Azure Monitor metrics via Azure Monitor Exporter
    - job_name: 'azure-monitor-metrics'
      scrape_interval: 60s
      static_configs:
        - targets:
          - 'azure-monitor-exporter:9276'
      relabel_configs:
      - target_label: cloud
        replacement: 'azure'
        
    # Cross-cloud application metrics
    - job_name: 'cross-cloud-apps'
      kubernetes_sd_configs:
      - role: service
        namespaces:
          names:
          - production
          - staging
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_cloud]
        target_label: source_cloud
      - target_label: current_cloud
        replacement: 'azure'
---
# Azure Monitor Exporter for cross-cloud correlation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-monitor-exporter
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-monitor-exporter
  template:
    metadata:
      labels:
        app: azure-monitor-exporter
    spec:
      containers:
      - name: azure-monitor-exporter
        image: prom/azure-exporter:latest
        ports:
        - containerPort: 9276
        env:
        - name: AZURE_SUBSCRIPTION_ID
          valueFrom:
            secretKeyRef:
              name: azure-credentials
              key: subscription-id
        - name: AZURE_CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: azure-credentials
              key: client-id
        - name: AZURE_CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: azure-credentials
              key: client-secret
        - name: AZURE_TENANT_ID
          valueFrom:
            secretKeyRef:
              name: azure-credentials
              key: tenant-id
        args:
        - --config.file=/etc/azure-exporter/config.yml
        volumeMounts:
        - name: config
          mountPath: /etc/azure-exporter
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
      volumes:
      - name: config
        configMap:
          name: azure-exporter-config
---
# Azure Monitor Exporter Config
apiVersion: v1
kind: ConfigMap
metadata:
  name: azure-exporter-config
  namespace: observability
data:
  config.yml: |
    targets:
      - resource_group: "*"
        resource_type: "Microsoft.Compute/virtualMachines"
        metrics:
          - name: "Percentage CPU"
          - name: "Network In Total"
          - name: "Network Out Total"
      - resource_group: "*" 
        resource_type: "Microsoft.ContainerService/managedClusters"
        metrics:
          - name: "cluster_autoscaler_cluster_safe_to_autoscale"
          - name: "cluster_autoscaler_scale_down_in_cooldown"
          - name: "cluster_autoscaler_unneeded_nodes_count"
      - resource_group: "*"
        resource_type: "Microsoft.Storage/storageAccounts"
        metrics:
          - name: "UsedCapacity"
          - name: "Transactions"
---
# Cross-Cloud Service Monitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: cross-cloud-services
  namespace: observability
spec:
  selector:
    matchLabels:
      monitoring: cross-cloud
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    relabelings:
    - sourceLabels: [__meta_kubernetes_service_annotation_cloud_provider]
      targetLabel: cloud_provider
    - sourceLabels: [__meta_kubernetes_service_annotation_region]
      targetLabel: region
    - sourceLabels: [__meta_kubernetes_service_annotation_cluster]
      targetLabel: cluster
---
# Multi-Cloud Grafana Dashboard ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: multicloud-dashboards
  namespace: observability
  labels:
    grafana_dashboard: "1"
data:
  multicloud-overview.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Multi-Cloud Overview",
        "tags": ["multi-cloud", "enterprise"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Cross-Cloud Request Rate",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(rate(istio_requests_total[5m])) by (cloud)",
                "legendFormat": "{{cloud}} requests/sec"
              }
            ],
            "gridPos": {"h": 6, "w": 8, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Cross-Cloud Error Rate",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(rate(istio_requests_total{response_code=~\"5.*\"}[5m])) by (cloud) / sum(rate(istio_requests_total[5m])) by (cloud) * 100",
                "legendFormat": "{{cloud}} error %"
              }
            ],
            "gridPos": {"h": 6, "w": 8, "x": 8, "y": 0}
          },
          {
            "id": 3,
            "title": "Cross-Cloud Latency",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (cloud, le))",
                "legendFormat": "{{cloud}} P95"
              },
              {
                "expr": "histogram_quantile(0.50, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (cloud, le))",
                "legendFormat": "{{cloud}} P50"
              }
            ],
            "gridPos": {"h": 6, "w": 8, "x": 16, "y": 0}
          },
          {
            "id": 4,
            "title": "Resource Utilization by Cloud",
            "type": "graph",
            "targets": [
              {
                "expr": "avg(100 - (avg by (cloud) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)) by (cloud)",
                "legendFormat": "{{cloud}} CPU %"
              },
              {
                "expr": "avg((1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100) by (cloud)",
                "legendFormat": "{{cloud}} Memory %"
              }
            ],
            "gridPos": {"h": 6, "w": 12, "x": 0, "y": 6}
          },
          {
            "id": 5,
            "title": "Service Health Across Clouds",
            "type": "table",
            "targets": [
              {
                "expr": "up{job=~\"kubernetes-.*\"} == 1",
                "format": "table",
                "instant": true
              }
            ],
            "gridPos": {"h": 6, "w": 12, "x": 12, "y": 6}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "refresh": "30s"
      }
    }
```

2. **Deploy Multi-Cloud Monitoring**:
```bash
# Create Azure credentials secret (replace with actual values)
kubectl create secret generic azure-credentials \
  --from-literal=subscription-id="YOUR_SUBSCRIPTION_ID" \
  --from-literal=client-id="YOUR_CLIENT_ID" \
  --from-literal=client-secret="YOUR_CLIENT_SECRET" \
  --from-literal=tenant-id="YOUR_TENANT_ID" \
  -n observability

# Apply multi-cloud monitoring
kubectl apply -f multi-cloud-monitoring.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/azure-monitor-exporter -n observability

# Verify federation configuration
kubectl get configmap prometheus-federation-config -n observability -o yaml
```

3. **Configure Cross-Cloud Service Discovery**:

Create `cross-cloud-discovery.yaml`:
```yaml
# Cross-Cloud Service Discovery for Enterprise
apiVersion: v1
kind: ConfigMap
metadata:
  name: cross-cloud-service-discovery
  namespace: observability
data:
  discovery-config.yaml: |
    clouds:
      azure:
        clusters:
          - name: "aks-enterprise"
            endpoint: "https://aks-enterprise-dns-xxxx.hcp.eastus.azmk8s.io"
            region: "eastus"
            prometheus_endpoint: "http://prometheus.observability.svc.cluster.local:9090"
            
      aws:
        clusters:
          - name: "workshop-eks-enterprise"
            endpoint: "https://xxxx.gr7.us-east-1.eks.amazonaws.com"
            region: "us-east-1"
            prometheus_endpoint: "http://aws-prometheus.example.com:9090"
            
      gcp:
        clusters:
          - name: "workshop-gke-enterprise"
            endpoint: "https://xxx.xxx.xxx.xxx"
            region: "us-central1"
            prometheus_endpoint: "http://gcp-prometheus.example.com:9090"
            
    service_discovery:
      enabled: true
      sync_interval: "30s"
      discovery_methods:
        - kubernetes_api
        - dns_discovery
        - static_config
        
    cross_cloud_routing:
      enabled: true
      load_balancing: "round_robin"
      health_check_interval: "10s"
      failover_enabled: true
      
    observability:
      distributed_tracing: true
      cross_cloud_metrics: true
      slo_monitoring: true
      correlation_tracking: true
---
# Cross-Cloud Gateway for Service Mesh
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: cross-cloud-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http-cross-cloud
      protocol: HTTP
    hosts:
    - "*.multicloud.enterprise.local"
  - port:
      number: 443
      name: https-cross-cloud
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: multicloud-tls
    hosts:
    - "*.multicloud.enterprise.local"
---
# Cross-Cloud Virtual Service
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: cross-cloud-routing
  namespace: production
spec:
  hosts:
  - "api.multicloud.enterprise.local"
  gateways:
  - istio-system/cross-cloud-gateway
  http:
  # Route to different clouds based on headers
  - match:
    - headers:
        "x-target-cloud":
          exact: "aws"
    route:
    - destination:
        host: aws-service-proxy.production.svc.cluster.local
      weight: 100
    timeout: 30s
    
  - match:
    - headers:
        "x-target-cloud":
          exact: "gcp"
    route:
    - destination:
        host: gcp-service-proxy.production.svc.cluster.local
      weight: 100
    timeout: 30s
    
  # Default to Azure services
  - route:
    - destination:
        host: user-service.production.svc.cluster.local
      weight: 100
    timeout: 30s
---
# Cross-Cloud Service Proxy (Simulated)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-service-proxy
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: aws-service-proxy
      cloud: aws
  template:
    metadata:
      labels:
        app: aws-service-proxy
        cloud: aws
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: proxy
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: TARGET_CLOUD
          value: "aws"
        - name: PROXY_MODE
          value: "cross-cloud"
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
        resources:
          requests:
            memory: "64Mi"
            cpu: "25m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      volumes:
      - name: config
        configMap:
          name: aws-proxy-config
---
# AWS Proxy Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-proxy-config
  namespace: production
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        add_header X-Cloud-Source "azure";
        add_header X-Cloud-Target "aws";
        add_header X-Proxy-Type "cross-cloud";
        
        location / {
            add_header Content-Type application/json;
            return 200 '{"message": "AWS service response (simulated)", "cloud": "aws", "proxy": "azure-to-aws"}';
        }
        
        location /health {
            return 200 "healthy from aws proxy";
        }
    }
---
# Service for AWS Proxy
apiVersion: v1
kind: Service
metadata:
  name: aws-service-proxy
  namespace: production
  labels:
    app: aws-service-proxy
    cloud: aws
    monitoring: cross-cloud
  annotations:
    cloud_provider: "aws"
    region: "us-east-1"
    cluster: "workshop-eks-enterprise"
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: aws-service-proxy
```

4. **Deploy Cross-Cloud Configuration**:
```bash
# Apply cross-cloud discovery
kubectl apply -f cross-cloud-discovery.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/aws-service-proxy -n production

# Test cross-cloud routing
INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test Azure routing (default)
curl -H "Host: api.multicloud.enterprise.local" \
     -H "x-request-id: multicloud-test-1" \
     http://$INGRESS_IP/

# Test AWS routing
curl -H "Host: api.multicloud.enterprise.local" \
     -H "x-target-cloud: aws" \
     -H "x-request-id: multicloud-test-2" \
     http://$INGRESS_IP/
```

**✅ Checkpoint**: Multi-cloud integration should show cross-cloud metrics and routing

---

## Module 4: Advanced Troubleshooting Scenarios (60 minutes)

### Step 1: Performance Degradation Scenario
**Time Required**: 30 minutes

1. **Create Performance Issue Simulation**:

Create `troubleshooting-scenarios.yaml`:
```yaml
# Performance Degradation Simulation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-service
  namespace: production
  labels:
    app: slow-service
    issue-type: performance
spec:
  replicas: 2
  selector:
    matchLabels:
      app: slow-service
      version: problematic
  template:
    metadata:
      labels:
        app: slow-service
        version: problematic
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: slow-service
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: SIMULATED_DELAY
          value: "2000"  # 2 second delay
        - name: ERROR_RATE
          value: "10"    # 10% error rate
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
        - name: scripts
          mountPath: /usr/local/bin
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: config
        configMap:
          name: slow-service-config
      - name: scripts
        configMap:
          name: slow-service-scripts
          defaultMode: 0755
---
# Slow Service Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: slow-service-config
  namespace: production
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            # Add artificial delay using Lua or proxy to simulate performance issues
            add_header Content-Type application/json;
            
            # Simulate different response times based on request path
            location /fast {
                return 200 '{"response": "fast", "delay_ms": 50}';
            }
            
            location /slow {
                # Simulate slow response (handled by script)
                proxy_pass http://127.0.0.1:8001/slow;
                proxy_read_timeout 5s;
            }
            
            location /error {
                # Simulate intermittent errors
                proxy_pass http://127.0.0.1:8001/error;
            }
            
            # Default slow response
            proxy_pass http://127.0.0.1:8001/default;
            proxy_read_timeout 5s;
        }
        
        location /health {
            access_log off;
            return 200 "healthy but slow";
        }
        
        location /metrics {
            stub_status on;
            access_log off;
        }
    }
---
# Slow Service Scripts
apiVersion: v1
kind: ConfigMap
metadata:
  name: slow-service-scripts
  namespace: production
data:
  start-backend.sh: |
    #!/bin/bash
    # Simple HTTP server that simulates performance issues
    python3 -c "
    import http.server
    import socketserver
    import time
    import random
    import json
    import os
    
    class SlowHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            path = self.path
            delay = int(os.environ.get('SIMULATED_DELAY', '1000')) / 1000.0
            error_rate = int(os.environ.get('ERROR_RATE', '5'))
            
            # Simulate different behaviors based on path
            if '/slow' in path:
                time.sleep(delay * 2)
            elif '/fast' in path:
                time.sleep(0.05)
            elif '/error' in path:
                if random.randint(1, 100) <= error_rate:
                    self.send_error(500, 'Simulated error')
                    return
            else:
                time.sleep(delay)
            
            # Add some CPU load to simulate processing
            start = time.time()
            while time.time() - start < 0.1:
                _ = sum(i*i for i in range(1000))
            
            response = {
                'service': 'slow-service',
                'path': path,
                'delay_ms': int(delay * 1000),
                'timestamp': time.time(),
                'cpu_load_simulation': True
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
    
    PORT = 8001
    with socketserver.TCPServer(('', PORT), SlowHandler) as httpd:
        print(f'Starting slow service backend on port {PORT}')
        httpd.serve_forever()
    "
---
# Slow Service
apiVersion: v1
kind: Service
metadata:
  name: slow-service
  namespace: production
  labels:
    app: slow-service
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "80"
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: slow-service
---
# Memory Leak Simulation
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-leak-service
  namespace: production
  labels:
    app: memory-leak-service
    issue-type: memory-leak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-leak-service
  template:
    metadata:
      labels:
        app: memory-leak-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: memory-leak-app
        image: python:3.9-slim
        command: ["/bin/sh"]
        args:
          - -c
          - |
            pip install flask prometheus_client && python3 -c "
            import time
            import threading
            from flask import Flask, jsonify
            from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
            import gc
            
            app = Flask(__name__)
            
            # Metrics
            REQUEST_COUNT = Counter('requests_total', 'Total requests')
            REQUEST_LATENCY = Histogram('request_duration_seconds', 'Request latency')
            
            # Memory leak simulation
            memory_hog = []
            
            @app.route('/')
            def home():
                REQUEST_COUNT.inc()
                with REQUEST_LATENCY.time():
                    # Simulate memory leak by accumulating data
                    memory_hog.append('x' * 10000)  # Add 10KB per request
                    if len(memory_hog) > 1000:  # Limit to prevent complete crash
                        memory_hog.clear()
                    
                    return jsonify({
                        'service': 'memory-leak-service',
                        'memory_objects': len(memory_hog),
                        'estimated_memory_kb': len(memory_hog) * 10
                    })
            
            @app.route('/metrics')
            def metrics():
                return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
            
            @app.route('/health')
            def health():
                return 'healthy', 200
            
            if __name__ == '__main__':
                app.run(host='0.0.0.0', port=80)
            "
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"  # Low limit to trigger OOM faster
            cpu: "200m"
---
# Memory Leak Service
apiVersion: v1
kind: Service
metadata:
  name: memory-leak-service
  namespace: production
  labels:
    app: memory-leak-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: memory-leak-service
---
# Virtual Service for Troubleshooting Routing
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: troubleshooting-routes
  namespace: production
spec:
  hosts:
  - "debug.enterprise.local"
  gateways:
  - enterprise-gateway
  http:
  - match:
    - uri:
        prefix: "/slow"
    route:
    - destination:
        host: slow-service.production.svc.cluster.local
      weight: 100
    timeout: 10s
    
  - match:
    - uri:
        prefix: "/memory-leak"
    route:
    - destination:
        host: memory-leak-service.production.svc.cluster.local
      weight: 100
    timeout: 30s
    
  # Default route to user service
  - route:
    - destination:
        host: user-service.production.svc.cluster.local
      weight: 100
```

2. **Deploy Troubleshooting Scenarios**:
```bash
# Apply troubleshooting scenarios
kubectl apply -f troubleshooting-scenarios.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/slow-service -n production
kubectl wait --for=condition=available --timeout=300s deployment/memory-leak-service -n production

# Generate traffic to trigger issues
INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Generate slow service traffic
for i in {1..20}; do
  curl -H "Host: debug.enterprise.local" \
       -H "x-request-id: slow-test-$i" \
       http://$INGRESS_IP/slow &
done

# Generate memory leak traffic
for i in {1..50}; do
  curl -H "Host: debug.enterprise.local" \
       -H "x-request-id: memory-test-$i" \
       http://$INGRESS_IP/memory-leak
  sleep 1
done
```

### Step 2: Troubleshooting Investigation Commands
**Time Required**: 30 minutes

1. **Kubernetes Troubleshooting Commands**:
```bash
# Check pod status and resource usage
kubectl top pods -n production
kubectl describe pod -n production -l app=slow-service
kubectl describe pod -n production -l app=memory-leak-service

# Check events for issues
kubectl get events -n production --sort-by=.metadata.creationTimestamp

# Check logs for errors
kubectl logs -n production -l app=slow-service --tail=50
kubectl logs -n production -l app=memory-leak-service --tail=50

# Check resource limits and requests
kubectl describe deployment slow-service -n production
kubectl describe deployment memory-leak-service -n production

# Check service mesh sidecar logs
kubectl logs -n production -l app=slow-service -c istio-proxy --tail=20
```

2. **Observability Investigation**:
```bash
# Check Prometheus metrics for performance issues
curl "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,sum(rate(istio_request_duration_milliseconds_bucket{destination_service_name=\"slow-service\"}[5m]))by(le))"

# Check error rates
curl "http://localhost:9090/api/v1/query?query=sum(rate(istio_requests_total{destination_service_name=\"slow-service\",response_code=~\"5.*\"}[5m]))/sum(rate(istio_requests_total{destination_service_name=\"slow-service\"}[5m]))*100"

# Check memory usage trends
curl "http://localhost:9090/api/v1/query?query=container_memory_working_set_bytes{pod=~\"memory-leak-service.*\"}"

# Check CPU usage
curl "http://localhost:9090/api/v1/query?query=rate(container_cpu_usage_seconds_total{pod=~\"slow-service.*\"}[5m])*100"
```

3. **Service Mesh Investigation with Kiali**:
```bash
# Port forward to access Kiali
kubectl port-forward -n istio-system svc/kiali 20001:20001 &

echo "Open Kiali at http://localhost:20001"
echo "Navigate to Graph -> production namespace"
echo "Look for red edges (errors) and thick edges (high traffic)"
echo "Check response times in the metrics tab"
```

4. **Distributed Tracing with Jaeger**:
```bash
# Port forward to access Jaeger
kubectl port-forward -n istio-system svc/jaeger 16686:16686 &

echo "Open Jaeger at http://localhost:16686"
echo "Search for traces with:"
echo "- Service: slow-service or memory-leak-service"
echo "- Tags: error=true"
echo "- Min Duration: 1000ms (to find slow traces)"
```

**✅ Checkpoint**: Troubleshooting scenarios should be generating observable issues

---

## Next Steps

In **Part 8**, we will complete the workshop with:
- **Module 5**: Compliance and Governance
- **Module 6**: Challenge Labs and Final Assessment
- **Workshop Wrap-up**: Best Practices and Next Steps

Your advanced multi-cloud observability platform is now ready for enterprise compliance and final challenges!

---

## Validation Commands

Before proceeding to Part 8:

```bash
# Check multi-cloud monitoring
kubectl get pods -n observability | grep -E "(azure-monitor|cross-cloud)"

# Verify troubleshooting scenarios are running
kubectl get pods -n production | grep -E "(slow-service|memory-leak)"

# Test cross-cloud routing
curl -H "Host: api.multicloud.enterprise.local" \
     -H "x-target-cloud: aws" \
     http://$INGRESS_IP/

# Check Prometheus federation
curl "http://localhost:9090/api/v1/label/cloud/values"

# Verify performance issues are being detected
curl "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname=="ResponseTimeAnomaly")'
```

All troubleshooting scenarios should be active and generating alerts.


---

## 🔙 Navigation

**[⬅️ Back to Main README](../README.md)**
