#  Azure Observability Workshop - Resources & Automation

This directory contains all the automation scripts, templates, and resources needed to run the complete Azure Observability Workshop. Everything is designed to be executed with minimal configuration - just provide your Azure subscription ID!

##  Quick Start

The easiest way to get started is with the quick-start script:

```bash
# 1. Deploy the complete workshop environment
./quick-start.sh deploy YOUR_SUBSCRIPTION_ID

# 2. Start the workshop environment (port forwarding)
./quick-start.sh start

# 3. Check deployment status
./quick-start.sh status

# 4. Clean up when done
./quick-start.sh cleanup
```

##  Directory Structure

```
resources/
├── quick-start.sh              #  Main entry point for students
├── deploy-workshop.sh          #  Complete workshop deployment
├── terraform/                  #  Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── aks.tf                 # AKS cluster configuration
│   ├── outputs.tf             # Output values
│   └── variables.tf           # Input variables
├── scripts/                    #  Deployment scripts
│   ├── deploy-infrastructure.sh # Azure infrastructure
│   ├── deploy-monitoring.sh    # Monitoring stack
│   ├── deploy-applications.sh  # Sample applications
│   └── helpers/               #  Utility scripts
│       ├── start-workshop-env.sh    # Start all services
│       ├── port-forward-grafana.sh  # Grafana access
│       ├── port-forward-prometheus.sh # Prometheus access
│       ├── port-forward-jaeger.sh   # Jaeger access
│       └── generate-load.sh         # Traffic generation
├── kubernetes/                 # ⚓ Kubernetes manifests
│   ├── prometheus/            # Prometheus configuration
│   ├── grafana/               # Grafana dashboards
│   └── applications/          # Sample app deployments
└── applications/              #  Sample applications
    ├── dotnet-sample/         # .NET Core sample app
    ├── user-service/          # User microservice
    └── order-service/         # Order microservice
```

##  Prerequisites

Before running the workshop automation, ensure you have:

### Required Tools
- **Azure CLI** (logged in to your subscription)
- **Terraform** (>= 1.0)
- **kubectl** (for Kubernetes management)
- **Docker** (for container operations)

### Azure Prerequisites
- Valid Azure subscription with sufficient permissions
- Subscription should allow creation of:
  - Resource Groups
  - AKS clusters
  - Container Registry
  - Log Analytics Workspace
  - Application Insights
  - Key Vault

### Installation Commands
```bash
# Azure CLI (macOS)
brew install azure-cli

# Terraform (macOS)
brew install terraform

# kubectl (macOS)
brew install kubernetes-cli

# Docker Desktop
# Download from https://docker.com/products/docker-desktop
```

##  Deployment Options

### Option 1: Quick Start (Recommended for Students)
```bash
# One-command deployment
./quick-start.sh deploy YOUR_SUBSCRIPTION_ID

# Start workshop environment
./quick-start.sh start
```

### Option 2: Full Control Deployment
```bash
# Step-by-step deployment with full control
./deploy-workshop.sh YOUR_SUBSCRIPTION_ID

# Optional: Skip specific components
./deploy-workshop.sh YOUR_SUBSCRIPTION_ID --skip-istio
./deploy-workshop.sh YOUR_SUBSCRIPTION_ID --quick
```

### Option 3: Manual Step-by-Step
```bash
# 1. Deploy infrastructure
./scripts/deploy-infrastructure.sh YOUR_SUBSCRIPTION_ID

# 2. Deploy monitoring stack
./scripts/deploy-monitoring.sh

# 3. Deploy applications
./scripts/deploy-applications.sh

# 4. Start environment
./scripts/helpers/start-workshop-env.sh
```

## 🎛️ Standard Configuration

The automation uses these standard settings (no configuration needed):

| Component | Configuration | Value |
|-----------|--------------|-------|
| **🌍 Region** | Azure Region | East US 2 |
| ** Resource Group** | Name Pattern | `rg-obs-workshop` |
| **⚓ AKS Cluster** | Name Pattern | `aks-obs-workshop` |
| ** Log Analytics** | Retention | 90 days |
| **🔐 Grafana Credentials** | Username/Password | `admin` / `ObservabilityWorkshop@2024!` |
| ** Container Registry** | SKU | Premium |
| ** Node Size** | AKS Default Pool | Standard_D4s_v3 |

##  Access URLs

After deployment and starting the environment:

| Service | URL | Credentials |
|---------|-----|-------------|
| ** Grafana** | http://localhost:3000 | admin / ObservabilityWorkshop@2024! |
| ** Prometheus** | http://localhost:9090 | None required |
| ** Jaeger** | http://localhost:16686 | None required |
| ** Sample App** | http://localhost:8080 | None required |
| **🚨 AlertManager** | http://localhost:9093 | None required |

##  What Gets Deployed

### Azure Infrastructure
- **Resource Group**: Centralized resource management
- **AKS Cluster**: Kubernetes cluster with monitoring enabled
- **Container Registry**: Private Docker registry
- **Log Analytics**: Centralized logging and analytics
- **Application Insights**: Application performance monitoring
- **Key Vault**: Secrets management
- **Virtual Network**: Secure networking
- **Storage Account**: Diagnostics and data storage

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Jaeger**: Distributed tracing
- **AlertManager**: Alert routing and management
- **Node Exporter**: System metrics
- **cAdvisor**: Container metrics

### Sample Applications
- **.NET Core API**: Multi-endpoint web application
- **User Service**: Microservice for user management
- **Order Service**: Microservice for order processing
- **Load Generator**: Traffic simulation tool

### Kubernetes Components
- **Namespaces**: Organized service separation
- **RBAC**: Security and permissions
- **Network Policies**: Traffic control
- **Service Mesh Ready**: Istio preparation
- **Monitoring Integration**: Built-in observability

##  Troubleshooting

### Common Issues

#### 1. Azure CLI Not Logged In
```bash
# Solution
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
```

#### 2. Insufficient Permissions
```bash
# Check current permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Required roles: Owner or Contributor + User Access Administrator
```

#### 3. Port Already in Use
```bash
# Find and kill conflicting processes
lsof -ti:3000 | xargs kill
lsof -ti:9090 | xargs kill
```

#### 4. Terraform State Issues
```bash
# Reset Terraform state (careful - this will re-create resources)
cd terraform/
rm -f terraform.tfstate*
terraform init
```

#### 5. kubectl Not Configured
```bash
# Get AKS credentials
source workshop-outputs.env
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER
```

### Getting Help

1. **Check deployment status**:
   ```bash
   ./quick-start.sh status
   ```

2. **View detailed logs**:
   ```bash
   kubectl logs -n monitoring deployment/grafana
   kubectl get events --all-namespaces
   ```

3. **Restart services**:
   ```bash
   ./scripts/helpers/start-workshop-env.sh
   ```

4. **Complete cleanup and redeploy**:
   ```bash
   ./quick-start.sh cleanup
   ./quick-start.sh deploy YOUR_SUBSCRIPTION_ID
   ```

## 🧹 Cleanup

### Quick Cleanup
```bash
./quick-start.sh cleanup
```

### Manual Cleanup
```bash
# Stop port forwarding
pkill -f "kubectl port-forward"

# Delete Azure resources
az group delete --name rg-obs-workshop --yes

# Clean local files
rm -f workshop-outputs.env
rm -f terraform/terraform.tfstate*
```

## 💰 Cost Management

### Estimated Costs (East US 2)
- **AKS Cluster**: ~$200-300/month (depending on usage)
- **Log Analytics**: ~$50-100/month (depending on data volume)
- **Container Registry**: ~$5-10/month
- **Storage**: ~$5-10/month

### Cost Optimization Tips
1. **Use quick deployment for short workshops** (`--quick` flag)
2. **Clean up resources immediately after workshop**
3. **Monitor usage with Azure Cost Management**
4. **Use Azure Dev/Test pricing where applicable**

## 🎓 Workshop Integration

This automation supports all workshop modules:

- **Part 1**: Basic Azure Monitor setup 
- **Part 2**: Dashboards and alerting   
- **Part 3**: Advanced Application Insights 
- **Part 4**: Multi-cloud integration 
- **Part 5**: AI-enhanced monitoring 
- **Part 6**: Service mesh observability 
- **Part 7**: Challenge labs 
- **Part 8**: Enterprise implementation 

## 🤝 Contributing

To contribute improvements to the automation:

1. Test changes in a separate Azure subscription
2. Update documentation accordingly
3. Ensure backward compatibility
4. Follow naming conventions
5. Add appropriate error handling

## 📞 Support

For workshop automation issues:

1. Check the troubleshooting guide above
2. Review the main workshop documentation
3. Check Azure service health status
4. Verify subscription limits and quotas

---

##  Ready to Start?

```bash
# Clone the repository
git clone https://github.com/your-repo/Agentic-Ops-Dev.git
cd Agentic-Ops-Dev/resources

# Deploy everything
./quick-start.sh deploy YOUR_SUBSCRIPTION_ID

# Start the workshop!
./quick-start.sh start
```

**Happy learning!** 