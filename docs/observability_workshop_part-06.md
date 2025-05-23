# 🚀 Complete Azure Observability Workshop Guide - Part 6
## 🤖 Service Mesh & AI-Enhanced SRE Agent (2.5 hours)

### ✅ Prerequisites Check
Before starting Part 6, ensure you have completed Part 5 and have:
- ✅ Enterprise Kubernetes cluster running (AKS)
- ✅ Prometheus and Grafana observability stack deployed
- ✅ Azure Monitor integration configured
- ✅ All pods in `observability` namespace are running
- ✅ Port forwards active for Prometheus (9090) and Grafana (3000)

---

## 🕸️ Module 1.2: Service Mesh Advanced Observability (75 minutes)

### ⚙️ Step 1: Install and Configure Istio Service Mesh
**Time Required**: 45 minutes

1. **📦 Download and Install Istio**:
```bash
# 📦 Download Istio service mesh platform
echo "📦 Downloading Istio v1.19.0 for enterprise service mesh..."
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.19.0 sh -
cd istio-1.19.0
export PATH=$PWD/bin:$PATH

# ✅ Verify Istio CLI installation
echo "✅ Verifying Istio installation..."
istioctl version --remote=false

# 🏢 Install Istio with enterprise configuration for production
echo "🏢 Installing Istio with enterprise observability settings..."
istioctl install --set values.defaultRevision=default \
  --set values.pilot.traceSampling=100.0 \
  --set values.global.meshID=enterprise-mesh \
  --set values.global.network=aks-network \
  --set values.pilot.env.EXTERNAL_ISTIOD=false \
  --set values.telemetry.v2.prometheus.service_monitor.enabled=true \
  --set values.defaultRevision=default

# ✅ Verify Istio installation in cluster
echo "✅ Verifying Istio deployment in Kubernetes..."
kubectl get pods -n istio-system
kubectl get svc -n istio-system

# Expected output: istiod and istio-proxy pods running
echo "✅ Istio service mesh installation completed successfully!"
```

2. **📊 Install Istio Observability Add-ons**:
```bash
# Install observability add-ons
kubectl apply -f samples/addons/jaeger.yaml
kubectl apply -f samples/addons/kiali.yaml
kubectl apply -f samples/addons/prometheus.yaml
kubectl apply -f samples/addons/grafana.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system

# Verify add-ons
kubectl get pods -n istio-system | grep -E "(jaeger|kiali|prometheus|grafana)"
```

3. **Configure Advanced Istio Telemetry**:

Create `istio-telemetry-config.yaml`:
```yaml
# Enhanced Telemetry Configuration
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: enterprise-telemetry
spec:
  meshConfig:
    defaultConfig:
      proxyStatsMatcher:
        inclusionRegexps:
        - ".*outlier_detection.*"
        - ".*circuit_breakers.*"
        - ".*upstream_rq_retry.*"
        - ".*upstream_rq_pending.*"
        - ".*_cx_.*"
        exclusionRegexps:
        - ".*osconfig.*"
      tracing:
        zipkin:
          address: jaeger-collector.istio-system:9411
        sampling: 100.0
        custom_tags:
          environment:
            literal:
              value: "enterprise"
          business_unit:
            header:
              name: "x-business-unit"
          tenant_id:
            header:
              name: "x-tenant-id"
          request_id:
            header:
              name: "x-request-id"
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            metric_relabeling_configs:
            - source_labels: [__name__]
              regex: 'istio_request_duration_milliseconds_bucket'
              target_label: __name__
              replacement: 'istio_request_duration_seconds_bucket'
        enabled: true
---
# Custom Telemetry for Business Metrics
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: business-metrics
  namespace: istio-system
spec:
  metrics:
  - providers:
    - name: prometheus
  - overrides:
    - match:
        metric: ALL_METRICS
      tagOverrides:
        request_protocol:
          operation: UPSERT
          value: |
            has(request.headers["x-forwarded-proto"]) ? request.headers["x-forwarded-proto"] : "http"
        business_unit:
          operation: UPSERT
          value: |
            has(request.headers["x-business-unit"]) ? request.headers["x-business-unit"] : "unknown"
        customer_tier:
          operation: UPSERT
          value: |
            has(request.headers["x-customer-tier"]) ? request.headers["x-customer-tier"] : "standard"
---
# Enhanced Access Logging
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: enhanced-access-log
  namespace: istio-system
spec:
  accessLogging:
  - providers:
    - name: otel
  - filter:
      expression: 'response.code >= 400'
```

4. **Apply Telemetry Configuration**:
```bash
kubectl apply -f istio-telemetry-config.yaml

# Enable sidecar injection for namespaces
kubectl label namespace default istio-injection=enabled
kubectl create namespace production
kubectl create namespace staging
kubectl label namespace production istio-injection=enabled
kubectl label namespace staging istio-injection=enabled

# Verify telemetry configuration
istioctl proxy-config cluster deploy/istio-proxy -n istio-system
```

### Step 2: Deploy Enterprise Microservices with Advanced Tracing
**Time Required**: 30 minutes

1. **Create Enterprise Application Manifests**:

Create `enterprise-microservices.yaml`:
```yaml
# Production Namespace Applications
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service-v2
  namespace: production
  labels:
    app: user-service
    version: v2
    tier: backend
    slo.target: "99.9"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
      version: v2
  template:
    metadata:
      labels:
        app: user-service
        version: v2
        tier: backend
        slo.target: "99.9"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: user-service
        image: nginx:1.21  # Using nginx as a simple example
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "user-service"
        - name: SERVICE_VERSION
          value: "v2"
        - name: BUSINESS_UNIT
          value: "customer-experience"
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: config
        configMap:
          name: user-service-config
---
# User Service ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-service-config
  namespace: production
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        # Add custom headers for tracing
        add_header X-Service-Name "user-service";
        add_header X-Service-Version "v2";
        add_header X-Business-Unit "customer-experience";
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        
        location /health/live {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        location /health/ready {
            access_log off;
            return 200 "ready\n";
            add_header Content-Type text/plain;
        }
        
        location /metrics {
            stub_status on;
            access_log off;
        }
    }
---
# User Service
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: production
  labels:
    app: user-service
    service: user-service
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
---
# Order Service Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-v2
  namespace: production
  labels:
    app: order-service
    version: v2
    tier: backend
    slo.target: "99.5"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
      version: v2
  template:
    metadata:
      labels:
        app: order-service
        version: v2
        tier: backend
        slo.target: "99.5"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: order-service
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "order-service"
        - name: SERVICE_VERSION
          value: "v2"
        - name: BUSINESS_UNIT
          value: "commerce"
        - name: USER_SERVICE_URL
          value: "http://user-service.production.svc.cluster.local"
        resources:
          requests:
            memory: "128Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: config
        configMap:
          name: order-service-config
---
# Order Service ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
  namespace: production
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        # Add custom headers for tracing
        add_header X-Service-Name "order-service";
        add_header X-Service-Version "v2";
        add_header X-Business-Unit "commerce";
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        
        location /api/orders {
            # Simulate order processing
            add_header Content-Type application/json;
            return 200 '{"orderId": "12345", "status": "processing", "service": "order-service-v2"}';
        }
        
        location /health/live {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        location /health/ready {
            access_log off;
            return 200 "ready\n";
            add_header Content-Type text/plain;
        }
        
        location /metrics {
            stub_status on;
            access_log off;
        }
    }
---
# Order Service
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: production
  labels:
    app: order-service
    service: order-service
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
---
# Istio Gateway
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: enterprise-gateway
  namespace: production
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "api.enterprise.local"
    - "*.enterprise.local"
---
# Virtual Service for Advanced Routing
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: enterprise-api
  namespace: production
spec:
  hosts:
  - "api.enterprise.local"
  gateways:
  - enterprise-gateway
  http:
  # Canary routing based on headers
  - match:
    - headers:
        "x-canary":
          exact: "true"
    route:
    - destination:
        host: user-service.production.svc.cluster.local
        subset: v2
      weight: 100
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
  # Customer tier-based routing
  - match:
    - headers:
        "x-customer-tier":
          exact: "premium"
    route:
    - destination:
        host: user-service.production.svc.cluster.local
        subset: premium
      weight: 100
  # Default routing
  - route:
    - destination:
        host: user-service.production.svc.cluster.local
        subset: v2
      weight: 100
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
---
# Destination Rule for Load Balancing and Circuit Breaking
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: user-service
  namespace: production
spec:
  host: user-service.production.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 10
        maxRequestsPerConnection: 2
        consecutiveGatewayErrors: 5
        interval: 30s
        baseEjectionTime: 30s
        maxEjectionPercent: 50
    outlierDetection:
      consecutive5xxErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
  - name: v2
    labels:
      version: v2
  - name: premium
    labels:
      version: v2
      tier: premium
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 200
        http:
          http1MaxPendingRequests: 20
```

2. **Deploy and Test Enterprise Services**:
```bash
# Apply enterprise microservices
kubectl apply -f enterprise-microservices.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment --all -n production

# Get ingress gateway IP
INGRESS_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"

# Test the services with advanced headers
curl -H "Host: api.enterprise.local" \
     -H "x-business-unit: customer-experience" \
     -H "x-customer-tier: premium" \
     -H "x-request-id: test-$(date +%s)" \
     http://$INGRESS_IP/

# Test order service
curl -H "Host: api.enterprise.local" \
     -H "x-business-unit: commerce" \
     http://$INGRESS_IP/api/orders

# Generate load for observability
for i in {1..50}; do
  curl -s -H "Host: api.enterprise.local" \
       -H "x-business-unit: commerce" \
       -H "x-customer-tier: standard" \
       -H "x-request-id: load-test-$i" \
       http://$INGRESS_IP/ > /dev/null
done
```

3. **Access Advanced Observability Tools**:
```bash
# Port forward to access Istio tools
kubectl port-forward -n istio-system svc/kiali 20001:20001 &
kubectl port-forward -n istio-system svc/jaeger 16686:16686 &

echo "Kiali (Service Mesh Dashboard): http://localhost:20001"
echo "Jaeger (Distributed Tracing): http://localhost:16686"
echo "Grafana (Metrics Visualization): http://localhost:3000"
```

**✅ Checkpoint**: Service mesh should show distributed tracing and advanced traffic management

---

## 🤖 Module 2: AI-Enhanced SRE Agent Implementation (75 minutes)

### 🎆 Step 1: Azure SRE Agent Setup
**Time Required**: 45 minutes

1. **Register for Azure SRE Agent Preview**:
```bash
# Note: Azure SRE Agent is in preview - registration required
# Visit: https://aka.ms/SREAgentPreview to register

# Install Azure CLI extensions (if needed)
az extension add --name application-insights
az extension add --name log-analytics

# Verify subscription access
az account show
```

2. **Create SRE Agent Configuration**:

Create `sre-agent-config.yaml`:
```yaml
# SRE Agent Service Account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sre-agent
  namespace: observability
  annotations:
    azure.workload.identity/client-id: "YOUR_CLIENT_ID"  # Replace with actual client ID
---
# SRE Agent ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: sre-agent-config
  namespace: observability
data:
  config.yaml: |
    sre_agent:
      enabled: true
      environment: "enterprise"
      cluster_name: "aks-enterprise"
      
    azure_monitor:
      connection_string: "${APPLICATIONINSIGHTS_CONNECTION_STRING}"
      workspace_id: "${LOG_ANALYTICS_WORKSPACE_ID}"
      
    alert_management:
      enabled: true
      auto_acknowledge: true
      escalation_threshold: 3
      
    incident_response:
      enabled: true
      auto_remediation: true
      approval_required: true
      
    health_models:
      - name: "user-service"
        namespace: "production"
        slo_target: 99.9
        critical_metrics:
          - "request_success_rate"
          - "response_time_p95"
          - "error_rate"
        dependencies:
          - "order-service"
          
      - name: "order-service"
        namespace: "production"
        slo_target: 99.5
        critical_metrics:
          - "request_success_rate"
          - "response_time_p95"
          - "error_rate"
          
    automation_rules:
      - name: "high_cpu_scale_out"
        trigger: "cpu_usage > 80%"
        action: "scale_deployment"
        parameters:
          replicas: "+2"
          max_replicas: 10
          
      - name: "high_error_rate_rollback"
        trigger: "error_rate > 5%"
        action: "rollback_deployment"
        parameters:
          previous_version: true
          
      - name: "memory_leak_restart"
        trigger: "memory_usage > 90%"
        action: "restart_pods"
        parameters:
          rolling_restart: true
          
    notifications:
      slack:
        webhook_url: "${SLACK_WEBHOOK_URL}"
        channel: "#sre-alerts"
      teams:
        webhook_url: "${TEAMS_WEBHOOK_URL}"
      email:
        smtp_server: "smtp.office365.com"
        recipients:
          - "sre-team@company.com"
---
# SRE Agent Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sre-agent
  namespace: observability
  labels:
    app: sre-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sre-agent
  template:
    metadata:
      labels:
        app: sre-agent
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: sre-agent
      containers:
      - name: sre-agent
        image: mcr.microsoft.com/azure-sre-agent:preview  # Preview image
        env:
        - name: APPLICATIONINSIGHTS_CONNECTION_STRING
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: connection-string
        - name: LOG_ANALYTICS_WORKSPACE_ID
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: workspace-id
        - name: SLACK_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: slack-webhook
              optional: true
        - name: TEAMS_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: teams-webhook
              optional: true
        - name: AZURE_CLIENT_ID
          value: "YOUR_CLIENT_ID"  # Replace with actual client ID
        - name: AZURE_TENANT_ID
          value: "YOUR_TENANT_ID"  # Replace with actual tenant ID
        volumeMounts:
        - name: config
          mountPath: /etc/sre-agent
        - name: cache
          mountPath: /var/cache/sre-agent
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
      volumes:
      - name: config
        configMap:
          name: sre-agent-config
      - name: cache
        emptyDir: {}
---
# SRE Agent Service
apiVersion: v1
kind: Service
metadata:
  name: sre-agent
  namespace: observability
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: sre-agent
---
# SRE Agent ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sre-agent
rules:
- apiGroups: [""]
  resources:
  - pods
  - services
  - endpoints
  - events
  - configmaps
  - secrets
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["apps"]
  resources:
  - deployments
  - replicasets
  - statefulsets
  - daemonsets
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["metrics.k8s.io"]
  resources:
  - pods
  - nodes
  verbs: ["get", "list"]
- apiGroups: ["networking.istio.io"]
  resources:
  - virtualservices
  - destinationrules
  - gateways
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---
# SRE Agent ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sre-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sre-agent
subjects:
- kind: ServiceAccount
  name: sre-agent
  namespace: observability
```

3. **Create Required Secrets**:
```bash
# Get Azure credentials from Terraform output
WORKSPACE_ID=$(terraform output -raw log_analytics_workspace_id)
CONNECTION_STRING=$(terraform output -raw application_insights_connection_string)

# Create secrets for SRE Agent
kubectl create secret generic azure-secrets \
  --from-literal=workspace-id="$WORKSPACE_ID" \
  --from-literal=connection-string="$CONNECTION_STRING" \
  -n observability

# Optional: Create notification secrets (replace with your webhooks)
kubectl create secret generic notification-secrets \
  --from-literal=slack-webhook="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
  --from-literal=teams-webhook="https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK" \
  -n observability
```

4. **Deploy SRE Agent (Simulated)**:
```bash
# Note: Since Azure SRE Agent is in preview, we'll simulate with a monitoring pod
# Replace the image with the actual SRE Agent image when available

# Create a simulated SRE agent for demonstration
cat > sre-agent-sim.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sre-agent-simulator
  namespace: observability
  labels:
    app: sre-agent-simulator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sre-agent-simulator
  template:
    metadata:
      labels:
        app: sre-agent-simulator
    spec:
      containers:
      - name: sre-agent-sim
        image: alpine:3.18
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo 'SRE Agent monitoring cluster...'; sleep 30; done"]
        env:
        - name: CLUSTER_NAME
          value: "aks-enterprise"
        - name: ENVIRONMENT
          value: "enterprise"
        resources:
          requests:
            memory: "64Mi"
            cpu: "10m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: sre-agent-simulator
  namespace: observability
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: sre-agent-simulator
EOF

kubectl apply -f sre-agent-sim.yaml
```

### Step 2: Intelligent Alerting and Automation
**Time Required**: 30 minutes

1. **Create Intelligent Alert Rules**:

Create `intelligent-alerts.yaml`:
```yaml
# PrometheusRule for Intelligent Alerting
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: enterprise-intelligent-alerts
  namespace: observability
  labels:
    app: prometheus
spec:
  groups:
  - name: sre.intelligent.rules
    interval: 30s
    rules:
    # SLO-based alerting
    - alert: ServiceSLOBreach
      expr: |
        (
          sum(rate(istio_requests_total{reporter="destination",destination_service_name!="unknown"}[5m])) by (destination_service_name, destination_service_namespace) -
          sum(rate(istio_requests_total{reporter="destination",destination_service_name!="unknown",response_code!~"5.*"}[5m])) by (destination_service_name, destination_service_namespace)
        ) / sum(rate(istio_requests_total{reporter="destination",destination_service_name!="unknown"}[5m])) by (destination_service_name, destination_service_namespace) * 100 > 0.1
      for: 2m
      labels:
        severity: critical
        team: sre
        automation: "true"
        slo_target: "99.9"
      annotations:
        summary: "Service {{ $labels.destination_service_name }} SLO breach"
        description: "Service {{ $labels.destination_service_name }} in namespace {{ $labels.destination_service_namespace }} has error rate above SLO target"
        runbook_url: "https://wiki.company.com/runbooks/slo-breach"
        automation_action: "rollback_deployment"
        
    # Predictive scaling alert
    - alert: PredictiveScalingNeeded
      expr: |
        predict_linear(
          avg_over_time(
            sum(rate(istio_requests_total{reporter="destination"}[1m])) by (destination_service_name)[5m:]
          )[30m:], 600
        ) > 1000
      for: 1m
      labels:
        severity: warning
        team: sre
        automation: "true"
      annotations:
        summary: "Predictive scaling needed for {{ $labels.destination_service_name }}"
        description: "Based on current trends, {{ $labels.destination_service_name }} will need scaling in the next 10 minutes"
        automation_action: "scale_deployment"
        scale_factor: "1.5"
        
    # Anomaly detection alert
    - alert: ResponseTimeAnomaly
      expr: |
        (
          histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket{reporter="destination"}[5m])) by (destination_service_name, le)) -
          avg_over_time(histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket{reporter="destination"}[5m])) by (destination_service_name, le))[1h:])
        ) / avg_over_time(histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket{reporter="destination"}[5m])) by (destination_service_name, le))[1h:]) * 100 > 50
      for: 3m
      labels:
        severity: warning
        team: development
        automation: "true"
      annotations:
        summary: "Response time anomaly detected for {{ $labels.destination_service_name }}"
        description: "95th percentile response time is 50% higher than historical average"
        automation_action: "investigate_performance"
        
    # Resource exhaustion prediction
    - alert: ResourceExhaustionPredicted
      expr: |
        predict_linear(
          avg_over_time(
            (1 - (avg(node_memory_MemAvailable_bytes) / avg(node_memory_MemTotal_bytes)))[5m:]
          )[30m:], 3600
        ) > 0.9
      for: 5m
      labels:
        severity: critical
        team: platform
        automation: "true"
      annotations:
        summary: "Node memory exhaustion predicted within 1 hour"
        description: "Based on current memory consumption trends, nodes will run out of memory within 1 hour"
        automation_action: "add_nodes"
        
    # Circuit breaker triggered
    - alert: CircuitBreakerTriggered
      expr: |
        sum(rate(istio_request_total{source_app!="unknown",response_flags=~".*UO.*"}[5m])) by (source_app, destination_service_name) > 0
      for: 1m
      labels:
        severity: warning
        team: sre
        automation: "true"
      annotations:
        summary: "Circuit breaker triggered between {{ $labels.source_app }} and {{ $labels.destination_service_name }}"
        description: "Circuit breaker has been triggered, indicating potential issues with {{ $labels.destination_service_name }}"
        automation_action: "check_dependency_health"
        
    # Business impact alert
    - alert: BusinessImpactDetected
      expr: |
        sum(rate(istio_requests_total{destination_service_name="order-service",response_code=~"5.*"}[5m])) / sum(rate(istio_requests_total{destination_service_name="order-service"}[5m])) * 100 > 1
      for: 1m
      labels:
        severity: critical
        team: business
        automation: "true"
        business_unit: "commerce"
      annotations:
        summary: "Business impact detected - Order service errors"
        description: "Order service error rate above 1% - this directly impacts revenue"
        automation_action: "emergency_rollback"
        estimated_revenue_impact: "$1000/minute"
---
# AlertManager Configuration for Intelligent Routing
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: observability
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'smtp.office365.com:587'
      smtp_from: 'alerts@company.com'
      
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'sre-team'
      routes:
      # Business critical alerts
      - match:
          severity: critical
          business_unit: commerce
        receiver: 'business-critical'
        group_wait: 0s
        repeat_interval: 5m
        
      # Automation-enabled alerts
      - match:
          automation: "true"
        receiver: 'sre-automation'
        group_wait: 5s
        
      # Platform alerts
      - match:
          team: platform
        receiver: 'platform-team'
        
      # Development alerts  
      - match:
          team: development
        receiver: 'dev-team'
        
    receivers:
    - name: 'sre-team'
      email_configs:
      - to: 'sre-team@company.com'
        subject: 'SRE Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Severity: {{ .Labels.severity }}
          {{ end }}
          
    - name: 'business-critical'
      email_configs:
      - to: 'business-critical@company.com'
        subject: 'BUSINESS CRITICAL: {{ .GroupLabels.alertname }}'
      slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#business-critical'
        title: 'Business Critical Alert'
        text: '{{ .CommonAnnotations.summary }}'
        
    - name: 'sre-automation'
      webhook_configs:
      - url: 'http://sre-agent.observability.svc.cluster.local:8080/webhook'
        send_resolved: true
        
    - name: 'platform-team'
      email_configs:
      - to: 'platform-team@company.com'
        
    - name: 'dev-team'
      email_configs:
      - to: 'dev-team@company.com'
        
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'cluster', 'service']
```

2. **Deploy Intelligent Alerting**:
```bash
# Apply intelligent alerts
kubectl apply -f intelligent-alerts.yaml

# Verify prometheus rules
kubectl get prometheusrules -n observability

# Check if alerts are loading
kubectl port-forward -n observability svc/prometheus 9090:9090 &
curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.type=="alerting") | .name'
```

**✅ Checkpoint**: Service mesh and AI-enhanced monitoring should be operational with intelligent alerting

---

## Next Steps

In **Part 7**, we will continue with:
- **Module 3**: Multi-Cloud Integration (AWS/GCP connectivity)
- **Module 4**: Advanced Troubleshooting Scenarios
- **Module 5**: Compliance and Governance

Your enterprise service mesh with AI-enhanced observability is now ready for multi-cloud expansion!

---

## Validation Commands

Before proceeding to Part 7:

```bash
# Check Istio installation
istioctl proxy-status
kubectl get pods -n istio-system

# Verify service mesh traffic
kubectl get virtualservices,destinationrules -n production

# Test distributed tracing
curl -H "Host: api.enterprise.local" \
     -H "x-request-id: trace-test-$(date +%s)" \
     http://$INGRESS_IP/

# Check SRE agent simulation
kubectl logs -n observability deployment/sre-agent-simulator --tail=10

# Verify intelligent alerts
curl http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | .labels.alertname'
```

All components should be healthy and generating observability data before continuing.


---

## 🔙 Navigation

**[⬅️ Back to Main README](../README.md)**
