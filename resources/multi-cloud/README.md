# Multi-Cloud Observability with Azure

This directory contains all resources needed to implement multi-cloud observability using Azure as the central management platform. It demonstrates how to leverage Azure Arc, Azure Monitor, and third-party tools like Datadog to achieve unified monitoring across Azure, AWS, and GCP.

## 🌍 Overview

### The Multi-Cloud Challenge

Organizations today often run workloads across multiple cloud providers:
- **Azure** for enterprise applications and Microsoft integrations
- **AWS** for specific services or regional presence
- **GCP** for data analytics and machine learning

Managing observability across these environments presents unique challenges:
- Different monitoring tools and APIs
- Inconsistent metrics and logging formats
- Complex networking and security boundaries
- Difficulty correlating issues across clouds

### Our Solution

We provide a comprehensive approach using:
1. **Azure Arc** - Unified management plane for all Kubernetes clusters
2. **Azure Monitor** - Centralized metrics and logs collection
3. **Datadog Integration** - Enhanced multi-cloud observability
4. **Unified Dashboards** - Single pane of glass for all environments

## 🚀 Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- AWS account (if deploying to AWS)
- GCP project (if deploying to GCP)
- Required CLI tools:
  ```bash
  # Install required tools
  ./install-prerequisites.sh
  ```

### Deploy Everything

```bash
# Set your configuration
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AWS_REGION="us-east-1"
export GCP_PROJECT="your-gcp-project"

# Deploy to all clouds
./deploy-multicloud.sh \
  --app-name myapp \
  --deploy-azure true \
  --deploy-aws true \
  --deploy-gcp true \
  --enable-arc true \
  --enable-datadog true
```

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Portal                              │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │  Azure Arc  │  │ Azure Monitor │  │ Azure DevOps/GitHub│    │
│  └──────┬──────┘  └───────┬──────┘  └─────────┬──────────┘    │
└─────────┼─────────────────┼───────────────────┼────────────────┘
          │                 │                   │
          │    ┌────────────┴────────────┐     │
          │    │                         │     │
    ┌─────▼─────▼───┐  ┌─────────────┐  ┌─────▼─────┐
    │     Azure     │  │     AWS     │  │    GCP    │
    │  AKS Cluster  │  │ EKS Cluster │  │GKE Cluster│
    │               │  │             │  │           │
    │ ┌───────────┐ │  │ ┌─────────┐ │  │ ┌───────┐ │
    │ │ Datadog   │ │  │ │ Datadog │ │  │ │Datadog│ │
    │ │  Agent    │ │  │ │  Agent  │ │  │ │ Agent │ │
    │ └───────────┘ │  │ └─────────┘ │  │ └───────┘ │
    └───────────────┘  └─────────────┘  └───────────┘
```

### Components

1. **Azure Arc-enabled Kubernetes**
   - Provides unified management across all clusters
   - Enables Azure Policy enforcement
   - GitOps deployment capabilities
   - Azure RBAC integration

2. **Azure Monitor Integration**
   - Container Insights for all clusters
   - Log Analytics workspace for centralized logs
   - Custom metrics collection
   - Alert rules across clouds

3. **Datadog Multi-Cloud Monitoring**
   - APM and distributed tracing
   - Infrastructure monitoring
   - Log aggregation and analysis
   - Custom dashboards and alerts

4. **CI/CD Integration**
   - GitHub Actions workflows
   - Azure DevOps pipelines
   - Multi-cloud deployment automation
   - Observability-driven deployments

## 📚 Detailed Guides

### 1. Azure Arc Setup

Azure Arc enables you to manage Kubernetes clusters running anywhere as if they were running in Azure.

```bash
# Connect a cluster to Azure Arc
./setup-azure-arc.sh \
  --cluster-name my-eks-cluster \
  --resource-group rg-multicloud \
  --cloud aws
```

**Features enabled:**
- Azure Policy for Kubernetes
- Azure Monitor for containers
- Microsoft Defender for Cloud
- GitOps with Flux v2
- Azure RBAC

### 2. Datadog Integration

Datadog provides comprehensive monitoring across all clouds with advanced features.

```bash
# Set Datadog credentials
export DATADOG_API_KEY="your-api-key"
export DATADOG_APP_KEY="your-app-key"

# Deploy Datadog
./datadog-integration/setup-datadog.sh
```

**Features configured:**
- Infrastructure monitoring
- APM and distributed tracing
- Log collection and processing
- Network performance monitoring
- Security monitoring
- Custom metrics and dashboards

### 3. Multi-Cloud Deployment

Deploy applications consistently across all clouds:

```bash
# Deploy application to all clouds
./deploy-multicloud.sh \
  --app-name my-application \
  --app-version v2.0.0
```

**Deployment includes:**
- Kubernetes deployments with health checks
- Load balancer services
- Horizontal pod autoscaling
- Pod disruption budgets
- Observability annotations

## 🔧 Configuration

### Environment Variables

```bash
# Azure Configuration
export AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export AZURE_CLIENT_SECRET="your-client-secret"

# AWS Configuration
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# GCP Configuration
export GCP_PROJECT="your-project-id"
export GCP_REGION="us-central1"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Datadog Configuration
export DATADOG_API_KEY="your-datadog-api-key"
export DATADOG_APP_KEY="your-datadog-app-key"
export DATADOG_SITE="datadoghq.com"  # or datadoghq.eu
```

### Customization Options

#### Azure Arc Features

```yaml
# Enable/disable specific Arc features
arc:
  gitops:
    enabled: true
    repository: https://github.com/your-org/k8s-config
  monitoring:
    enabled: true
    logAnalyticsWorkspaceId: "workspace-id"
  defender:
    enabled: true
  policy:
    enabled: true
    assignments:
      - "Kubernetes cluster pods should only use allowed images"
      - "Kubernetes clusters should be accessible only over HTTPS"
```

#### Datadog Configuration

```yaml
# Customize Datadog deployment
datadog:
  features:
    apm:
      enabled: true
      sampleRate: 0.1
    logs:
      enabled: true
      containerCollectAll: true
    npm:
      enabled: true
    processAgent:
      enabled: true
  integrations:
    azure:
      enabled: true
    aws:
      enabled: true
    gcp:
      enabled: true
```

## 🔍 Observability Scenarios

### Scenario 1: Azure-Only Deployment

For organizations using only Azure:

```bash
# Deploy to Azure with full observability
./deploy-multicloud.sh \
  --deploy-azure true \
  --deploy-aws false \
  --deploy-gcp false \
  --enable-arc false \
  --enable-datadog false

# Use native Azure monitoring
az aks enable-addons \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --addons monitoring
```

### Scenario 2: Multi-Cloud with Unified Management

For true multi-cloud deployments:

```bash
# Deploy everywhere with Arc and Datadog
./deploy-multicloud.sh \
  --deploy-azure true \
  --deploy-aws true \
  --deploy-gcp true \
  --enable-arc true \
  --enable-datadog true
```

### Scenario 3: Hybrid Cloud with On-Premises

For hybrid scenarios including on-premises:

```bash
# Connect on-premises cluster
./setup-azure-arc.sh \
  --cluster-name on-prem-cluster \
  --resource-group rg-hybrid \
  --cloud on-premises

# Enable Azure Monitor
az k8s-extension create \
  --name azuremonitor-containers \
  --cluster-name on-prem-cluster \
  --resource-group rg-hybrid \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AzureMonitor.Containers
```

## 📊 Dashboards and Alerts

### Pre-configured Dashboards

1. **Multi-Cloud Overview**
   - Total requests across clouds
   - Error rates by region
   - Latency comparison
   - Cost analysis

2. **Application Performance**
   - APM service map
   - Transaction traces
   - Error analytics
   - Performance trends

3. **Infrastructure Health**
   - Cluster utilization
   - Node health
   - Pod status
   - Network performance

4. **Security Posture**
   - Policy compliance
   - Security alerts
   - Vulnerability status
   - Access patterns

### Alert Examples

```yaml
# High Error Rate Alert
- name: "Multi-Cloud High Error Rate"
  condition: |
    avg(last_5m):sum:http.requests.errors{*} by {cloud}.as_rate() > 0.05
  message: "Error rate above 5% in {{cloud.name}}"
  
# Cross-Cloud Latency Alert
- name: "Cross-Cloud Latency Degradation"
  condition: |
    avg(last_10m):avg:trace.http.request.duration{*} by {source_cloud,target_cloud} > 1000
  message: "High latency between {{source_cloud.name}} and {{target_cloud.name}}"
```

## 🛠️ Troubleshooting

### Common Issues

1. **Arc Connection Failed**
   ```bash
   # Check Arc agents
   kubectl get pods -n azure-arc
   
   # View Arc agent logs
   kubectl logs -n azure-arc deployment/clusterconnect-agent
   ```

2. **Datadog Agent Not Collecting Metrics**
   ```bash
   # Check agent status
   kubectl exec -n datadog -it datadog-xxxxx -- agent status
   
   # Verify API key
   kubectl get secret datadog-agent -n datadog -o yaml
   ```

3. **Cross-Cloud Connectivity Issues**
   ```bash
   # Test connectivity
   kubectl exec -it test-pod -- curl http://service.other-cloud.example.com
   
   # Check network policies
   kubectl get networkpolicies --all-namespaces
   ```

## 📈 Cost Optimization

### Multi-Cloud Cost Management

1. **Use Azure Arc for unified cost views**
   ```bash
   # Enable cost analysis
   az costmanagement export create \
     --name MultiCloudExport \
     --type Usage \
     --scope "subscriptions/$SUBSCRIPTION_ID"
   ```

2. **Implement resource tagging**
   ```yaml
   tags:
     Environment: Production
     Application: MyApp
     CostCenter: Engineering
     ManagedBy: AzureArc
   ```

3. **Set up budget alerts**
   ```bash
   # Create budget with alerts
   az consumption budget create \
     --budget-name MultiCloudBudget \
     --amount 10000 \
     --time-grain Monthly \
     --category Cost
   ```

## 🔐 Security Best Practices

1. **Use Managed Identities** (Azure) / **IAM Roles** (AWS) / **Service Accounts** (GCP)
2. **Implement Network Policies** across all clusters
3. **Enable Encryption** for data in transit and at rest
4. **Regular Security Scanning** with Microsoft Defender
5. **Audit Logging** to centralized location

## 🚦 CI/CD Integration

### GitHub Actions Example

```yaml
name: Multi-Cloud Deployment
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Multi-Cloud
        env:
          AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
        run: |
          ./deploy-multicloud.sh --app-name myapp --app-version ${{ github.sha }}
```

### Azure DevOps Pipeline Example

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Deploy
  jobs:
  - job: MultiCloudDeploy
    steps:
    - task: AzureCLI@2
      inputs:
        azureSubscription: 'MySubscription'
        scriptType: 'bash'
        scriptLocation: 'scriptPath'
        scriptPath: './deploy-multicloud.sh'
        arguments: '--app-name myapp --app-version $(Build.BuildId)'
```

## 📖 Additional Resources

### Documentation
- [Azure Arc Documentation](https://docs.microsoft.com/azure/azure-arc/)
- [Azure Monitor for Containers](https://docs.microsoft.com/azure/azure-monitor/insights/container-insights-overview)
- [Datadog Kubernetes Integration](https://docs.datadoghq.com/agent/kubernetes/)

### Training
- [Azure Arc Jumpstart](https://azurearcjumpstart.io/)
- [Multi-Cloud Architecture on Microsoft Learn](https://docs.microsoft.com/learn/paths/architect-multi-cloud/)

### Community
- [Azure Arc GitHub](https://github.com/Azure/azure-arc-kubernetes)
- [CNCF Observability SIG](https://github.com/cncf/sig-observability)

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines for:
- Adding new cloud providers
- Enhancing monitoring capabilities
- Improving documentation
- Sharing best practices

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details. 