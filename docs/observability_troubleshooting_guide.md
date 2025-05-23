# 🔧 Azure Observability Workshop - Troubleshooting Guide

## 🆘 Quick Reference for Common Issues

This comprehensive troubleshooting guide helps you resolve common issues encountered during the Azure Observability Workshop. Use this as your first resource when encountering problems.

---

## 📋 Table of Contents

1. [⚙️ Prerequisites and Setup Issues](#prerequisites-and-setup-issues)
2. [☁️ Azure Resource Deployment Problems](#azure-resource-deployment-problems)
3. [🚀 Kubernetes and Container Issues](#kubernetes-and-container-issues)
4. [🌐 Service Mesh (Istio) Problems](#service-mesh-istio-problems)
5. [📊 Monitoring Stack Issues](#monitoring-stack-issues)
6. [📱 Application and Connectivity Problems](#application-and-connectivity-problems)
7. [⚡ Performance and Resource Issues](#performance-and-resource-issues)
8. [🌐 Multi-Cloud Integration Problems](#multi-cloud-integration-problems)
9. [Security and Compliance Issues](#security-and-compliance-issues)
10. [Emergency Recovery Procedures](#emergency-recovery-procedures)

---

## ⚙️ Prerequisites and Setup Issues

### 🔐 Issue: Azure CLI Authentication Failures

| 🔴 **Symptoms** | 🔍 **Root Cause** | ✅ **Solution Priority** |
|---|---|---|
| `az login` fails or times out | Network restrictions, proxy issues | High - blocks all Azure operations |
| "Please run 'az login' to set up account" errors | Expired authentication tokens | High - required for any Azure CLI commands |
| Permission denied errors | Insufficient subscription permissions | Critical - contact Azure admin |
| Browser-based login issues | Corporate firewall/proxy | Medium - use device code alternative |

**Solutions**:
```bash
# 🧹 Azure CLI Authentication Recovery
# Purpose: Fix authentication issues and restore Azure CLI access

# Step 1: Clear corrupted authentication cache
echo "🧹 Clearing Azure CLI cache..."
az account clear                    # Remove all account information
az cache purge                      # Clear internal CLI cache

# Step 2: Re-authenticate with device code (works with proxies/firewalls)
echo "🔐 Starting device code authentication..."
az login --use-device-code         # Follow the URL and enter the code displayed

# Step 3: Verify subscription access and permissions
echo "📋 Verifying subscription access..."
az account list --output table     # List all accessible subscriptions

# Step 4: Set the correct subscription context
echo "🎯 Setting subscription context..."
az account set --subscription "YOUR_SUBSCRIPTION_ID"  # Replace with your subscription ID

# Step 5: Validate authentication status
echo "✅ Validating authentication..."
az account show --output table     # Display current account context

# 💡 Expected Output:
# - Account list shows your subscription(s)
# - Current account shows correct user and subscription
# - No authentication errors in subsequent commands

# 🔍 If still failing, check:
# - Subscription permissions (Owner/Contributor required)
# - Corporate proxy settings
# - Azure service outages at status.azure.com
```

**Alternative Authentication**:
```bash
# Using service principal (for automation)
az login --service-principal \
  --username "CLIENT_ID" \
  --password "CLIENT_SECRET" \
  --tenant "TENANT_ID"
```

### Issue: Terraform Initialization Problems

**Symptoms**:
- "Failed to install provider" errors
- Backend initialization failures
- Version conflicts

**Solutions**:
```bash
# Clean Terraform cache
rm -rf .terraform
rm .terraform.lock.hcl

# Reinstall providers
terraform init -upgrade

# Use specific provider versions
terraform init -backend=false
terraform providers lock -platform=linux_amd64

# Force provider download
terraform init -get-plugins=true -verify-plugins=false
```

### Issue: kubectl Configuration Problems

**Symptoms**:
- "Unable to connect to the server" errors
- Context switching failures
- Permission denied errors

**Solutions**:
```bash
# Verify kubectl installation
kubectl version --client

# Reset kubeconfig
rm ~/.kube/config
az aks get-credentials --resource-group YOUR_RG --name YOUR_CLUSTER

# Check current context
kubectl config current-context
kubectl config get-contexts

# Switch context if needed
kubectl config use-context YOUR_CONTEXT

# Test connection
kubectl get nodes
kubectl get namespaces
```

---

## Azure Resource Deployment Problems

### Issue: Resource Quota Exceeded

**Symptoms**:
- "Quota exceeded" errors during resource creation
- Deployment failures with quota messages
- Unable to create VMs or clusters

**Solutions**:
```bash
# Check current quotas
az vm list-usage --location eastus --output table

# Request quota increase (for production)
az support tickets create \
  --ticket-name "Quota Increase Request" \
  --description "Need increased quota for workshop" \
  --severity minimal

# Use smaller VM sizes
# Change from Standard_D4s_v3 to Standard_B2ms in Terraform
```

### Issue: Resource Group Creation Failures

**Symptoms**:
- Permission denied creating resource groups
- Resource group already exists errors
- Location not available errors

**Solutions**:
```bash
# Check available locations
az account list-locations --output table

# Use different region if current is unavailable
az group create --name workshop-rg --location westus2

# Check existing resource groups
az group list --output table

# Delete conflicting resource group if safe
az group delete --name conflicting-rg --yes --no-wait
```

### Issue: Application Insights Connection Failures

**Symptoms**:
- No telemetry data appearing
- Connection string errors
- Instrumentation key not working

**Solutions**:
```bash
# Verify Application Insights exists
az monitor app-insights component show \
  --app YOUR_APP_INSIGHTS_NAME \
  --resource-group YOUR_RG

# Get correct connection string
az monitor app-insights component show \
  --app YOUR_APP_INSIGHTS_NAME \
  --resource-group YOUR_RG \
  --query "connectionString" -o tsv

# Test connection string format
echo "InstrumentationKey=your-key;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/"

# Update kubernetes secret
kubectl create secret generic azure-secrets \
  --from-literal=connection-string="YOUR_CONNECTION_STRING" \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Kubernetes and Container Issues

### Issue: Pods Stuck in Pending State

**Symptoms**:
- Pods remain in "Pending" status
- Events show scheduling failures
- Resource constraints

**Diagnostic Commands**:
```bash
# Check pod status and events
kubectl describe pod POD_NAME -n NAMESPACE

# Check node resources
kubectl top nodes
kubectl describe nodes

# Check resource quotas
kubectl describe quota -n NAMESPACE

# Check for taints and tolerations
kubectl get nodes -o json | jq '.items[].spec.taints'
```

**Solutions**:
```bash
# Scale cluster if needed (AKS)
az aks scale --resource-group YOUR_RG --name YOUR_CLUSTER --node-count 4

# Add node pool with more resources
az aks nodepool add \
  --resource-group YOUR_RG \
  --cluster-name YOUR_CLUSTER \
  --name largenodes \
  --node-count 2 \
  --node-vm-size Standard_D4s_v3

# Reduce resource requests in deployments
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"memory":"128Mi","cpu":"50m"}}}]}}}}'
```

### Issue: Image Pull Failures

**Symptoms**:
- "ImagePullBackOff" errors
- "ErrImagePull" status
- Authentication failures

**Solutions**:
```bash
# Check image exists and is accessible
docker pull IMAGE_NAME

# Verify image registry secrets
kubectl get secrets -n NAMESPACE
kubectl describe secret IMAGE_PULL_SECRET -n NAMESPACE

# Create registry secret if missing
kubectl create secret docker-registry regcred \
  --docker-server=YOUR_REGISTRY \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  --docker-email=YOUR_EMAIL

# Use public images for workshop
# Replace private images with public alternatives:
# mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.4
# prom/prometheus:v2.47.0
# grafana/grafana:10.1.0
```

### Issue: Container Crashes and Restarts

**Symptoms**:
- High restart counts
- CrashLoopBackOff status
- OOMKilled errors

**Diagnostic Commands**:
```bash
# Check container logs
kubectl logs POD_NAME -n NAMESPACE --previous
kubectl logs POD_NAME -n NAMESPACE -c CONTAINER_NAME

# Check resource usage
kubectl top pod POD_NAME -n NAMESPACE

# Check events
kubectl get events -n NAMESPACE --sort-by=.metadata.creationTimestamp

# Check liveness/readiness probes
kubectl describe pod POD_NAME -n NAMESPACE | grep -A 10 "Liveness\|Readiness"
```

**Solutions**:
```bash
# Increase memory limits
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Adjust probe settings
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","livenessProbe":{"initialDelaySeconds":60,"periodSeconds":30}}]}}}}'

# Scale down and up to restart cleanly
kubectl scale deployment YOUR_DEPLOYMENT --replicas=0 -n NAMESPACE
kubectl scale deployment YOUR_DEPLOYMENT --replicas=2 -n NAMESPACE
```

---

## Service Mesh (Istio) Problems

### Issue: Istio Installation Failures

**Symptoms**:
- `istioctl install` hangs or fails
- Istio components not starting
- Webhook validation errors

**Solutions**:
```bash
# Check Istio installation status
istioctl verify-install

# Reinstall with debug output
istioctl install --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true -v

# Pre-check cluster compatibility
istioctl experimental precheck

# Manual cleanup if needed
kubectl delete namespace istio-system
kubectl delete validatingwebhookconfiguration istio-validator-istio-system
kubectl delete mutatingwebhookconfiguration istio-sidecar-injector

# Alternative installation method
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set values.defaultRevision=default
```

### Issue: Sidecar Injection Not Working

**Symptoms**:
- Pods don't have istio-proxy container
- No service mesh traffic visible
- Injection label present but no sidecar

**Diagnostic Commands**:
```bash
# Check namespace labels
kubectl get namespace -L istio-injection

# Check injection webhook
kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml

# Check if pod has annotation
kubectl get pod POD_NAME -o yaml | grep -A 5 -B 5 sidecar.istio.io
```

**Solutions**:
```bash
# Enable injection on namespace
kubectl label namespace NAMESPACE istio-injection=enabled

# Force injection on specific pod
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}'

# Restart deployment to trigger injection
kubectl rollout restart deployment/YOUR_DEPLOYMENT -n NAMESPACE

# Check injection status
kubectl get pods -n NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

### Issue: Traffic Not Flowing Through Service Mesh

**Symptoms**:
- Services accessible directly but not through Istio gateway
- No traffic visible in Kiali
- 503 errors from gateway

**Solutions**:
```bash
# Check gateway configuration
kubectl get gateway -n NAMESPACE
kubectl describe gateway GATEWAY_NAME -n NAMESPACE

# Check virtual service
kubectl get virtualservice -n NAMESPACE
kubectl describe virtualservice VS_NAME -n NAMESPACE

# Check destination rules
kubectl get destinationrule -n NAMESPACE

# Verify ingress gateway is running
kubectl get pods -n istio-system -l app=istio-ingressgateway

# Get ingress gateway IP
kubectl get svc istio-ingressgateway -n istio-system

# Test gateway configuration
istioctl analyze -n NAMESPACE
```

---

## Monitoring Stack Issues

### Issue: Prometheus Not Scraping Metrics

**Symptoms**:
- No metrics in Prometheus UI
- Empty queries return no data
- Targets showing as down

**Diagnostic Commands**:
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Check service discovery
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | .discoveredLabels'

# Check Prometheus configuration
kubectl get configmap prometheus-config -n observability -o yaml
```

**Solutions**:
```bash
# Reload Prometheus configuration
kubectl exec -n observability deployment/prometheus -- kill -HUP 1

# Check service annotations
kubectl get services -n NAMESPACE -o yaml | grep -A 3 -B 3 prometheus.io

# Verify network policies allow scraping
kubectl get networkpolicy -n observability
kubectl describe networkpolicy POLICY_NAME -n observability

# Fix service monitor
kubectl get servicemonitor -n observability
kubectl describe servicemonitor SM_NAME -n observability
```

### Issue: Grafana Dashboard Not Loading Data

**Symptoms**:
- Dashboards show "No data" or "N/A"
- Query errors in dashboard panels
- Data source connection issues

**Solutions**:
```bash
# Check Grafana data source configuration
curl -u admin:enterprise123 http://localhost:3000/api/datasources

# Test Prometheus connection from Grafana pod
kubectl exec -n observability deployment/grafana -- wget -qO- http://prometheus:9090/api/v1/query?query=up

# Check if metrics exist in Prometheus
curl "http://localhost:9090/api/v1/query?query=up" | jq '.data.result | length'

# Reload dashboard
curl -u admin:enterprise123 -X POST http://localhost:3000/api/admin/provisioning/dashboards/reload

# Import dashboard manually
curl -u admin:enterprise123 -X POST \
  -H "Content-Type: application/json" \
  -d @dashboard.json \
  http://localhost:3000/api/dashboards/db
```

### Issue: Jaeger Tracing Not Working

**Symptoms**:
- No traces visible in Jaeger UI
- Applications not sending traces
- Collector not receiving data

**Solutions**:
```bash
# Check Jaeger components
kubectl get pods -n istio-system -l app.kubernetes.io/name=jaeger

# Check collector endpoint
kubectl get svc -n istio-system jaeger-collector

# Verify tracing configuration in Istio
istioctl proxy-config bootstrap POD_NAME.NAMESPACE | grep tracing

# Check application instrumentation
kubectl logs POD_NAME -n NAMESPACE | grep -i trace

# Test trace generation
curl -H "x-request-id: test-trace-$(date +%s)" http://YOUR_SERVICE_URL/
```

---

## Application and Connectivity Problems

### Issue: Services Not Accessible Externally

**Symptoms**:
- LoadBalancer stuck in "Pending"
- External IP not assigned
- Connection timeouts

**Solutions**:
```bash
# Check service type and status
kubectl get svc -n NAMESPACE
kubectl describe svc SERVICE_NAME -n NAMESPACE

# Check load balancer events
kubectl get events -n NAMESPACE | grep LoadBalancer

# Use NodePort as alternative
kubectl patch svc SERVICE_NAME -n NAMESPACE -p='{"spec":{"type":"NodePort"}}'

# Port forward for testing
kubectl port-forward svc/SERVICE_NAME 8080:80 -n NAMESPACE

# Check firewall rules (Azure)
az network nsg rule list --resource-group MC_* --nsg-name kubernetes-nsg --output table
```

### Issue: DNS Resolution Problems

**Symptoms**:
- Services can't resolve each other
- "Name resolution failed" errors
- Intermittent connectivity

**Solutions**:
```bash
# Check CoreDNS status
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution from pod
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default.svc.cluster.local

# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Check service endpoints
kubectl get endpoints SERVICE_NAME -n NAMESPACE
```

---

## Performance and Resource Issues

### Issue: High Memory Usage and OOM Kills

**Symptoms**:
- Pods getting OOMKilled
- High memory consumption
- Performance degradation

**Diagnostic Commands**:
```bash
# Check memory usage
kubectl top pods -n NAMESPACE
kubectl top nodes

# Check for memory leaks
kubectl logs POD_NAME -n NAMESPACE | grep -i "memory\|oom"

# Monitor memory over time
watch "kubectl top pods -n NAMESPACE"
```

**Solutions**:
```bash
# Increase memory limits
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"limits":{"memory":"2Gi"},"requests":{"memory":"512Mi"}}}]}}}}'

# Enable memory monitoring
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: memory-monitor
data:
  script.sh: |
    #!/bin/bash
    while true; do
      echo "Memory usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
      sleep 10
    done
EOF

# Add memory limits to all containers
for deploy in $(kubectl get deployments -n NAMESPACE -o name); do
  kubectl patch $deploy -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"'"$(kubectl get $deploy -n NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].name}')"'","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
done
```

### Issue: Slow Response Times

**Symptoms**:
- High latency in applications
- Timeouts in requests
- Poor user experience

**Solutions**:
```bash
# Check resource utilization
kubectl top pods -n NAMESPACE
kubectl top nodes

# Scale up applications
kubectl scale deployment YOUR_DEPLOYMENT --replicas=5 -n NAMESPACE

# Check for resource contention
kubectl describe nodes | grep -A 5 "Allocated resources"

# Optimize resource requests
kubectl patch deployment YOUR_DEPLOYMENT -n NAMESPACE -p='{"spec":{"template":{"spec":{"containers":[{"name":"CONTAINER_NAME","resources":{"requests":{"cpu":"200m","memory":"256Mi"}}}]}}}}'

# Add horizontal pod autoscaler
kubectl autoscale deployment YOUR_DEPLOYMENT --cpu-percent=70 --min=2 --max=10 -n NAMESPACE
```

---

## Multi-Cloud Integration Problems

### Issue: Cross-Cloud Connectivity Failures

**Symptoms**:
- Services in different clouds can't communicate
- Timeouts accessing external services
- Authentication failures

**Solutions**:
```bash
# Test network connectivity
kubectl run test-connectivity --image=busybox --rm -it -- ping EXTERNAL_SERVICE

# Check network policies
kubectl get networkpolicy --all-namespaces
kubectl describe networkpolicy POLICY_NAME -n NAMESPACE

# Verify firewall rules
# Azure
az network nsg rule list --resource-group YOUR_RG --nsg-name YOUR_NSG

# Test with curl from pod
kubectl exec -it POD_NAME -n NAMESPACE -- curl -v http://EXTERNAL_SERVICE

# Check service mesh configuration for external services
kubectl get serviceentry -n NAMESPACE
```

### Issue: Prometheus Federation Not Working

**Symptoms**:
- No cross-cloud metrics visible
- Federation endpoints timing out
- Incomplete metric collection

**Solutions**:
```bash
# Check federation configuration
kubectl get configmap prometheus-federation-config -n observability -o yaml

# Test federation endpoint manually
kubectl exec -n observability deployment/prometheus -- wget -qO- http://EXTERNAL_PROMETHEUS:9090/federate?match[]={__name__=~"up|.*_total"}

# Verify network connectivity to external Prometheus
kubectl run test-federation --image=curlimages/curl --rm -it -- curl http://EXTERNAL_PROMETHEUS:9090/api/v1/query?query=up

# Update federation configuration
kubectl patch configmap prometheus-federation-config -n observability --patch='{"data":{"prometheus-federation.yml":"NEW_CONFIG"}}'
```

---

## Security and Compliance Issues

### Issue: RBAC Permission Denied

**Symptoms**:
- "Forbidden" errors when accessing resources
- Service accounts can't perform required actions
- Authentication failures

**Solutions**:
```bash
# Check current permissions
kubectl auth can-i --list --as=system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT

# Check role bindings
kubectl get rolebindings,clusterrolebindings --all-namespaces | grep SERVICE_ACCOUNT

# Create necessary role binding
kubectl create rolebinding BINDING_NAME \
  --clusterrole=ROLE_NAME \
  --serviceaccount=NAMESPACE:SERVICE_ACCOUNT \
  --namespace=NAMESPACE

# Check effective permissions
kubectl auth can-i get pods --as=system:serviceaccount:NAMESPACE:SERVICE_ACCOUNT
```

### Issue: Network Policy Blocking Traffic

**Symptoms**:
- Services can't communicate
- Unexpected connection refused errors
- Traffic flow blocked

**Solutions**:
```bash
# List all network policies
kubectl get networkpolicy --all-namespaces

# Check policy details
kubectl describe networkpolicy POLICY_NAME -n NAMESPACE

# Temporarily disable policy for testing
kubectl annotate networkpolicy POLICY_NAME -n NAMESPACE policy.disabled=true

# Create allow-all policy for troubleshooting
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-traffic
  namespace: NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
```

---

## Emergency Recovery Procedures

### Complete Cluster Reset

**When to use**: Cluster is completely broken and unrecoverable

```bash
# 1. Save important configurations
kubectl get all,configmaps,secrets --all-namespaces -o yaml > cluster-backup.yaml

# 2. Delete problematic namespaces
kubectl delete namespace observability production staging --force --grace-period=0

# 3. Remove Istio
istioctl uninstall --purge
kubectl delete namespace istio-system --force --grace-period=0

# 4. Clean up CRDs
kubectl get crd | grep istio | awk '{print $1}' | xargs kubectl delete crd

# 5. Restart from clean state
# Re-run workshop setup scripts
```

### Partial Service Recovery

**When to use**: Specific services or components are failing

```bash
# 1. Scale down problematic deployment
kubectl scale deployment DEPLOYMENT_NAME --replicas=0 -n NAMESPACE

# 2. Delete and recreate pods
kubectl delete pods -l app=APP_NAME -n NAMESPACE

# 3. Reset configuration
kubectl delete configmap CONFIG_NAME -n NAMESPACE
kubectl apply -f original-config.yaml

# 4. Scale back up
kubectl scale deployment DEPLOYMENT_NAME --replicas=2 -n NAMESPACE
```

### Data Recovery

**When to use**: Lost important monitoring data or configurations

```bash
# 1. Check for available backups
kubectl get persistentvolumeclaims -n observability

# 2. Export current Grafana dashboards
curl -u admin:enterprise123 "http://localhost:3000/api/search?type=dash-db" | jq -r '.[].uri' | xargs -I {} curl -u admin:enterprise123 "http://localhost:3000/api/dashboards/{}"

# 3. Backup Prometheus data (if persistent volume exists)
kubectl exec -n observability deployment/prometheus -- tar czf /tmp/prometheus-backup.tar.gz /prometheus

# 4. Save critical configurations
kubectl get configmaps,secrets -n observability -o yaml > observability-backup.yaml
```

---

## 🆘 Emergency Contacts and Resources

### Quick Help Commands

```bash
# Get cluster status overview
kubectl get nodes,pods --all-namespaces | grep -E "(NotReady|Error|CrashLoop|Pending)"

# Check resource usage
kubectl top nodes && kubectl top pods --all-namespaces

# Check recent events
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp | tail -20

# Generate support bundle
kubectl cluster-info dump > cluster-info-$(date +%Y%m%d-%H%M%S).txt
```

### Documentation Links

- **Azure Monitor**: https://docs.microsoft.com/en-us/azure/azure-monitor/
- **Kubernetes Troubleshooting**: https://kubernetes.io/docs/tasks/debug-application-cluster/
- **Istio Troubleshooting**: https://istio.io/latest/docs/ops/common-problems/
- **Prometheus Troubleshooting**: https://prometheus.io/docs/prometheus/latest/troubleshooting/

### Support Resources

- **Azure Support**: https://azure.microsoft.com/en-us/support/
- **Kubernetes Community**: https://kubernetes.io/community/
- **Stack Overflow**: Use tags `azure-monitor`, `kubernetes`, `istio`, `prometheus`

---

## 📝 Prevention Best Practices

1. **Always verify prerequisites** before starting each module
2. **Save working configurations** after successful deployments
3. **Monitor resource usage** throughout the workshop
4. **Keep backup of important data** and configurations
5. **Test connectivity** after each major configuration change
6. **Review logs regularly** for early warning signs
7. **Use proper resource limits** to prevent resource exhaustion
8. **Follow security best practices** for production deployments

Remember: This troubleshooting guide covers the most common issues. For complex problems, don't hesitate to reach out to the workshop facilitator or Azure support.
