#!/bin/bash

# Azure Observability Workshop - Applications Deployment Script
# This script builds and deploys sample applications for the workshop

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
OUTPUTS_FILE="$PROJECT_ROOT/workshop-outputs.env"

log "Starting applications deployment..."

# Source the outputs file if it exists
if [ -f "$OUTPUTS_FILE" ]; then
    source "$OUTPUTS_FILE"
    log "Loaded deployment outputs from $OUTPUTS_FILE"
else
    warn "Outputs file not found at $OUTPUTS_FILE"
    warn "Make sure you've run deploy-infrastructure.sh first"
fi

# Check required environment variables
if [ -z "${ACR_NAME:-}" ]; then
    error "ACR_NAME not set. Please run deploy-infrastructure.sh first or set ACR_NAME manually."
fi

if [ -z "${APP_INSIGHTS_KEY:-}" ]; then
    warn "APP_INSIGHTS_KEY not set. Application Insights integration may not work."
fi

# Check if kubectl is available and connected
if ! kubectl cluster-info &> /dev/null; then
    error "kubectl is not configured or cluster is not accessible"
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker to build application images."
fi

# Login to ACR
log "Logging into Azure Container Registry..."
az acr login --name "$ACR_NAME"

# Create applications namespace if it doesn't exist
log "Creating applications namespace..."
kubectl create namespace applications --dry-run=client -o yaml | kubectl apply -f -

# Build and push .NET sample application
DOTNET_APP_DIR="$PROJECT_ROOT/applications/dotnet-sample"
log "Building .NET sample application..."

cd "$DOTNET_APP_DIR"

# Build Docker image
DOTNET_IMAGE="$ACR_NAME.azurecr.io/dotnet-sample-app:latest"
log "Building Docker image: $DOTNET_IMAGE"
docker build -t "$DOTNET_IMAGE" .

# Push image to ACR
log "Pushing image to ACR..."
docker push "$DOTNET_IMAGE"

# Update Kubernetes deployment with correct image and App Insights key
KUBERNETES_DIR="$PROJECT_ROOT/kubernetes"
TEMP_DEPLOYMENT="/tmp/dotnet-sample-app.yaml"

log "Preparing Kubernetes deployment..."
cp "$KUBERNETES_DIR/applications/dotnet-sample-app.yaml" "$TEMP_DEPLOYMENT"

# Replace image name in deployment
sed -i.bak "s|image: dotnet-sample-app:latest|image: $DOTNET_IMAGE|g" "$TEMP_DEPLOYMENT"

# Update Application Insights connection string if available
if [ -n "${APP_INSIGHTS_KEY:-}" ]; then
    # Create a proper connection string
    CONNECTION_STRING="InstrumentationKey=${APP_INSIGHTS_KEY};IngestionEndpoint=https://eastus2-3.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus2.livediagnostics.monitor.azure.com/"
    
    # Update the secret in the deployment
    sed -i.bak "s|connection-string: \".*\"|connection-string: \"$CONNECTION_STRING\"|g" "$TEMP_DEPLOYMENT"
fi

# Deploy .NET sample application
log "Deploying .NET sample application..."
kubectl apply -f "$TEMP_DEPLOYMENT"

# Build and deploy microservices
log "Building and deploying microservices..."

# User Service
USER_SERVICE_DIR="$PROJECT_ROOT/applications/user-service"
USER_IMAGE="$ACR_NAME.azurecr.io/user-service:latest"

log "Building User Service..."
cd "$USER_SERVICE_DIR"

# Create a simple Dockerfile for User Service
cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["UserService.csproj", "."]
RUN dotnet restore "./UserService.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "UserService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "UserService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "UserService.dll"]
EOF

# Create project file for User Service
cat > UserService.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="OpenTelemetry" Version="1.6.0" />
    <PackageReference Include="OpenTelemetry.Extensions.Hosting" Version="1.6.0" />
    <PackageReference Include="OpenTelemetry.Instrumentation.AspNetCore" Version="1.5.1-beta.1" />
    <PackageReference Include="OpenTelemetry.Instrumentation.Http" Version="1.5.1-beta.1" />
    <PackageReference Include="OpenTelemetry.Exporter.Jaeger" Version="1.5.1" />
  </ItemGroup>
</Project>
EOF

docker build -t "$USER_IMAGE" .
docker push "$USER_IMAGE"

# Order Service
ORDER_SERVICE_DIR="$PROJECT_ROOT/applications/order-service"
ORDER_IMAGE="$ACR_NAME.azurecr.io/order-service:latest"

log "Building Order Service..."
cd "$ORDER_SERVICE_DIR"

# Create project file and Dockerfile for Order Service (similar to User Service)
cat > OrderService.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="OpenTelemetry" Version="1.6.0" />
    <PackageReference Include="OpenTelemetry.Extensions.Hosting" Version="1.6.0" />
    <PackageReference Include="OpenTelemetry.Instrumentation.AspNetCore" Version="1.5.1-beta.1" />
    <PackageReference Include="OpenTelemetry.Instrumentation.Http" Version="1.5.1-beta.1" />
    <PackageReference Include="OpenTelemetry.Exporter.Jaeger" Version="1.5.1" />
  </ItemGroup>
</Project>
EOF

cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["OrderService.csproj", "."]
RUN dotnet restore "./OrderService.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "OrderService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "OrderService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "OrderService.dll"]
EOF

docker build -t "$ORDER_IMAGE" .
docker push "$ORDER_IMAGE"

# Create Kubernetes deployments for microservices
log "Creating microservices deployments..."

# User Service deployment
cat > /tmp/user-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: applications
  labels:
    app: user-service
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
      version: v1
  template:
    metadata:
      labels:
        app: user-service
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "80"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: user-service
        image: $USER_IMAGE
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ORDER_SERVICE_URL
          value: "http://order-service"
        - name: OTEL_EXPORTER_JAEGER_ENDPOINT
          value: "http://jaeger-collector.jaeger-system:14268/api/traces"
        - name: OTEL_SERVICE_NAME
          value: "user-service"
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
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: applications
  labels:
    app: user-service
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
    app: user-service
EOF

# Order Service deployment
cat > /tmp/order-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: applications
  labels:
    app: order-service
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
      version: v1
  template:
    metadata:
      labels:
        app: order-service
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "80"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: order-service
        image: $ORDER_IMAGE
        ports:
        - containerPort: 80
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: USER_SERVICE_URL
          value: "http://user-service"
        - name: OTEL_EXPORTER_JAEGER_ENDPOINT
          value: "http://jaeger-collector.jaeger-system:14268/api/traces"
        - name: OTEL_SERVICE_NAME
          value: "order-service"
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
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: applications
  labels:
    app: order-service
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
    app: order-service
EOF

# Deploy microservices
log "Deploying microservices..."
kubectl apply -f /tmp/user-service.yaml
kubectl apply -f /tmp/order-service.yaml

# Wait for deployments to be ready
log "Waiting for applications to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/dotnet-sample-app -n applications
kubectl wait --for=condition=available --timeout=300s deployment/user-service -n applications
kubectl wait --for=condition=available --timeout=300s deployment/order-service -n applications

# Verify deployments
log "Verifying application deployments..."
kubectl get pods -n applications
kubectl get services -n applications

# Create load testing script
log "Creating load testing script..."
cat > "$SCRIPT_DIR/helpers/generate-load.sh" << 'EOF'
#!/bin/bash

# Generate load on deployed applications
echo "Generating load on applications..."
echo "Press Ctrl+C to stop"

# Port forward services in background
kubectl port-forward -n applications svc/dotnet-sample-app 8080:80 &
PF_PID1=$!
kubectl port-forward -n applications svc/user-service 8081:80 &
PF_PID2=$!
kubectl port-forward -n applications svc/order-service 8082:80 &
PF_PID3=$!

# Wait for port forwards to establish
sleep 5

# Function to cleanup background processes
cleanup() {
    echo "Stopping port forwards..."
    kill $PF_PID1 $PF_PID2 $PF_PID3 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# Generate load
while true; do
    # Hit various endpoints
    curl -s http://localhost:8080/api/users > /dev/null &
    curl -s http://localhost:8080/api/orders > /dev/null &
    curl -s http://localhost:8081/api/users > /dev/null &
    curl -s http://localhost:8082/api/orders > /dev/null &
    
    # Simulate some errors
    curl -s http://localhost:8080/api/simulate-error > /dev/null &
    curl -s http://localhost:8080/api/simulate-delay > /dev/null &
    
    echo "Generated requests at $(date)"
    sleep 2
done
EOF

chmod +x "$SCRIPT_DIR/helpers/generate-load.sh"

log "Applications deployment completed successfully!"
log ""
log "Deployed applications:"
log "✓ .NET Sample Application (dotnet-sample-app)"
log "✓ User Service (user-service)"
log "✓ Order Service (order-service)"
log ""
log "All applications are instrumented with:"
log "- OpenTelemetry for distributed tracing"
log "- Prometheus metrics"
log "- Health checks"
log "- Application Insights integration"
log ""
log "Load testing script created: $SCRIPT_DIR/helpers/generate-load.sh"
log ""
log "To access applications, use port forwarding:"
log "kubectl port-forward -n applications svc/dotnet-sample-app 8080:80"
log "kubectl port-forward -n applications svc/user-service 8081:80"
log "kubectl port-forward -n applications svc/order-service 8082:80"
log ""
log "Application URLs (after port-forwarding):"
log "- Main App: http://localhost:8080"
log "- User Service: http://localhost:8081/api/users"
log "- Order Service: http://localhost:8082/api/orders"