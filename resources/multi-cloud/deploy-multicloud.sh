#!/bin/bash

# Multi-Cloud Deployment Script
# Deploy applications across Azure, AWS, and GCP with unified observability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="${APP_NAME:-sample-app}"
APP_VERSION="${APP_VERSION:-v1.0.0}"
DEPLOY_AZURE="${DEPLOY_AZURE:-true}"
DEPLOY_AWS="${DEPLOY_AWS:-true}"
DEPLOY_GCP="${DEPLOY_GCP:-true}"
ENABLE_ARC="${ENABLE_ARC:-true}"
ENABLE_DATADOG="${ENABLE_DATADOG:-true}"

# Cloud-specific settings
AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-rg-multicloud-${APP_NAME}}"
AZURE_LOCATION="${AZURE_LOCATION:-eastus2}"
AZURE_CLUSTER_NAME="${AZURE_CLUSTER_NAME:-aks-${APP_NAME}}"

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_CLUSTER_NAME="${AWS_CLUSTER_NAME:-eks-${APP_NAME}}"

GCP_PROJECT="${GCP_PROJECT:-}"
GCP_REGION="${GCP_REGION:-us-central1}"
GCP_CLUSTER_NAME="${GCP_CLUSTER_NAME:-gke-${APP_NAME}}"

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

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Common tools
    for tool in kubectl helm jq; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    # Cloud CLIs
    if [ "$DEPLOY_AZURE" = "true" ] && ! command -v az &> /dev/null; then
        missing_tools+=("az")
    fi
    
    if [ "$DEPLOY_AWS" = "true" ] && ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi
    
    if [ "$DEPLOY_GCP" = "true" ] && ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Deploy to Azure
deploy_to_azure() {
    if [ "$DEPLOY_AZURE" != "true" ]; then
        print_info "Skipping Azure deployment"
        return
    fi
    
    print_info "Deploying to Azure..."
    
    # Login check
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure. Please run 'az login'"
        exit 1
    fi
    
    # Create resource group
    az group create --name $AZURE_RESOURCE_GROUP --location $AZURE_LOCATION
    
    # Create AKS cluster if not exists
    if ! az aks show --name $AZURE_CLUSTER_NAME --resource-group $AZURE_RESOURCE_GROUP &>/dev/null; then
        print_info "Creating AKS cluster..."
        az aks create \
            --resource-group $AZURE_RESOURCE_GROUP \
            --name $AZURE_CLUSTER_NAME \
            --node-count 3 \
            --enable-addons monitoring \
            --generate-ssh-keys \
            --network-plugin azure \
            --network-policy azure
    fi
    
    # Get credentials
    az aks get-credentials --resource-group $AZURE_RESOURCE_GROUP --name $AZURE_CLUSTER_NAME --overwrite-existing
    
    # Deploy application
    deploy_application "azure" $AZURE_CLUSTER_NAME
    
    print_success "Azure deployment completed"
}

# Deploy to AWS
deploy_to_aws() {
    if [ "$DEPLOY_AWS" != "true" ]; then
        print_info "Skipping AWS deployment"
        return
    fi
    
    print_info "Deploying to AWS..."
    
    # Check if cluster exists
    if ! aws eks describe-cluster --name $AWS_CLUSTER_NAME --region $AWS_REGION &>/dev/null; then
        print_info "Creating EKS cluster..."
        
        # Create cluster using eksctl
        cat > /tmp/eks-cluster.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $AWS_CLUSTER_NAME
  region: $AWS_REGION
  version: "1.27"

managedNodeGroups:
  - name: workers
    instanceType: t3.medium
    desiredCapacity: 3
    minSize: 1
    maxSize: 5
    volumeSize: 80
    ssh:
      allow: true

iam:
  withOIDC: true

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver
EOF
        
        eksctl create cluster -f /tmp/eks-cluster.yaml
    fi
    
    # Update kubeconfig
    aws eks update-kubeconfig --name $AWS_CLUSTER_NAME --region $AWS_REGION
    
    # Deploy application
    deploy_application "aws" $AWS_CLUSTER_NAME
    
    print_success "AWS deployment completed"
}

# Deploy to GCP
deploy_to_gcp() {
    if [ "$DEPLOY_GCP" != "true" ]; then
        print_info "Skipping GCP deployment"
        return
    fi
    
    print_info "Deploying to GCP..."
    
    # Check project
    if [ -z "$GCP_PROJECT" ]; then
        print_error "GCP_PROJECT not set"
        exit 1
    fi
    
    # Set project
    gcloud config set project $GCP_PROJECT
    
    # Create GKE cluster if not exists
    if ! gcloud container clusters describe $GCP_CLUSTER_NAME --region $GCP_REGION &>/dev/null; then
        print_info "Creating GKE cluster..."
        gcloud container clusters create $GCP_CLUSTER_NAME \
            --region $GCP_REGION \
            --num-nodes 3 \
            --enable-cloud-logging \
            --enable-cloud-monitoring \
            --enable-autorepair \
            --enable-autoupgrade \
            --addons HorizontalPodAutoscaling,HttpLoadBalancing
    fi
    
    # Get credentials
    gcloud container clusters get-credentials $GCP_CLUSTER_NAME --region $GCP_REGION
    
    # Deploy application
    deploy_application "gcp" $GCP_CLUSTER_NAME
    
    print_success "GCP deployment completed"
}

# Deploy application to cluster
deploy_application() {
    local cloud=$1
    local cluster_name=$2
    
    print_info "Deploying application to $cloud cluster: $cluster_name"
    
    # Create namespace
    kubectl create namespace $APP_NAME --dry-run=client -o yaml | kubectl apply -f -
    
    # Create deployment manifest
    cat > /tmp/app-deployment-$cloud.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
    version: $APP_VERSION
    cloud: $cloud
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
        version: $APP_VERSION
        cloud: $cloud
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: $APP_NAME
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: CLOUD_PROVIDER
          value: "$cloud"
        - name: CLUSTER_NAME
          value: "$cluster_name"
        - name: APP_VERSION
          value: "$APP_VERSION"
        - name: DD_AGENT_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: DD_ENV
          value: "production"
        - name: DD_SERVICE
          value: "$APP_NAME"
        - name: DD_VERSION
          value: "$APP_VERSION"
        - name: DD_LOGS_INJECTION
          value: "true"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
  labels:
    app: $APP_NAME
    cloud: $cloud
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    name: http
  - port: 9090
    targetPort: 9090
    name: metrics
  selector:
    app: $APP_NAME
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $APP_NAME
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: $APP_NAME
  namespace: $APP_NAME
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: $APP_NAME
EOF
    
    # Apply deployment
    kubectl apply -f /tmp/app-deployment-$cloud.yaml
    
    # Wait for deployment
    kubectl wait --for=condition=available --timeout=300s deployment/$APP_NAME -n $APP_NAME
    
    # Get service endpoint
    local service_ip=""
    for i in {1..30}; do
        service_ip=$(kubectl get svc $APP_NAME -n $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ ! -z "$service_ip" ]; then
            break
        fi
        print_info "Waiting for load balancer IP... ($i/30)"
        sleep 10
    done
    
    if [ ! -z "$service_ip" ]; then
        print_success "Application deployed at: http://$service_ip"
    else
        print_warning "Load balancer IP not yet available"
    fi
}

# Enable Azure Arc
enable_azure_arc() {
    if [ "$ENABLE_ARC" != "true" ]; then
        print_info "Skipping Azure Arc setup"
        return
    fi
    
    print_info "Enabling Azure Arc for multi-cloud management..."
    
    # Setup Arc for each cloud
    if [ "$DEPLOY_AWS" = "true" ]; then
        ./resources/multi-cloud/setup-azure-arc.sh \
            --cluster-name $AWS_CLUSTER_NAME \
            --resource-group $AZURE_RESOURCE_GROUP \
            --cloud aws
    fi
    
    if [ "$DEPLOY_GCP" = "true" ]; then
        ./resources/multi-cloud/setup-azure-arc.sh \
            --cluster-name $GCP_CLUSTER_NAME \
            --resource-group $AZURE_RESOURCE_GROUP \
            --cloud gcp
    fi
    
    print_success "Azure Arc enabled for all clusters"
}

# Enable Datadog monitoring
enable_datadog_monitoring() {
    if [ "$ENABLE_DATADOG" != "true" ]; then
        print_info "Skipping Datadog setup"
        return
    fi
    
    print_info "Enabling Datadog monitoring across all clouds..."
    
    # Check for Datadog credentials
    if [ -z "$DATADOG_API_KEY" ] || [ -z "$DATADOG_APP_KEY" ]; then
        print_warning "Datadog API keys not set. Skipping Datadog setup."
        return
    fi
    
    # Deploy Datadog to each cluster
    for cluster in $AZURE_CLUSTER_NAME $AWS_CLUSTER_NAME $GCP_CLUSTER_NAME; do
        if [ ! -z "$cluster" ]; then
            export CLUSTER_NAME=$cluster
            ./resources/multi-cloud/datadog-integration/setup-datadog.sh
        fi
    done
    
    print_success "Datadog monitoring enabled"
}

# Create unified dashboard
create_unified_dashboard() {
    print_info "Creating unified observability dashboard..."
    
    # Create dashboard ConfigMap
    kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: multicloud-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  multicloud-overview.json: |
    {
      "dashboard": {
        "title": "Multi-Cloud Application Overview",
        "uid": "multicloud-overview",
        "tags": ["multicloud", "azure", "aws", "gcp"],
        "timezone": "browser",
        "panels": [
          {
            "title": "Total Requests Across Clouds",
            "type": "graph",
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (cloud)",
                "legendFormat": "{{cloud}}",
                "refId": "A"
              }
            ]
          },
          {
            "title": "Error Rate by Cloud",
            "type": "graph",
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (cloud) / sum(rate(http_requests_total[5m])) by (cloud)",
                "legendFormat": "{{cloud}}",
                "refId": "A"
              }
            ]
          },
          {
            "title": "Response Time by Cloud",
            "type": "heatmap",
            "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8},
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (cloud, le))",
                "legendFormat": "{{cloud}}",
                "refId": "A"
              }
            ]
          }
        ]
      }
    }
EOF
    
    print_success "Unified dashboard created"
}

# Generate deployment report
generate_report() {
    print_info "Generating multi-cloud deployment report..."
    
    cat > multicloud-deployment-report.md << EOF
# Multi-Cloud Deployment Report

**Date:** $(date)
**Application:** $APP_NAME
**Version:** $APP_VERSION

## Deployment Summary

### Azure
- **Deployed:** $DEPLOY_AZURE
- **Cluster:** $AZURE_CLUSTER_NAME
- **Resource Group:** $AZURE_RESOURCE_GROUP
- **Location:** $AZURE_LOCATION

### AWS
- **Deployed:** $DEPLOY_AWS
- **Cluster:** $AWS_CLUSTER_NAME
- **Region:** $AWS_REGION

### GCP
- **Deployed:** $DEPLOY_GCP
- **Cluster:** $GCP_CLUSTER_NAME
- **Project:** $GCP_PROJECT
- **Region:** $GCP_REGION

## Features Enabled

- **Azure Arc:** $ENABLE_ARC
- **Datadog Monitoring:** $ENABLE_DATADOG

## Access Points

$(if [ "$DEPLOY_AZURE" = "true" ]; then
    echo "### Azure"
    kubectl config use-context $AZURE_CLUSTER_NAME
    echo "- Endpoint: $(kubectl get svc $APP_NAME -n $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'Pending')"
fi)

$(if [ "$DEPLOY_AWS" = "true" ]; then
    echo "### AWS"
    kubectl config use-context $AWS_CLUSTER_NAME
    echo "- Endpoint: $(kubectl get svc $APP_NAME -n $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo 'Pending')"
fi)

$(if [ "$DEPLOY_GCP" = "true" ]; then
    echo "### GCP"
    kubectl config use-context $GCP_CLUSTER_NAME
    echo "- Endpoint: $(kubectl get svc $APP_NAME -n $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'Pending')"
fi)

## Monitoring

- **Grafana Dashboard:** http://localhost:3000/d/multicloud-overview
- **Prometheus:** http://localhost:9090
- **Datadog:** https://app.datadoghq.com

## Next Steps

1. Configure DNS for load balancing across clouds
2. Set up Traffic Manager or Global Load Balancer
3. Implement data replication strategy
4. Configure cross-cloud networking (VPN/ExpressRoute)
5. Set up disaster recovery procedures

## Commands

\`\`\`bash
# Switch between clusters
kubectl config use-context $AZURE_CLUSTER_NAME
kubectl config use-context $AWS_CLUSTER_NAME
kubectl config use-context $GCP_CLUSTER_NAME

# Check application status
kubectl get pods -n $APP_NAME --context=$AZURE_CLUSTER_NAME
kubectl get pods -n $APP_NAME --context=$AWS_CLUSTER_NAME
kubectl get pods -n $APP_NAME --context=$GCP_CLUSTER_NAME

# View logs
kubectl logs -n $APP_NAME -l app=$APP_NAME --context=<cluster-name>

# Scale application
kubectl scale deployment/$APP_NAME -n $APP_NAME --replicas=5 --context=<cluster-name>
\`\`\`
EOF
    
    print_success "Report generated: multicloud-deployment-report.md"
}

# Main execution
main() {
    print_info "Starting multi-cloud deployment..."
    
    check_prerequisites
    
    # Deploy to each cloud
    deploy_to_azure
    deploy_to_aws
    deploy_to_gcp
    
    # Enable management features
    enable_azure_arc
    enable_datadog_monitoring
    
    # Create unified views
    create_unified_dashboard
    
    # Generate report
    generate_report
    
    print_success "Multi-cloud deployment completed successfully!"
    print_info "Check multicloud-deployment-report.md for details"
}

# Run main function
main "$@" 