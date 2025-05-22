# Complete Azure Observability Workshop Guide - Part 1
## From Zero to AI-Enhanced Multi-Cloud Monitoring

### Table of Contents - Complete Workshop Series

**Part 1** - Setup and Beginner Foundation (This Document)
- [Pre-Workshop Preparation](#pre-workshop-preparation)
- [Step 1: Create Required Accounts](#step-1-create-required-accounts)
- [Step 2: Install Required Tools](#step-2-install-required-tools)
- [Beginner Workshop Introduction](#beginner-workshop-2-hours)
- [Module 1: Setting Up Your First Monitoring Solution](#module-1-setting-up-your-first-monitoring-solution-30-minutes)

**Part 2** - Beginner Workshop Modules 2-5
- Module 2: Creating Your First Dashboard and Alerts
- Module 3: AI-Assisted Troubleshooting with GitHub Copilot
- Module 4: Implementing Proactive Monitoring
- Module 5: Introduction to Azure SRE Agent

**Part 3** - Intermediate Workshop (4 hours)
- Module 1: Advanced Application Insights and Distributed Tracing
- Module 2: Multi-Cloud Monitoring Integration
- Module 3: CI/CD Integration with Observability
- Module 4: Security Monitoring Integration

**Part 4** - Advanced Workshop Part 1 (3-4 hours)
- Module 1: Enterprise-Scale Observability Architecture
- Module 2: AI-Enhanced SRE Agent Implementation

**Part 5** - Advanced Workshop Part 2 (3-4 hours)
- Module 3: Infrastructure as Code with Observability
- Multi-Cloud Challenge Labs
- Final Integration and Wrap-up

---

## Pre-Workshop Preparation

### What You'll Learn
By completing these workshops, you will:
- **Master Azure observability fundamentals** and advanced techniques
- **Implement AI-powered monitoring** with Azure SRE Agent and GitHub Copilot
- **Deploy and monitor applications** across Azure, AWS, and Google Cloud
- **Create unified dashboards** combining Azure Monitor, Datadog, and Prometheus
- **Establish automated incident response** with intelligent agents
- **Build enterprise-scale observability solutions**
- **Integrate security monitoring** with Microsoft Defender and Sentinel

### Workshop Overview and AI-Enhanced Features

#### What is Modern Observability?
**Traditional Monitoring**: Reactive alerts when something breaks
**Modern Observability**: Proactive insights into system behavior through metrics, logs, and traces
**AI-Enhanced Observability**: Intelligent agents that monitor, analyze, predict, and respond automatically

#### Key Technologies We'll Use
- **Azure SRE Agent**: NEW AI-powered site reliability engineering (BUILD 2025 launch)
- **GitHub Copilot**: AI pair programmer for monitoring queries and troubleshooting
- **Azure AI Foundry**: Advanced AI analysis for code and infrastructure
- **Multi-Cloud Integration**: Azure Monitor as central hub for AWS and GCP telemetry
- **Agentic DevOps**: Where AI agents work as team members in development lifecycle

### Time Investment
- **Preparation**: 45-60 minutes
- **Beginner Workshop**: 2 hours
- **Intermediate Workshop**: 4 hours (recommended)
- **Advanced Workshop**: 6-8 hours (for senior practitioners)

---

## Step 1: Create Required Accounts

### 1.1 Azure Account Setup
**Time Required**: 10 minutes

1. **Create Azure Free Account**:
   - **Navigate to**: `azure.microsoft.com/free`
   - **Click "Start free"** (green button)
   - **Sign in** with Microsoft account or create new one
   - **Provide required information**:
     - Phone number for verification
     - Credit card (for identity verification - won't be charged)
   - **Complete identity verification**

2. **Verify Azure Subscription**:
   - **Go to**: `portal.azure.com`
   - **Click "Subscriptions"** in the left menu
   - **Verify**: You should see "Free Trial" or "Pay-As-You-Go"
   - **Note your Subscription ID** (you'll need this later)

3. **Check Free Tier Limits**:
   - **Application Insights**: 1 GB per month free
   - **Log Analytics**: 5 GB per month free
   - **Azure Monitor**: Basic metrics included
   - **App Service**: 60 CPU minutes per day free

**✅ Checkpoint**: You should be able to access Azure Portal and see your subscription

### 1.2 GitHub Account and Copilot Setup
**Time Required**: 10 minutes

1. **Create/Verify GitHub Account**:
   - **Go to**: `github.com`
   - **Sign up or sign in**
   - **Enable Two-Factor Authentication** (recommended for enterprise)

2. **Get GitHub Copilot Access**:
   - **Go to**: `github.com/features/copilot`
   - **Click "Start free trial"** (30-day trial available)
   - **Choose plan**: Individual ($10/month after trial)
   - **Complete setup**

3. **Verify Copilot Access**:
   - **Go to**: `github.com/settings/copilot`
   - **Verify**: "GitHub Copilot is active"
   - **Note**: You'll configure this in VS Code later

**✅ Checkpoint**: GitHub Copilot trial should be active

### 1.3 Azure SRE Agent Preview Registration
**Time Required**: 5 minutes

1. **Register for Preview**:
   - **Go to**: `aka.ms/sre-agent-preview`
   - **Fill out registration form**
   - **Provide business justification**: "Learning and workshop training"
   - **Note**: Preview access may take 1-2 business days

2. **Alternative for Workshop**:
   - We'll simulate SRE Agent capabilities using standard Azure services
   - Real SRE Agent features will be demonstrated in advanced modules

**✅ Checkpoint**: Registration submitted (access will be verified in advanced modules)

### 1.4 Multi-Cloud Accounts (For Advanced Workshop Only)
**Time Required**: 15 minutes

**AWS Account** (Advanced Workshop Only):
1. **Go to**: `aws.amazon.com/free`
2. **Click "Create a Free Account"**
3. **Complete registration** (requires credit card verification)
4. **Verify email and phone**
5. **Free Tier Includes**:
   - CloudWatch: 10 custom metrics, 5 GB logs
   - EC2: 750 hours t2.micro per month
   - Lambda: 1M free requests per month

**Google Cloud Account** (Advanced Workshop Only):
1. **Go to**: `cloud.google.com/free`
2. **Click "Get started for free"**
3. **Complete registration** (requires credit card verification)
4. **Activate $300 free credit**
5. **Free Tier Includes**:
   - Cloud Monitoring: Basic tier included
   - Compute Engine: 1 f1-micro instance
   - Cloud Functions: 2M invocations per month

**✅ Checkpoint**: For advanced workshop, you should have access to AWS and GCP consoles

### 1.5 Optional Third-Party Accounts
**Time Required**: 10 minutes

**Datadog Free Trial** (Intermediate/Advanced Workshops):
1. **Go to**: `datadoghq.com`
2. **Click "Start Free Trial"**
3. **14-day free trial** includes full features
4. **Note API key** for later integration

**PagerDuty Developer Account** (Advanced Workshop):
1. **Go to**: `developer.pagerduty.com`
2. **Create free developer account**
3. **14-day trial** of full features

**✅ Checkpoint**: Third-party accounts ready for integration exercises

---

## Step 2: Install Required Tools

### 2.1 Install Azure CLI
**Time Required**: 10 minutes

**For Windows:**
```powershell
# Option 1: Using MSI Installer (Recommended)
# Download from: https://aka.ms/installazurecliwindows
# Run the installer and follow prompts

# Option 2: Using PowerShell (if you have admin rights)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'

# Option 3: Using winget
winget install -e --id Microsoft.AzureCLI
```

**For macOS:**
```bash
# Using Homebrew (Recommended)
brew install azure-cli

# Alternative: Using curl
curl -L https://aka.ms/InstallAzureCli | bash
```

**For Linux (Ubuntu/Debian):**
```bash
# Install via apt package manager
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Alternative manual installation
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli
```

**Verify Installation and Login:**
```bash
# Check version
az --version

# Login to Azure
az login

# List subscriptions
az account list --output table

# Set default subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify current subscription
az account show
```

**✅ Checkpoint**: `az --version` should show Azure CLI version and you should be logged in

### 2.2 Install Visual Studio Code and Extensions
**Time Required**: 15 minutes

1. **Install VS Code**:
   - **Download from**: `code.visualstudio.com`
   - **Windows**: Run installer, check "Add to PATH"
   - **macOS**: Drag to Applications folder
   - **Linux**: Follow package manager instructions

2. **Install Essential Extensions via Command Line**:
```bash
# Azure extensions pack
code --install-extension ms-vscode.vscode-node-azure-pack

# Individual Azure extensions
code --install-extension ms-azuretools.vscode-azureappservice
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension ms-azuretools.vscode-azureresourcegroups
code --install-extension ms-azuretools.vscode-docker

# GitHub Copilot
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat

# Monitoring and query tools
code --install-extension ms-mssql.mssql
code --install-extension ms-vscode.vscode-json

# Programming language support
code --install-extension ms-dotnettools.csharp
code --install-extension ms-python.python
code --install-extension ms-vscode.powershell

# Additional productivity tools
code --install-extension ms-vscode.remote-containers
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
```

3. **Configure Azure Extension**:
   - **Open VS Code**
   - **Press `Ctrl+Shift+P`** (Windows/Linux) or `Cmd+Shift+P`** (Mac)
   - **Type**: "Azure: Sign In"
   - **Follow authentication flow**
   - **Verify**: You should see your Azure subscription in Azure extension

4. **Configure GitHub Copilot**:
   - **Press `Ctrl+Shift+P`** and type "GitHub Copilot: Sign In"
   - **Follow authentication flow**
   - **Verify**: Copilot icon should appear in status bar

**✅ Checkpoint**: You should see Azure resources in VS Code Azure extension and Copilot should be active

### 2.3 Install Docker Desktop
**Time Required**: 15 minutes

**For Windows/Mac:**
1. **Download from**: `docker.com/products/docker-desktop`
2. **Install Docker Desktop**
3. **Start Docker Desktop**
4. **Enable Kubernetes** (optional, for advanced modules)

**For Linux:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional, requires logout/login)
sudo usermod -aG docker $USER
```

**Verify Docker Installation:**
```bash
# Check version
docker --version
docker compose version

# Test Docker
docker run hello-world

# Verify Docker is running
docker ps
```

**✅ Checkpoint**: Docker should be running and `docker --version` should work

### 2.4 Install Programming Language Support

#### Option A: Install .NET 8 SDK (Recommended for this workshop)
**Time Required**: 10 minutes

**For Windows:**
```powershell
# Option 1: Download from https://dotnet.microsoft.com/download
# Option 2: Using winget
winget install Microsoft.DotNet.SDK.8

# Option 3: Using Chocolatey
choco install dotnet-8.0-sdk
```

**For macOS:**
```bash
# Using Homebrew
brew install dotnet

# Verify installation
dotnet --info
```

**For Linux:**
```bash
# Ubuntu 22.04
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# Alternative: Using snap
sudo snap install dotnet-sdk --classic --channel=8.0
```

**Verify .NET Installation:**
```bash
# Check version
dotnet --version
# Should show: 8.0.x

# Check installed SDKs
dotnet --list-sdks

# Check runtime
dotnet --list-runtimes

# Create test project
dotnet new console -n TestApp
cd TestApp
dotnet run
```

**✅ Checkpoint**: `dotnet --version` should show 8.0.x

#### Option B: Install Python 3.9+ (Alternative)
**Time Required**: 10 minutes

**For Windows:**
```powershell
# Download from: https://python.org/downloads
# Or use winget
winget install Python.Python.3.11

# Verify installation
python --version
pip --version
```

**For macOS:**
```bash
# Using Homebrew
brew install python@3.11

# Verify installation
python3 --version
pip3 --version
```

**For Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3.11 python3.11-pip python3.11-venv

# Verify installation
python3 --version
pip3 --version
```

**Create Python virtual environment for workshop:**
```bash
# Create virtual environment
python3 -m venv workshop-env

# Activate virtual environment
# On Windows:
workshop-env\Scripts\activate
# On macOS/Linux:
source workshop-env/bin/activate

# Install common packages
pip install flask requests azure-identity azure-monitor-opentelemetry
```

**✅ Checkpoint**: Either `dotnet --version` or `python3 --version` should work

### 2.5 Install Git and Configure
**Time Required**: 10 minutes

**For Windows:**
```powershell
# Download from: https://git-scm.com/download/win
# Or use winget
winget install Git.Git

# Alternative: Using Chocolatey
choco install git
```

**For macOS:**
```bash
# Using Homebrew
brew install git

# Alternative: Xcode Command Line Tools
xcode-select --install
```

**For Linux:**
```bash
# Ubuntu/Debian
sudo apt install git

# CentOS/RHEL/Fedora
sudo dnf install git
```

**Configure Git:**
```bash
# Set global configuration
git config --global user.name "Your Full Name"
git config --global user.email "your.email@example.com"

# Configure line endings (Windows)
git config --global core.autocrlf true

# Configure line endings (macOS/Linux)
git config --global core.autocrlf input

# Set default branch name
git config --global init.defaultBranch main

# Verify configuration
git config --list
```

**✅ Checkpoint**: `git --version` should show version and configuration should be set

### 2.6 Workshop-Specific Tools Setup

#### Install Azure Functions Core Tools
**Time Required**: 5 minutes

```bash
# Windows (using npm)
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# macOS
brew tap azure/functions
brew install azure-functions-core-tools@4

# Linux
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4
```

#### Install Node.js (for some workshop components)
**Time Required**: 5 minutes

```bash
# Windows
winget install OpenJS.NodeJS

# macOS
brew install node

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Verify installations:**
```bash
func --version
node --version
npm --version
```

**✅ Checkpoint**: All development tools should be installed and working

---

## Beginner Workshop (2 hours)

### Introduction: Modern Cloud Observability and Agentic DevOps (15 minutes)

#### The Evolution of Monitoring
**Traditional IT Monitoring (1990s-2000s)**:
- Server room with blinking lights
- Manual log file checking
- Reactive alerts: "Server is down!"
- Mean Time To Detection (MTTD): Hours or days

**Cloud Monitoring (2010s)**:
- Dashboard-driven monitoring
- Automated metrics collection
- Proactive alerting: "CPU usage high"
- MTTD: Minutes to hours

**Modern Observability (2020s)**:
- Three pillars: Metrics, Logs, Traces
- End-to-end system understanding
- Context-aware insights: "Customer checkout failing"
- MTTD: Seconds to minutes

**AI-Enhanced Observability (2024+)**:
- Intelligent agents as team members
- Predictive issue detection
- Automated root cause analysis
- Self-healing systems
- MTTD: Predictive (before issues occur)

#### What is Agentic DevOps?

**Traditional DevOps**: "Union of people, process, and technology to enable continuous delivery"

**Agentic DevOps**: "AI-powered agents operating as members of your dev and ops teams, automating, optimizing, and accelerating every stage of the software lifecycle"

#### The Three Pillars of Observability

1. **Metrics** (What happened?):
   - Numerical measurements over time
   - CPU usage, response times, error rates
   - Good for alerts and trending

2. **Logs** (What happened in detail?):
   - Text records of events
   - Error messages, user actions, system events
   - Good for debugging and investigation

3. **Traces** (How did it happen?):
   - Request flow through distributed systems
   - Shows the journey of a user request
   - Good for understanding dependencies

#### Azure Observability Ecosystem Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Monitor                            │
│                 (Central Platform)                          │
├─────────────────┬──────────────────┬──────────────────────┤
│ Application     │ Log Analytics    │ Azure SRE Agent      │
│ Insights        │ Workspace        │ (AI-Powered)         │
│ (APM)          │ (Logs & Queries) │ (Automated Response) │
├─────────────────┼──────────────────┼──────────────────────┤
│ Metrics        │ Alerts &         │ Dashboards &         │
│ Collection     │ Actions          │ Workbooks            │
└─────────────────┴──────────────────┴──────────────────────┘
```

#### Key Technologies We'll Use Today

1. **Azure Monitor**: Central platform for collecting and analyzing telemetry
2. **Application Insights**: Application performance monitoring (APM)
3. **Log Analytics**: Query and analyze log data with KQL
4. **Azure SRE Agent**: AI-powered site reliability engineering (NEW!)
5. **GitHub Copilot**: AI assistant for writing monitoring queries and troubleshooting

#### Workshop Goals
By the end of today's beginner workshop, you'll have:
- ✅ Set up comprehensive monitoring for a cloud application
- ✅ Created intelligent alerts and custom dashboards
- ✅ Used AI assistance for writing monitoring queries
- ✅ Implemented proactive health checks
- ✅ Built automated incident response workflows
- ✅ Understood the foundations of modern observability

---

## Module 1: Setting Up Your First Monitoring Solution (30 minutes)

### 1.1 Create Resource Group and Basic Resources
**Time Required**: 15 minutes

1. **Set up Workshop Environment Variables**:
```bash
# Set variables for the workshop (customize these values)
RESOURCE_GROUP="observability-workshop-rg"
LOCATION="eastus"
APP_NAME="workshop-app-$(date +%s)"
YOUR_EMAIL="your.email@example.com"

echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "App Name: $APP_NAME"
echo "Your Email: $YOUR_EMAIL"
```

2. **Create Resource Group**:
```bash
# Create resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --tags Environment=Workshop Purpose="Observability Learning"

# Verify creation
az group show --name $RESOURCE_GROUP --output table
```

3. **Create Log Analytics Workspace**:
```bash
# Create Log Analytics workspace (central logging platform)
az monitor log-analytics workspace create \
    --workspace-name "${APP_NAME}-logs" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --retention-in-days 30 \
    --sku PerGB2018

# Get workspace ID and key (we'll need these later)
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --workspace-name "${APP_NAME}-logs" \
    --resource-group $RESOURCE_GROUP \
    --query customerId \
    --output tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --workspace-name "${APP_NAME}-logs" \
    --resource-group $RESOURCE_GROUP \
    --query primarySharedKey \
    --output tsv)

echo "Workspace ID: $WORKSPACE_ID"
echo "Workspace Key: $WORKSPACE_KEY"
```

4. **Create Application Insights Instance**:
```bash
# Create Application Insights (APM platform)
az monitor app-insights component create \
    --app "${APP_NAME}-insights" \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --kind web \
    --application-type web \
    --workspace $WORKSPACE_ID

# Get instrumentation key and connection string
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
    --app "${APP_NAME}-insights" \
    --resource-group $RESOURCE_GROUP \
    --query instrumentationKey \
    --output tsv)

CONNECTION_STRING=$(az monitor app-insights component show \
    --app "${APP_NAME}-insights" \
    --resource-group $RESOURCE_GROUP \
    --query connectionString \
    --output tsv)

echo "Instrumentation Key: $INSTRUMENTATION_KEY"
echo "Connection String: $CONNECTION_STRING"
```

5. **Save Configuration for Later Use**:
```bash
# Create a configuration file for later reference
cat > workshop-config.txt << EOF
# Azure Observability Workshop Configuration
# Generated on: $(date)

RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION
APP_NAME=$APP_NAME
WORKSPACE_ID=$WORKSPACE_ID
INSTRUMENTATION_KEY=$INSTRUMENTATION_KEY
CONNECTION_STRING=$CONNECTION_STRING
YOUR_EMAIL=$YOUR_EMAIL

# Use these values in your application configuration
EOF

echo "Configuration saved to workshop-config.txt"
cat workshop-config.txt
```

**✅ Checkpoint**: You should see both Application Insights and Log Analytics workspace in Azure Portal under your resource group

### 1.2 Deploy Sample Application with Monitoring
**Time Required**: 15 minutes

1. **Create Sample Web Application Directory**:
```bash
# Create project directory
mkdir azure-monitoring-workshop
cd azure-monitoring-workshop

# Create solution structure
mkdir src tests docs
```

2. **Create .NET Web API Application with Monitoring**:
```bash
# Create new web API project
dotnet new webapi --name MonitoringApp --output src/MonitoringApp
cd src/MonitoringApp

# Add Application Insights package
dotnet add package Microsoft.ApplicationInsights.AspNetCore
dotnet add package Microsoft.Extensions.Logging.ApplicationInsights

# Add packages for advanced monitoring
dotnet add package Microsoft.ApplicationInsights.PerfCounterCollector
dotnet add package Microsoft.ApplicationInsights.DependencyCollector
```

3. **Create Program.cs with Comprehensive Monitoring**:

Create or replace `src/MonitoringApp/Program.cs`:
```csharp
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure Application Insights
var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING") 
                      ?? "YOUR_CONNECTION_STRING_HERE";

builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = connectionString;
    options.EnableDependencyTrackingTelemetryModule = true;
    options.EnablePerformanceCounterCollectionModule = true;
    options.EnableEventCounterCollectionModule = true;
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy())
    .AddCheck("database", () => CheckDatabaseConnection())
    .AddCheck("external-api", () => CheckExternalAPIConnection());

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// Health check endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

// Sample endpoints for testing monitoring
app.MapGet("/", () => new { 
    Status = "Running", 
    Timestamp = DateTime.UtcNow,
    Version = "1.0.0",
    Environment = app.Environment.EnvironmentName
});

app.MapGet("/api/test", () => new { 
    Message = "Test endpoint working", 
    RequestId = Activity.Current?.Id ?? Guid.NewGuid().ToString(),
    MachineName = Environment.MachineName
});

app.MapGet("/api/slow", async () => {
    // Simulate slow operation
    var delay = Random.Shared.Next(1000, 3000);
    await Task.Delay(delay);
    return new { 
        Message = "Slow operation completed", 
        DelayMs = delay,
        Timestamp = DateTime.UtcNow
    };
});

app.MapGet("/api/error", () => {
    // Simulate error for testing alerts
    if (Random.Shared.NextDouble() < 0.3) // 30% chance of error
    {
        throw new InvalidOperationException("Simulated error for testing monitoring");
    }
    return new { Message = "Success", Timestamp = DateTime.UtcNow };
});

app.MapGet("/api/memory", () => {
    // Get memory information
    var process = Process.GetCurrentProcess();
    return new {
        WorkingSet = process.WorkingSet64,
        PrivateMemory = process.PrivateMemorySize64,
        VirtualMemory = process.VirtualMemorySize64,
        GCTotalMemory = GC.GetTotalMemory(false),
        GCGen0Collections = GC.CollectionCount(0),
        GCGen1Collections = GC.CollectionCount(1),
        GCGen2Collections = GC.CollectionCount(2)
    };
});

app.Run();

// Helper methods for health checks
static Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult CheckDatabaseConnection()
{
    // Simulate database check
    var isHealthy = Random.Shared.NextDouble() > 0.1; // 90% success rate
    return isHealthy 
        ? Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy("Database connection successful")
        : Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy("Database connection failed");
}

static Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult CheckExternalAPIConnection()
{
    // Simulate external API check
    var isHealthy = Random.Shared.NextDouble() > 0.05; // 95% success rate
    return isHealthy 
        ? Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy("External API responsive")
        : Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy("External API not responding");
}
```

4. **Create appsettings.json Configuration**:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    },
    "ApplicationInsights": {
      "LogLevel": {
        "Default": "Information",
        "Microsoft": "Warning"
      }
    }
  },
  "AllowedHosts": "*",
  "ApplicationInsights": {
    "InstrumentationKey": "",
    "ConnectionString": ""
  }
}
```

5. **Test Application Locally**:
```bash
# Replace placeholder with actual connection string
sed -i "s/YOUR_CONNECTION_STRING_HERE/$CONNECTION_STRING/g" Program.cs

# Or set environment variable
export APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING"

# Build and run the application
dotnet build
dotnet run

# In another terminal, test the endpoints
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/api/test
curl http://localhost:5000/api/memory

# Generate some traffic and errors for monitoring
for i in {1..10}; do
  curl http://localhost:5000/api/test
  curl http://localhost:5000/api/slow
  curl http://localhost:5000/api/error
  sleep 1
done
```

6. **Verify Telemetry in Azure Portal**:
   - **Go to Azure Portal** → **Application Insights**
   - **Click on your Application Insights resource**
   - **Wait 2-3 minutes** for telemetry to appear
   - **Check "Live Metrics"** - you should see real-time data
   - **Check "Application Map"** - shows application topology
   - **Check "Performance"** - shows response times and throughput

**✅ Checkpoint**: 
- Your application should be running locally
- Telemetry should appear in Application Insights Live Metrics
- Health checks should return successful responses
- API endpoints should respond correctly

### Workshop Progress Check
At this point, you have:
- ✅ Created Azure monitoring infrastructure (Log Analytics + Application Insights)
- ✅ Built a sample application with comprehensive telemetry
- ✅ Verified telemetry is flowing to Azure Monitor
- ✅ Set up health checks and monitoring endpoints

**Continue to Part 2** for:
- Creating custom dashboards and intelligent alerts
- AI-assisted troubleshooting with GitHub Copilot
- Proactive monitoring implementation
- Introduction to Azure SRE Agent

---

## Next Steps

**Part 2 - Beginner Workshop Modules 2-5** will cover:
- Module 2: Creating Your First Dashboard and Alerts (25 minutes)
- Module 3: AI-Assisted Troubleshooting with GitHub Copilot (30 minutes)
- Module 4: Implementing Proactive Monitoring (35 minutes)
- Module 5: Introduction to Azure SRE Agent (15 minutes)

**Ready for Part 2?** Ensure you have:
- ✅ Application running and sending telemetry
- ✅ Azure resources created successfully
- ✅ GitHub Copilot active in VS Code
- ✅ Basic understanding of observability concepts

**Troubleshooting**: If you encounter issues, check the troubleshooting section in Part 5 or review the configuration values in your `workshop-config.txt` file.