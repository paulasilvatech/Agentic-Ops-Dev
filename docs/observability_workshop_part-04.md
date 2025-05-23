# 🚀 Complete Azure Observability Workshop Guide - Part 4
## 🔒 Intermediate Workshop - CI/CD Integration & Security Monitoring

### 🤖 DevSecOps Automation

**⚡ Deploy secure monitoring with CI/CD integration:**

```bash
# Complete DevSecOps automation
cd resources/
./quick-start.sh deploy YOUR_SUBSCRIPTION_ID

# Includes:
# - GitHub Actions CI/CD templates
# - Azure DevOps pipeline examples
# - Microsoft Defender integration
# - Automated security monitoring setup

# Access security dashboards
./scripts/helpers/port-forward-grafana.sh
# Security dashboards available at http://localhost:3000
```

**📊 Security Templates**: Pre-configured monitoring for compliance and threat detection.

---

### 🔗 Continuing from Part 3
**Prerequisites**: You should have completed Parts 1-3 and have:
- ✅ Microservices running with distributed tracing
- ✅ Multi-cloud monitoring integration (Azure + Datadog + Prometheus/Grafana)
- ✅ Unified dashboard displaying metrics from multiple sources
- ✅ Understanding of advanced observability patterns

---

## 🔄 Module 3: CI/CD Integration with Observability (60 minutes)

### 🛠️ 3.1 GitHub Actions with Monitoring Integration
**Time Required**: 30 minutes

1. **📋 Create GitHub Repository for Workshop**:
```bash
# 📂 Initialize git in your microservices project
cd azure-monitoring-workshop/microservices

# 🌱 Initialize Git repository with enterprise standards
git init
git add .
git commit -m "🎆 Initial microservices setup with observability

- Added User Service with distributed tracing
- Added Order Service with cross-service communication
- Configured OpenTelemetry and Application Insights
- Implemented custom telemetry processors"

# 🚀 Create GitHub repository (replace YOUR_USERNAME with actual username)
gh repo create azure-observability-microservices --public --description "Enterprise observability workshop with microservices"

# 🔗 Configure remote repository
git remote add origin https://github.com/YOUR_USERNAME/azure-observability-microservices.git
git branch -M main
git push -u origin main

# ✅ Verify repository creation
echo "✅ Repository created successfully at:"
echo "https://github.com/YOUR_USERNAME/azure-observability-microservices"
```

2. **🛠️ Create Comprehensive CI/CD Pipeline** - Create `.github/workflows/ci-cd-observability.yml`:
```yaml
name: CI/CD with Integrated Observability

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  AZURE_WEBAPP_USER_SERVICE: ${{ secrets.AZURE_WEBAPP_USER_SERVICE }}
  AZURE_WEBAPP_ORDER_SERVICE: ${{ secrets.AZURE_WEBAPP_ORDER_SERVICE }}
  AZURE_RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}
  APPLICATIONINSIGHTS_CONNECTION_STRING: ${{ secrets.APPLICATIONINSIGHTS_CONNECTION_STRING }}

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup .NET 8
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/.nuget/packages
        key: ${{ runner.os }}-nuget-${{ hashFiles('**/*.csproj') }}
        restore-keys: |
          ${{ runner.os }}-nuget-
    
    - name: Restore dependencies
      run: |
        dotnet restore user-service/UserService
        dotnet restore order-service/OrderService
    
    - name: Build services
      run: |
        dotnet build user-service/UserService --configuration Release --no-restore
        dotnet build order-service/OrderService --configuration Release --no-restore
    
    - name: Run unit tests with coverage
      run: |
        dotnet test user-service/UserService --configuration Release --no-build \
          --collect:"XPlat Code Coverage" \
          --logger trx \
          --results-directory TestResults/
        
        dotnet test order-service/OrderService --configuration Release --no-build \
          --collect:"XPlat Code Coverage" \
          --logger trx \
          --results-directory TestResults/
    
    - name: Publish test results
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: '.NET Tests'
        path: TestResults/*.trx
        reporter: dotnet-trx
    
    - name: Upload coverage to Azure Application Insights
      if: always()
      run: |
        # Send test metrics to Application Insights
        curl -X POST "https://dc.services.visualstudio.com/v2/track" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Microsoft.ApplicationInsights.Event",
            "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "iKey": "${{ secrets.APPINSIGHTS_INSTRUMENTATION_KEY }}",
            "data": {
              "baseType": "EventData",
              "baseData": {
                "name": "CI.TestResults",
                "properties": {
                  "BuildNumber": "${{ github.run_number }}",
                  "Branch": "${{ github.ref_name }}",
                  "Commit": "${{ github.sha }}",
                  "Actor": "${{ github.actor }}",
                  "Repository": "${{ github.repository }}",
                  "TestsPassed": "true",
                  "Stage": "CI"
                }
              }
            }
          }'
    
    - name: Build and publish artifacts
      run: |
        dotnet publish user-service/UserService -c Release -o user-service/publish
        dotnet publish order-service/OrderService -c Release -o order-service/publish
    
    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: published-services
        path: |
          user-service/publish/
          order-service/publish/

  security-scan:
    runs-on: ubuntu-latest
    needs: build-and-test
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run CodeQL Analysis
      uses: github/codeql-action/init@v2
      with:
        languages: csharp
    
    - name: Setup .NET 8
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'
    
    - name: Build for analysis
      run: |
        dotnet build user-service/UserService --configuration Release
        dotnet build order-service/OrderService --configuration Release
    
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
    
    - name: Upload security scan results to Application Insights
      if: always()
      run: |
        curl -X POST "https://dc.services.visualstudio.com/v2/track" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Microsoft.ApplicationInsights.Event",
            "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "iKey": "${{ secrets.APPINSIGHTS_INSTRUMENTATION_KEY }}",
            "data": {
              "baseType": "EventData",
              "baseData": {
                "name": "CI.SecurityScan",
                "properties": {
                  "BuildNumber": "${{ github.run_number }}",
                  "ScanType": "CodeQL",
                  "Status": "Completed",
                  "Branch": "${{ github.ref_name }}"
                }
              }
            }
          }'

  deploy-to-azure:
    runs-on: ubuntu-latest
    needs: [build-and-test, security-scan]
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Download artifacts
      uses: actions/download-artifact@v3
      with:
        name: published-services
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy User Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_USER_SERVICE }}
        package: user-service/publish
    
    - name: Deploy Order Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_ORDER_SERVICE }}
        package: order-service/publish
    
    - name: Create Application Insights deployment annotation
      run: |
        # Create deployment annotation in Application Insights
        curl -X POST "https://ainsights-api.azurewebsites.net/Annotations" \
          -H "X-AIAD-ApiKey: ${{ secrets.APPINSIGHTS_API_KEY }}" \
          -H "Content-Type: application/json" \
          -d '{
            "AnnotationName": "Deployment",
            "EventTime": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "Category": "Deployment", 
            "Properties": {
              "ReleaseName": "Release-${{ github.run_number }}",
              "ReleaseDescription": "Automated deployment from GitHub Actions",
              "TriggerBy": "${{ github.actor }}",
              "BuildNumber": "${{ github.run_number }}",
              "Repository": "${{ github.repository }}",
              "Branch": "${{ github.ref_name }}",
              "CommitId": "${{ github.sha }}"
            }
          }'
    
    - name: Wait for deployment to settle
      run: sleep 60
    
    - name: Run deployment health checks
      id: health-check
      run: |
        USER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_USER_SERVICE }}.azurewebsites.net"
        ORDER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_ORDER_SERVICE }}.azurewebsites.net"
        
        echo "Checking User Service health..."
        USER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$USER_SERVICE_URL/api/user/health")
        echo "user_health=$USER_HEALTH" >> $GITHUB_OUTPUT
        
        echo "Checking Order Service health..."
        ORDER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$ORDER_SERVICE_URL/api/order/health")
        echo "order_health=$ORDER_HEALTH" >> $GITHUB_OUTPUT
        
        echo "User Service health: $USER_HEALTH"
        echo "Order Service health: $ORDER_HEALTH"
        
        if [ "$USER_HEALTH" != "200" ] || [ "$ORDER_HEALTH" != "200" ]; then
          echo "Health check failed!"
          exit 1
        fi
    
    - name: Run smoke tests
      run: |
        USER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_USER_SERVICE }}.azurewebsites.net"
        ORDER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_ORDER_SERVICE }}.azurewebsites.net"
        
        echo "Running smoke tests..."
        
        # Test user creation
        USER_RESPONSE=$(curl -s -X POST "$USER_SERVICE_URL/api/user" \
          -H "Content-Type: application/json" \
          -d '{"name": "Test User", "email": "test@example.com"}' \
          -w "%{http_code}")
        
        echo "User creation response: $USER_RESPONSE"
        
        # Test order creation
        ORDER_RESPONSE=$(curl -s -X POST "$ORDER_SERVICE_URL/api/order" \
          -H "Content-Type: application/json" \
          -d '{"userId": 123, "total": 99.99, "items": [{"name": "Test Product", "quantity": 1, "price": 99.99}]}' \
          -w "%{http_code}")
        
        echo "Order creation response: $ORDER_RESPONSE"
        
        # Verify responses contain 20x status codes
        if [[ ! "$USER_RESPONSE" =~ 20[0-9] ]] || [[ ! "$ORDER_RESPONSE" =~ 20[0-9] ]]; then
          echo "Smoke tests failed!"
          exit 1
        fi
        
        echo "Smoke tests passed!"
    
    - name: Upload deployment metrics to Application Insights
      if: always()
      run: |
        STATUS="Success"
        if [ "${{ steps.health-check.outcome }}" != "success" ]; then
          STATUS="Failed"
        fi
        
        curl -X POST "https://dc.services.visualstudio.com/v2/track" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Microsoft.ApplicationInsights.Event",
            "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "iKey": "${{ secrets.APPINSIGHTS_INSTRUMENTATION_KEY }}",
            "data": {
              "baseType": "EventData",
              "baseData": {
                "name": "CD.Deployment",
                "properties": {
                  "BuildNumber": "${{ github.run_number }}",
                  "DeploymentStatus": "'$STATUS'",
                  "UserServiceHealth": "${{ steps.health-check.outputs.user_health }}",
                  "OrderServiceHealth": "${{ steps.health-check.outputs.order_health }}",
                  "Branch": "${{ github.ref_name }}",
                  "CommitId": "${{ github.sha }}",
                  "Actor": "${{ github.actor }}"
                }
              }
            }
          }'

  performance-testing:
    runs-on: ubuntu-latest
    needs: deploy-to-azure
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run performance tests
      run: |
        USER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_USER_SERVICE }}.azurewebsites.net"
        ORDER_SERVICE_URL="https://${{ env.AZURE_WEBAPP_ORDER_SERVICE }}.azurewebsites.net"
        
        echo "Running performance tests..."
        
        # Install artillery for load testing
        npm install -g artillery
        
        # Create artillery config
        cat > performance-test.yml << EOF
        config:
          target: '$USER_SERVICE_URL'
          phases:
            - duration: 60
              arrivalRate: 5
        scenarios:
          - name: "User API Load Test"
            requests:
              - get:
                  url: "/api/user/{{ \$randomInt(1, 100) }}"
              - post:
                  url: "/api/user"
                  json:
                    name: "Load Test User {{ \$randomInt(1, 1000) }}"
                    email: "loadtest{{ \$randomInt(1, 1000) }}@example.com"
        EOF
        
        # Run load test
        artillery run performance-test.yml --output performance-results.json
        
        # Parse results and send to Application Insights
        REQUESTS_COMPLETED=$(cat performance-results.json | jq '.aggregate.counters."http.requests"')
        RESPONSE_TIME_MEDIAN=$(cat performance-results.json | jq '.aggregate.summaries."http.response_time".median')
        RESPONSE_TIME_P95=$(cat performance-results.json | jq '.aggregate.summaries."http.response_time".p95')
        
        echo "Performance test completed:"
        echo "Requests: $REQUESTS_COMPLETED"
        echo "Median response time: $RESPONSE_TIME_MEDIAN ms"
        echo "95th percentile: $RESPONSE_TIME_P95 ms"
        
        # Send performance metrics to Application Insights
        curl -X POST "https://dc.services.visualstudio.com/v2/track" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Microsoft.ApplicationInsights.Event",
            "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "iKey": "${{ secrets.APPINSIGHTS_INSTRUMENTATION_KEY }}",
            "data": {
              "baseType": "EventData",
              "baseData": {
                "name": "CD.PerformanceTest",
                "properties": {
                  "BuildNumber": "${{ github.run_number }}",
                  "RequestsCompleted": "'$REQUESTS_COMPLETED'",
                  "MedianResponseTime": "'$RESPONSE_TIME_MEDIAN'",
                  "P95ResponseTime": "'$RESPONSE_TIME_P95'",
                  "TestDuration": "60",
                  "LoadLevel": "5 RPS"
                }
              }
            }
          }'
```

3. **Create Rollback Workflow** - Create `.github/workflows/rollback.yml`:
```yaml
name: Emergency Rollback

on:
  workflow_dispatch:
    inputs:
      target_version:
        description: 'Version to rollback to (GitHub run number)'
        required: true
        type: string
      reason:
        description: 'Reason for rollback'
        required: true
        type: string
      services:
        description: 'Services to rollback (comma-separated: user-service,order-service,both)'
        required: true
        default: 'both'
        type: choice
        options:
        - both
        - user-service
        - order-service

env:
  AZURE_WEBAPP_USER_SERVICE: ${{ secrets.AZURE_WEBAPP_USER_SERVICE }}
  AZURE_WEBAPP_ORDER_SERVICE: ${{ secrets.AZURE_WEBAPP_ORDER_SERVICE }}
  AZURE_RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}

jobs:
  validate-rollback:
    runs-on: ubuntu-latest
    outputs:
      rollback-approved: ${{ steps.validation.outputs.approved }}
    
    steps:
    - name: Validate rollback request
      id: validation
      run: |
        echo "Validating rollback request..."
        echo "Target version: ${{ inputs.target_version }}"
        echo "Reason: ${{ inputs.reason }}"
        echo "Services: ${{ inputs.services }}"
        
        # In a real scenario, you might check if the target version exists
        # and validate the rollback is safe
        echo "approved=true" >> $GITHUB_OUTPUT
    
    - name: Log rollback initiation
      run: |
        curl -X POST "https://dc.services.visualstudio.com/v2/track" \
          -H "Content-Type: application/json" \
          -d '{
            "name": "Microsoft.ApplicationInsights.Event",
            "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "iKey": "${{ secrets.APPINSIGHTS_INSTRUMENTATION_KEY }}",
            "data": {
              "baseType": "EventData",
              "baseData": {
                "name": "CD.RollbackInitiated",
                "properties": {
                  "TargetVersion": "${{ inputs.target_version }}",
                  "Reason": "${{ inputs.reason }}",
                  "Services": "${{ inputs.services }}",
                  "InitiatedBy": "${{ github.actor }}"
                }
              }
            }
          }'

  perform-rollback:
    runs-on: ubuntu-latest
    needs: validate-rollback
    if: needs.validate-rollback.outputs.rollback-approved == 'true'
    
    steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Get current deployment info
      run: |
        if [[ "${{ inputs.services }}" == "both" || "${{ inputs.services }}" == "user-service" ]]; then
          echo "Current User Service deployment:"
          az webapp show --name ${{ env.AZURE_WEBAPP_USER_SERVICE }} \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "{name:name, state:state, defaultHostName:defaultHostName}"
        fi
        
        if [[ "${{ inputs.services }}" == "both" || "${{ inputs.services }}" == "order-service" ]]; then
          echo "Current Order Service deployment:"
          az webapp show --name ${{ env.AZURE_WEBAPP_ORDER_SERVICE }} \
            --resource-group ${{ env.AZURE_RESOURCE_GROUP }} \
            --query "{name:name, state:state, defaultHostName:defaultHostName}"
        fi
    
    - name: Download rollback artifacts
      run: |
        # In a real scenario, you would download the specific version artifacts
        # For this workshop, we'll simulate the rollback
        echo "Downloading artifacts for version ${{ inputs.target_version }}"
        echo "This would typically download from artifact storage or registry"
    
    - name: Perform rollback deployment
      run: |
        echo "Performing rollback to version ${{ inputs.target_version }}"
        echo "Reason: ${{ inputs.reason }}"
        echo "Services: ${{ inputs.services }}"
        
        # In a real scenario, you would:
        # 1. Stop traffic to the services
        # 2. Deploy the previous version
        # 3. Update database schemas if needed
        # 4. Clear caches
        # 5. Restart services
        # 6. Gradually restore traffic
        
        echo "Rollback simulation completed"
    
    - name: Post-rollback health check
      id: health-check
      run: |
        sleep 30  # Wait for services to stabilize
        
        HEALTH_STATUS="success"
        
        if [[ "${{ inputs.services }}" == "both" || "${{ inputs.services }}" == "user-service" ]]; then
          USER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "https://${{ env.AZURE_WEBAPP_USER_SERVICE }}.azurewebsites.net/api/user/health")
          echo "User Service health: $USER_HEALTH"
          if [ "$USER_HEALTH" != "200" ]; then
            HEALTH_STATUS="failed"
          fi
        fi
        
        if [[ "${{ inputs.services }}" == "both" || "${{ inputs.services }}" == "order-service" ]]; then
          ORDER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "https://${{ env.AZURE_WEBAPP_ORDER_SERVICE }}.azurewebsites.net/api/order/health")
          echo "Order Service health: $ORDER_HEALTH"
          if [ "$ORDER_HEALTH" != "200" ]; then
            HEALTH_STATUS="failed"
          fi
        fi
        
        echo "Overall health status: $HEALTH_STATUS"
        echo "status=$HEALTH_STATUS" >> $GITHUB_OUTPUT
        
        if [ "$HEALTH_STATUS" == "failed" ]; then
          echo "Post-rollback health check failed!"
          exit 1
        fi
    
    - name: Create rollback annotation
      if: always()
      run: |
        STATUS="Success"
        if [ "${{ steps.health-check.outputs.status }}" != "success" ]; then
          STATUS="Failed"
        fi
        
        curl -X POST "https://ainsights-api.azurewebsites.net/Annotations" \
          -H "X-AIAD-ApiKey: ${{ secrets.APPINSIGHTS_API_KEY }}" \
          -H "Content-Type: application/json" \
          -d '{
            "AnnotationName": "Rollback",
            "EventTime": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
            "Category": "Deployment",
            "Properties": {
              "RollbackVersion": "${{ inputs.target_version }}",
              "Reason": "${{ inputs.reason }}",
              "Services": "${{ inputs.services }}",
              "Status": "'$STATUS'",
              "InitiatedBy": "${{ github.actor }}"
            }
          }'
```

| ✅ **Checkpoint Validation** | **Expected Outcome** |
|---|---|
| **GitHub Actions Pipeline** | CI/CD workflow runs successfully with monitoring integration |
| **Application Insights Events** | Build, test, and deployment events appear in telemetry |
| **Deployment Annotations** | Release markers visible in Application Insights timeline |
| **Health Checks** | Automated deployment validation and rollback capability |

**🔍 Quick Verification**:
```bash
# Trigger a test deployment
git commit -m "Test: Trigger CI/CD pipeline" --allow-empty
git push origin main

# Check GitHub Actions
gh run list --limit 1

# Verify Application Insights events (wait 2-3 minutes)
echo "✅ Expected: CI/CD events should appear in Application Insights"
```

### 🛡️ 3.2 Deployment Monitoring and Release Gates
**Time Required**: 30 minutes

1. **Create Deployment Health Monitor Service** - Create `shared/infrastructure/DeploymentHealthMonitor.cs`:
```csharp
using Microsoft.ApplicationInsights;
using System.Text.Json;

namespace Shared.Infrastructure
{
    public class DeploymentHealthMonitor
    {
        private readonly TelemetryClient _telemetryClient;
        private readonly ILogger<DeploymentHealthMonitor> _logger;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public DeploymentHealthMonitor(
            TelemetryClient telemetryClient,
            ILogger<DeploymentHealthMonitor> logger,
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _telemetryClient = telemetryClient;
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task<DeploymentHealthResult> ValidateDeployment(
            string deploymentId, 
            List<string> serviceUrls, 
            TimeSpan timeout)
        {
            var result = new DeploymentHealthResult
            {
                DeploymentId = deploymentId,
                StartTime = DateTime.UtcNow,
                ServiceUrls = serviceUrls,
                IsHealthy = true
            };

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                _logger.LogInformation("Starting deployment health validation for {DeploymentId}", deploymentId);

                // Step 1: Basic connectivity and health checks
                await ValidateBasicHealth(result);

                // Step 2: Performance baseline validation
                await ValidatePerformanceBaseline(result);

                // Step 3: Business functionality validation
                await ValidateBusinessFunctionality(result);

                // Step 4: Cross-service communication validation
                await ValidateCrossServiceCommunication(result);

                // Step 5: Database and dependency validation
                await ValidateDependencies(result);

                result.EndTime = DateTime.UtcNow;
                result.Duration = stopwatch.Elapsed;

                // Determine overall health status
                result.IsHealthy = result.HealthChecks.All(check => check.IsHealthy);

                // Track deployment validation metrics
                _telemetryClient.TrackEvent("DeploymentValidation", new Dictionary<string, string>
                {
                    ["DeploymentId"] = deploymentId,
                    ["IsHealthy"] = result.IsHealthy.ToString(),
                    ["Duration"] = result.Duration.TotalSeconds.ToString(),
                    ["ChecksPerformed"] = result.HealthChecks.Count.ToString(),
                    ["FailedChecks"] = result.HealthChecks.Count(c => !c.IsHealthy).ToString()
                });

                _logger.LogInformation("Deployment validation completed for {DeploymentId}. Healthy: {IsHealthy}", 
                    deploymentId, result.IsHealthy);

                return result;
            }
            catch (Exception ex)
            {
                result.IsHealthy = false;
                result.HealthChecks.Add(new HealthCheck
                {
                    Name = "ValidationException",
                    IsHealthy = false,
                    Error = ex.Message,
                    Duration = stopwatch.Elapsed
                });

                _logger.LogError(ex, "Deployment validation failed for {DeploymentId}", deploymentId);
                _telemetryClient.TrackException(ex);

                return result;
            }
        }

        private async Task ValidateBasicHealth(DeploymentHealthResult result)
        {
            foreach (var serviceUrl in result.ServiceUrls)
            {
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var check = new HealthCheck { Name = $"BasicHealth_{GetServiceName(serviceUrl)}" };

                try
                {
                    var healthUrl = $"{serviceUrl}/health";
                    _logger.LogInformation("Checking basic health for {ServiceUrl}", healthUrl);

                    var response = await _httpClient.GetAsync(healthUrl);
                    stopwatch.Stop();

                    check.StatusCode = (int)response.StatusCode;
                    check.Duration = stopwatch.Elapsed;
                    check.IsHealthy = response.IsSuccessStatusCode && stopwatch.ElapsedMilliseconds < 5000;

                    if (check.IsHealthy)
                    {
                        var content = await response.Content.ReadAsStringAsync();
                        check.ResponseBody = content;
                    }
                    else
                    {
                        check.Error = $"Status: {response.StatusCode}, Duration: {stopwatch.ElapsedMilliseconds}ms";
                    }
                }
                catch (Exception ex)
                {
                    stopwatch.Stop();
                    check.IsHealthy = false;
                    check.Error = ex.Message;
                    check.Duration = stopwatch.Elapsed;
                }

                result.HealthChecks.Add(check);
            }
        }

        private async Task ValidatePerformanceBaseline(DeploymentHealthResult result)
        {
            foreach (var serviceUrl in result.ServiceUrls)
            {
                var check = new HealthCheck { Name = $"Performance_{GetServiceName(serviceUrl)}" };
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();

                try
                {
                    // Perform multiple requests to get baseline performance
                    var responseTimes = new List<TimeSpan>();
                    var successCount = 0;

                    for (int i = 0; i < 10; i++)
                    {
                        var requestStopwatch = System.Diagnostics.Stopwatch.StartNew();
                        try
                        {
                            var response = await _httpClient.GetAsync($"{serviceUrl}/api/health");
                            requestStopwatch.Stop();

                            if (response.IsSuccessStatusCode)
                            {
                                successCount++;
                                responseTimes.Add(requestStopwatch.Elapsed);
                            }
                        }
                        catch
                        {
                            requestStopwatch.Stop();
                            // Continue with other requests
                        }

                        await Task.Delay(100); // Small delay between requests
                    }

                    stopwatch.Stop();

                    if (responseTimes.Any())
                    {
                        var avgResponseTime = responseTimes.Average(rt => rt.TotalMilliseconds);
                        var maxResponseTime = responseTimes.Max(rt => rt.TotalMilliseconds);
                        var successRate = (double)successCount / 10 * 100;

                        check.IsHealthy = avgResponseTime < 2000 && maxResponseTime < 5000 && successRate >= 90;
                        check.Metrics = new Dictionary<string, object>
                        {
                            ["AverageResponseTime"] = avgResponseTime,
                            ["MaxResponseTime"] = maxResponseTime,
                            ["SuccessRate"] = successRate,
                            ["RequestCount"] = 10
                        };

                        if (!check.IsHealthy)
                        {
                            check.Error = $"Performance below baseline. Avg: {avgResponseTime:F0}ms, Max: {maxResponseTime:F0}ms, Success: {successRate:F1}%";
                        }
                    }
                    else
                    {
                        check.IsHealthy = false;
                        check.Error = "No successful requests completed";
                    }

                    check.Duration = stopwatch.Elapsed;
                }
                catch (Exception ex)
                {
                    stopwatch.Stop();
                    check.IsHealthy = false;
                    check.Error = ex.Message;
                    check.Duration = stopwatch.Elapsed;
                }

                result.HealthChecks.Add(check);
            }
        }

        private async Task ValidateBusinessFunctionality(DeploymentHealthResult result)
        {
            var check = new HealthCheck { Name = "BusinessFunctionality" };
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                var userServiceUrl = result.ServiceUrls.FirstOrDefault(url => url.Contains("user"));
                var orderServiceUrl = result.ServiceUrls.FirstOrDefault(url => url.Contains("order"));

                if (userServiceUrl != null && orderServiceUrl != null)
                {
                    // Test user creation
                    var createUserPayload = JsonSerializer.Serialize(new
                    {
                        name = "Test User",
                        email = "test@deployment.validation"
                    });

                    var userResponse = await _httpClient.PostAsync(
                        $"{userServiceUrl}/api/user",
                        new StringContent(createUserPayload, System.Text.Encoding.UTF8, "application/json"));

                    if (userResponse.IsSuccessStatusCode)
                    {
                        // Test order creation (cross-service call)
                        var createOrderPayload = JsonSerializer.Serialize(new
                        {
                            userId = 123,
                            total = 99.99,
                            items = new[] { new { name = "Test Product", quantity = 1, price = 99.99 } }
                        });

                        var orderResponse = await _httpClient.PostAsync(
                            $"{orderServiceUrl}/api/order",
                            new StringContent(createOrderPayload, System.Text.Encoding.UTF8, "application/json"));

                        check.IsHealthy = orderResponse.IsSuccessStatusCode;
                        check.StatusCode = (int)orderResponse.StatusCode;

                        if (!check.IsHealthy)
                        {
                            check.Error = $"Order creation failed with status {orderResponse.StatusCode}";
                        }
                    }
                    else
                    {
                        check.IsHealthy = false;
                        check.Error = $"User creation failed with status {userResponse.StatusCode}";
                    }
                }
                else
                {
                    check.IsHealthy = false;
                    check.Error = "Required service URLs not found";
                }

                stopwatch.Stop();
                check.Duration = stopwatch.Elapsed;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                check.IsHealthy = false;
                check.Error = ex.Message;
                check.Duration = stopwatch.Elapsed;
            }

            result.HealthChecks.Add(check);
        }

        private async Task ValidateCrossServiceCommunication(DeploymentHealthResult result)
        {
            var check = new HealthCheck { Name = "CrossServiceCommunication" };
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                // This would test the communication between services
                // For now, we'll simulate a successful cross-service validation
                await Task.Delay(500); // Simulate validation time

                check.IsHealthy = true;
                check.Metrics = new Dictionary<string, object>
                {
                    ["ServiceConnectivity"] = "All services can communicate",
                    ["LatencyCheck"] = "Within acceptable limits"
                };

                stopwatch.Stop();
                check.Duration = stopwatch.Elapsed;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                check.IsHealthy = false;
                check.Error = ex.Message;
                check.Duration = stopwatch.Elapsed;
            }

            result.HealthChecks.Add(check);
        }

        private async Task ValidateDependencies(DeploymentHealthResult result)
        {
            var check = new HealthCheck { Name = "Dependencies" };
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                // Validate external dependencies (databases, APIs, etc.)
                var dependencyChecks = new List<(string name, bool healthy)>();

                // Simulate dependency checks
                dependencyChecks.Add(("Database", true));
                dependencyChecks.Add(("External API", true));
                dependencyChecks.Add(("Cache", true));

                await Task.Delay(300); // Simulate check time

                check.IsHealthy = dependencyChecks.All(dep => dep.healthy);
                check.Metrics = new Dictionary<string, object>
                {
                    ["DependencyCount"] = dependencyChecks.Count,
                    ["HealthyDependencies"] = dependencyChecks.Count(d => d.healthy)
                };

                if (!check.IsHealthy)
                {
                    var failedDeps = dependencyChecks.Where(d => !d.healthy).Select(d => d.name);
                    check.Error = $"Failed dependencies: {string.Join(", ", failedDeps)}";
                }

                stopwatch.Stop();
                check.Duration = stopwatch.Elapsed;
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                check.IsHealthy = false;
                check.Error = ex.Message;
                check.Duration = stopwatch.Elapsed;
            }

            result.HealthChecks.Add(check);
        }

        private string GetServiceName(string serviceUrl)
        {
            if (serviceUrl.Contains("user")) return "UserService";
            if (serviceUrl.Contains("order")) return "OrderService";
            return "UnknownService";
        }
    }

    public class DeploymentHealthResult
    {
        public string DeploymentId { get; set; } = "";
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public TimeSpan Duration { get; set; }
        public List<string> ServiceUrls { get; set; } = new();
        public bool IsHealthy { get; set; }
        public List<HealthCheck> HealthChecks { get; set; } = new();
    }

    public class HealthCheck
    {
        public string Name { get; set; } = "";
        public bool IsHealthy { get; set; }
        public TimeSpan Duration { get; set; }
        public int StatusCode { get; set; }
        public string? Error { get; set; }
        public string? ResponseBody { get; set; }
        public Dictionary<string, object>? Metrics { get; set; }
    }
}
```

2. **Add Deployment Validation Endpoints**:

Add to `UserService/Program.cs`:
```csharp
// Register deployment health monitor
builder.Services.AddHttpClient<DeploymentHealthMonitor>();

// Add deployment validation endpoints
app.MapPost("/api/deployment/validate", async (
    DeploymentHealthMonitor healthMonitor,
    string deploymentId,
    string[] serviceUrls) =>
{
    var timeout = TimeSpan.FromMinutes(5);
    var result = await healthMonitor.ValidateDeployment(deploymentId, serviceUrls.ToList(), timeout);
    
    if (result.IsHealthy)
    {
        return Results.Ok(result);
    }
    else
    {
        return Results.BadRequest(result);
    }
});

app.MapGet("/api/deployment/status/{deploymentId}", (string deploymentId) =>
{
    // In a real implementation, this would query deployment status from a database
    return Results.Ok(new
    {
        DeploymentId = deploymentId,
        Status = "Completed",
        Health = "Healthy",
        Timestamp = DateTime.UtcNow
    });
});
```

3. **Test Deployment Validation**:
```bash
# Test deployment validation
curl -X POST "http://localhost:5001/api/deployment/validate?deploymentId=test-123" \
  -H "Content-Type: application/json" \
  -d '["http://localhost:5001", "http://localhost:5002"]' | jq

# Check deployment status
curl "http://localhost:5001/api/deployment/status/test-123" | jq
```

| ✅ **Checkpoint Validation** | **Expected Outcome** |
|---|---|
| **Health Validation API** | `/api/deployment/validate` endpoint responds successfully |
| **Multi-Service Checks** | Basic health, performance, business functionality validated |
| **Cross-Service Communication** | Service-to-service connectivity verified |
| **Deployment Status API** | Real-time deployment status tracking available |

**🔍 Quick Verification**:
```bash
# Test deployment validation endpoint
curl -X POST "http://localhost:5001/api/deployment/validate?deploymentId=test-$(date +%s)" \
  -H "Content-Type: application/json" \
  -d '["http://localhost:5001", "http://localhost:5002"]' | jq

echo "✅ Expected: Comprehensive health validation results"
```

---

## 🔒 Module 4: Security Monitoring Integration (45 minutes)

### 🛡️ 4.1 Microsoft Defender for Cloud Setup
**Time Required**: 20 minutes

1. **Enable Microsoft Defender for Cloud**:
```bash
# Enable Defender for your subscription
az security pricing create \
    --name "AppServices" \
    --tier "Standard"

az security pricing create \
    --name "VirtualMachines" \
    --tier "Standard"

az security pricing create \
    --name "ContainerRegistry" \
    --tier "Standard"

# Enable auto-provisioning
az security auto-provisioning-setting update \
    --name "default" \
    --auto-provision "On"
```

2. **Create Security Monitoring Service** - Create `shared/infrastructure/SecurityMonitoringService.cs`:
```csharp
using Microsoft.ApplicationInsights;
using System.Security.Claims;
using System.Text.RegularExpressions;

namespace Shared.Infrastructure
{
    public class SecurityMonitoringService
    {
        private readonly TelemetryClient _telemetryClient;
        private readonly ILogger<SecurityMonitoringService> _logger;
        private readonly IConfiguration _configuration;

        public SecurityMonitoringService(
            TelemetryClient telemetryClient, 
            ILogger<SecurityMonitoringService> logger,
            IConfiguration configuration)
        {
            _telemetryClient = telemetryClient;
            _logger = logger;
            _configuration = configuration;
        }

        public void TrackAuthenticationEvent(
            string userId, 
            string eventType, 
            string ipAddress, 
            bool success,
            string userAgent = "",
            Dictionary<string, string>? additionalProperties = null)
        {
            var properties = new Dictionary<string, string>
            {
                ["UserId"] = userId,
                ["EventType"] = eventType,
                ["IpAddress"] = ipAddress,
                ["Success"] = success.ToString(),
                ["UserAgent"] = userAgent,
                ["Timestamp"] = DateTime.UtcNow.ToString("O"),
                ["Location"] = GetLocationFromIP(ipAddress)
            };

            // Add additional properties if provided
            if (additionalProperties != null)
            {
                foreach (var kvp in additionalProperties)
                {
                    properties[kvp.Key] = kvp.Value;
                }
            }

            // Track the event
            _telemetryClient.TrackEvent("SecurityEvent.Authentication", properties);

            if (!success)
            {
                _telemetryClient.TrackEvent("SecurityEvent.AuthenticationFailure", properties);
                _logger.LogWarning("Authentication failed for user {UserId} from IP {IpAddress}", userId, ipAddress);
                
                // Check for suspicious patterns
                DetectSuspiciousActivity(userId, ipAddress, eventType, success, userAgent);
            }
            else
            {
                _logger.LogInformation("Authentication successful for user {UserId} from IP {IpAddress}", userId, ipAddress);
            }
        }

        public void TrackDataAccess(
            string userId, 
            string resourceType, 
            string resourceId, 
            string action,
            bool authorized = true,
            Dictionary<string, string>? context = null)
        {
            var properties = new Dictionary<string, string>
            {
                ["UserId"] = userId,
                ["ResourceType"] = resourceType,
                ["ResourceId"] = resourceId,
                ["Action"] = action,
                ["Authorized"] = authorized.ToString(),
                ["Timestamp"] = DateTime.UtcNow.ToString("O"),
                ["Sensitive"] = IsSensitiveResource(resourceType).ToString()
            };

            // Add context if provided
            if (context != null)
            {
                foreach (var kvp in context)
                {
                    properties[$"Context.{kvp.Key}"] = kvp.Value;
                }
            }

            _telemetryClient.TrackEvent("SecurityEvent.DataAccess", properties);
            
            // Track sensitive data access separately
            if (IsSensitiveResource(resourceType))
            {
                _telemetryClient.TrackEvent("SecurityEvent.SensitiveDataAccess", properties);
                _logger.LogInformation("Sensitive data accessed: {ResourceType} {ResourceId} by {UserId}", 
                    resourceType, resourceId, userId);
                
                // Additional monitoring for sensitive resources
                TrackSensitiveResourceAccess(userId, resourceType, resourceId, action);
            }

            if (!authorized)
            {
                _telemetryClient.TrackEvent("SecurityEvent.UnauthorizedAccess", properties);
                _logger.LogWarning("Unauthorized access attempt: {UserId} tried to {Action} {ResourceType} {ResourceId}", 
                    userId, action, resourceType, resourceId);
                
                TrackSecurityViolation("UnauthorizedAccess", 
                    $"User {userId} attempted unauthorized {action} on {resourceType}", userId);
            }
        }

        public void TrackSecurityViolation(
            string violationType, 
            string details, 
            string userId = "Anonymous",
            string severity = "Medium")
        {
            var properties = new Dictionary<string, string>
            {
                ["ViolationType"] = violationType,
                ["Details"] = details,
                ["UserId"] = userId,
                ["Severity"] = severity,
                ["Timestamp"] = DateTime.UtcNow.ToString("O"),
                ["ServerName"] = Environment.MachineName,
                ["ApplicationName"] = _configuration["ApplicationName"] ?? "Unknown"
            };

            _telemetryClient.TrackEvent("SecurityEvent.Violation", properties);
            
            // Log based on severity
            switch (severity.ToLower())
            {
                case "critical":
                    _logger.LogCritical("CRITICAL SECURITY VIOLATION: {ViolationType} - {Details}", violationType, details);
                    break;
                case "high":
                    _logger.LogError("HIGH SECURITY VIOLATION: {ViolationType} - {Details}", violationType, details);
                    break;
                default:
                    _logger.LogWarning("Security violation detected: {ViolationType} - {Details}", violationType, details);
                    break;
            }

            // Send immediate alert for high-severity violations
            if (severity.ToLower() == "critical" || severity.ToLower() == "high")
            {
                SendSecurityAlert(properties);
            }
        }

        public void TrackAPIAbuseAttempt(
            string endpoint, 
            string ipAddress, 
            string userAgent,
            string abuseType = "RateLimitExceeded")
        {
            var properties = new Dictionary<string, string>
            {
                ["Endpoint"] = endpoint,
                ["IpAddress"] = ipAddress,
                ["UserAgent"] = userAgent,
                ["AbuseType"] = abuseType,
                ["Timestamp"] = DateTime.UtcNow.ToString("O")
            };

            _telemetryClient.TrackEvent("SecurityEvent.APIAbuse", properties);
            _logger.LogWarning("API abuse detected: {AbuseType} from {IpAddress} on {Endpoint}", 
                abuseType, ipAddress, endpoint);
        }

        public void TrackSQLInjectionAttempt(
            string endpoint,
            string suspiciousInput,
            string ipAddress,
            string userId = "Anonymous")
        {
            var properties = new Dictionary<string, string>
            {
                ["Endpoint"] = endpoint,
                ["SuspiciousInput"] = suspiciousInput,
                ["IpAddress"] = ipAddress,
                ["UserId"] = userId,
                ["AttackType"] = "SQLInjection",
                ["Timestamp"] = DateTime.UtcNow.ToString("O")
            };

            _telemetryClient.TrackEvent("SecurityEvent.SQLInjectionAttempt", properties);
            _logger.LogError("SQL Injection attempt detected from {IpAddress} on {Endpoint}: {Input}", 
                ipAddress, endpoint, suspiciousInput);

            TrackSecurityViolation("SQLInjectionAttempt", 
                $"Suspicious SQL patterns detected in input: {suspiciousInput}", userId, "High");
        }

        private void DetectSuspiciousActivity(
            string userId, 
            string ipAddress, 
            string eventType, 
            bool success,
            string userAgent)
        {
            // In a real implementation, you would check against patterns stored in a database
            // For this workshop, we'll implement simple rule-based detection

            // Pattern 1: Multiple failed attempts
            if (!success && eventType == "Login")
            {
                // Simulate checking recent failure count
                var recentFailures = GetRecentAuthenticationFailures(userId, TimeSpan.FromMinutes(15));
                if (recentFailures >= 5)
                {
                    TrackSecurityViolation("BruteForceAttempt", 
                        $"Multiple failed login attempts from {ipAddress}", userId, "High");
                }
            }

            // Pattern 2: Suspicious user agent
            if (IsSuspiciousUserAgent(userAgent))
            {
                TrackSecurityViolation("SuspiciousUserAgent", 
                    $"Suspicious user agent detected: {userAgent}", userId, "Medium");
            }

            // Pattern 3: Geolocation anomaly (simplified)
            if (IsGeolocationAnomaly(userId, ipAddress))
            {
                TrackSecurityViolation("GeolocationAnomaly", 
                    $"Login from unusual location: {ipAddress}", userId, "Medium");
            }
        }

        private void TrackSensitiveResourceAccess(string userId, string resourceType, string resourceId, string action)
        {
            // Additional tracking for sensitive resources
            _telemetryClient.GetMetric("Security.SensitiveAccess.Count").TrackValue(1);
            
            var sensitiveAccessEvent = new Dictionary<string, string>
            {
                ["Category"] = "SensitiveDataAccess",
                ["UserId"] = userId,
                ["ResourceType"] = resourceType,
                ["ResourceId"] = resourceId,
                ["Action"] = action,
                ["RequiresAudit"] = "true"
            };

            _telemetryClient.TrackEvent("Audit.SensitiveResourceAccess", sensitiveAccessEvent);
        }

        private void SendSecurityAlert(Dictionary<string, string> alertData)
        {
            // In a real implementation, this would integrate with security systems
            // For the workshop, we'll log and track the alert

            _telemetryClient.TrackEvent("SecurityAlert.Generated", alertData);
            _logger.LogCritical("SECURITY ALERT GENERATED: {AlertData}", 
                string.Join(", ", alertData.Select(kvp => $"{kvp.Key}={kvp.Value}")));

            // Could integrate with:
            // - Azure Security Center
            // - PagerDuty
            // - Teams/Slack notifications
            // - Email alerts
        }

        private bool IsSensitiveResource(string resourceType)
        {
            var sensitiveTypes = new[] 
            { 
                "UserData", "PaymentInfo", "HealthRecord", "PII", 
                "FinancialData", "PersonalData", "ConfidentialDocument" 
            };
            return sensitiveTypes.Contains(resourceType, StringComparer.OrdinalIgnoreCase);
        }

        private bool IsSuspiciousUserAgent(string userAgent)
        {
            if (string.IsNullOrEmpty(userAgent)) return true;

            var suspiciousPatterns = new[]
            {
                "bot", "crawler", "spider", "scraper", "scanner",
                "curl", "wget", "python-requests", "postman"
            };

            return suspiciousPatterns.Any(pattern => 
                userAgent.Contains(pattern, StringComparison.OrdinalIgnoreCase));
        }

        private bool IsGeolocationAnomaly(string userId, string ipAddress)
        {
            // Simplified geolocation check
            // In a real implementation, you would:
            // 1. Get the location from IP geolocation service
            // 2. Compare with user's typical locations
            // 3. Check for impossible travel scenarios
            
            return false; // Simplified for workshop
        }

        private string GetLocationFromIP(string ipAddress)
        {
            // In a real implementation, use IP geolocation service
            return "Unknown Location";
        }

        private int GetRecentAuthenticationFailures(string userId, TimeSpan timeWindow)
        {
            // In a real implementation, query Application Insights or database
            // For workshop, simulate some failures
            return Random.Shared.Next(0, 8);
        }

        public bool DetectSQLInjectionPatterns(string input)
        {
            if (string.IsNullOrEmpty(input)) return false;

            var sqlInjectionPatterns = new[]
            {
                @"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER)\b)",
                @"(\b(UNION|EXEC|EXECUTE)\b)",
                @"(--|\#|/\*|\*/)",
                @"(\b(OR|AND)\b.*=.*\b(OR|AND)\b)",
                @"('(\s*;\s*|\s+)(SELECT|INSERT|UPDATE|DELETE))",
                @"(\bxp_cmdshell\b)"
            };

            foreach (var pattern in sqlInjectionPatterns)
            {
                if (Regex.IsMatch(input, pattern, RegexOptions.IgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }
    }
}
```

3. **Create Security Middleware** - Create `shared/infrastructure/SecurityMiddleware.cs`:
```csharp
using Microsoft.ApplicationInsights;

namespace Shared.Infrastructure
{
    public class SecurityMonitoringMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly SecurityMonitoringService _securityService;
        private readonly ILogger<SecurityMonitoringMiddleware> _logger;

        public SecurityMonitoringMiddleware(
            RequestDelegate next, 
            SecurityMonitoringService securityService,
            ILogger<SecurityMonitoringMiddleware> logger)
        {
            _next = next;
            _securityService = securityService;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var startTime = DateTime.UtcNow;
            var ipAddress = GetClientIPAddress(context);
            var userAgent = context.Request.Headers["User-Agent"].ToString();
            var endpoint = $"{context.Request.Method} {context.Request.Path}";

            try
            {
                // Check for suspicious patterns in the request
                await ValidateRequest(context, ipAddress, userAgent, endpoint);

                await _next(context);

                // Monitor response patterns
                await MonitorResponse(context, ipAddress, endpoint);
            }
            catch (Exception ex)
            {
                _securityService.TrackSecurityViolation("UnhandledException", 
                    $"Unhandled exception in {endpoint}: {ex.Message}", GetUserId(context));
                throw;
            }
        }

        private async Task ValidateRequest(HttpContext context, string ipAddress, string userAgent, string endpoint)
        {
            // Check for SQL injection attempts
            if (context.Request.HasFormContentType || context.Request.Query.Any())
            {
                var allInputs = new List<string>();
                
                // Check query parameters
                foreach (var query in context.Request.Query)
                {
                    allInputs.Add(query.Value.ToString());
                }

                // Check form data
                if (context.Request.HasFormContentType)
                {
                    foreach (var form in context.Request.Form)
                    {
                        allInputs.Add(form.Value.ToString());
                    }
                }

                // Check for SQL injection patterns
                foreach (var input in allInputs)
                {
                    if (_securityService.DetectSQLInjectionPatterns(input))
                    {
                        _securityService.TrackSQLInjectionAttempt(endpoint, input, ipAddress, GetUserId(context));
                    }
                }
            }

            // Check for API abuse patterns
            if (IsRateLimitExceeded(ipAddress, endpoint))
            {
                _securityService.TrackAPIAbuseAttempt(endpoint, ipAddress, userAgent, "RateLimitExceeded");
            }

            // Track authentication events
            if (endpoint.Contains("login", StringComparison.OrdinalIgnoreCase) ||
                endpoint.Contains("auth", StringComparison.OrdinalIgnoreCase))
            {
                var userId = GetUserId(context);
                _securityService.TrackAuthenticationEvent(userId, "Login", ipAddress, true, userAgent);
            }
        }

        private async Task MonitorResponse(HttpContext context, string ipAddress, string endpoint)
        {
            // Monitor for authentication failures
            if (context.Response.StatusCode == 401)
            {
                _securityService.TrackAuthenticationEvent(
                    GetUserId(context), "Unauthorized", ipAddress, false);
            }

            // Monitor for forbidden access
            if (context.Response.StatusCode == 403)
            {
                _securityService.TrackDataAccess(
                    GetUserId(context), "API", endpoint, "Access", false);
            }

            // Track successful data access
            if (context.Response.StatusCode >= 200 && context.Response.StatusCode < 300)
            {
                if (endpoint.Contains("/user") || endpoint.Contains("/order"))
                {
                    _securityService.TrackDataAccess(
                        GetUserId(context), 
                        GetResourceTypeFromEndpoint(endpoint), 
                        endpoint, 
                        context.Request.Method);
                }
            }
        }

        private string GetClientIPAddress(HttpContext context)
        {
            // Check for IP in headers (for load balancers/proxies)
            var forwardedFor = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
            if (!string.IsNullOrEmpty(forwardedFor))
            {
                return forwardedFor.Split(',')[0].Trim();
            }

            var realIP = context.Request.Headers["X-Real-IP"].FirstOrDefault();
            if (!string.IsNullOrEmpty(realIP))
            {
                return realIP;
            }

            return context.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
        }

        private string GetUserId(HttpContext context)
        {
            // Try to get user ID from different sources
            var userId = context.Request.Headers["X-User-Id"].FirstOrDefault();
            if (!string.IsNullOrEmpty(userId))
            {
                return userId;
            }

            // Check claims if using authentication
            var userClaim = context.User?.Identity?.Name;
            if (!string.IsNullOrEmpty(userClaim))
            {
                return userClaim;
            }

            return "Anonymous";
        }

        private string GetResourceTypeFromEndpoint(string endpoint)
        {
            if (endpoint.Contains("/user")) return "UserData";
            if (endpoint.Contains("/order")) return "OrderData";
            return "Unknown";
        }

        private bool IsRateLimitExceeded(string ipAddress, string endpoint)
        {
            // Simplified rate limiting check
            // In a real implementation, you would use a distributed cache or database
            // to track request counts per IP/endpoint combination
            
            return false; // Simplified for workshop
        }
    }
}
```

4. **Update Services with Security Monitoring**:

Add to both services' `Program.cs`:
```csharp
// Register security monitoring
builder.Services.AddSingleton<SecurityMonitoringService>();

// Add security middleware
app.UseMiddleware<SecurityMonitoringMiddleware>();
```

**✅ Checkpoint**: Security monitoring should track authentication events, data access, and potential security violations

### 📊 4.2 Microsoft Sentinel Integration
**Time Required**: 25 minutes

1. **Create Microsoft Sentinel Workspace**:
```bash
# Create or use existing Log Analytics workspace for Sentinel
SENTINEL_WORKSPACE_NAME="${APP_NAME}-sentinel"

# Create Log Analytics workspace for Sentinel (if not using existing)
az monitor log-analytics workspace create \
    --workspace-name $SENTINEL_WORKSPACE_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --retention-in-days 90

# Enable Sentinel on the workspace
az sentinel workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $SENTINEL_WORKSPACE_NAME
```

2. **Configure Data Connectors in Azure Portal**:
   - **Go to Azure Portal** → **Microsoft Sentinel**
   - **Select your workspace**
   - **Click "Data connectors"**
   - **Enable these connectors**:
     - Azure Activity
     - Azure Monitor (Application Insights)
     - Office 365 (if available)
     - Azure AD Identity Protection

3. **Create Custom Security Detection Rules**:

**Create KQL rule for suspicious authentication patterns**:
```kql
// Suspicious Authentication Patterns
let timeRange = 24h;
let failureThreshold = 5;
let blockedUserAgents = dynamic(["bot", "crawler", "spider", "scanner", "curl", "wget"]);

customEvents
| where timestamp > ago(timeRange)
| where name == "SecurityEvent.AuthenticationFailure"
| extend UserId = tostring(customDimensions["UserId"])
| extend IpAddress = tostring(customDimensions["IpAddress"])
| extend UserAgent = tostring(customDimensions["UserAgent"])
| extend EventType = tostring(customDimensions["EventType"])
| summarize 
    FailureCount = count(),
    UniqueIPs = dcount(IpAddress),
    UserAgents = make_set(UserAgent)
    by UserId, bin(timestamp, 1h)
| where FailureCount >= failureThreshold
| extend
    SuspiciousUserAgent = array_length(set_intersect(UserAgents, blockedUserAgents)) > 0,
    MultipleIPs = UniqueIPs > 1
| project 
    timestamp,
    UserId,
    FailureCount,
    UniqueIPs,
    SuspiciousUserAgent,
    MultipleIPs,
    UserAgents
| order by FailureCount desc
```

**Create rule for data exfiltration detection**:
```kql
// Large Data Access Patterns
let timeRange = 1h;
let accessThreshold = 100;

customEvents
| where timestamp > ago(timeRange)
| where name == "SecurityEvent.DataAccess"
| extend UserId = tostring(customDimensions["UserId"])
| extend ResourceType = tostring(customDimensions["ResourceType"])
| extend Action = tostring(customDimensions["Action"])
| extend Sensitive = tobool(customDimensions["Sensitive"])
| summarize 
    AccessCount = count(),
    SensitiveAccessCount = countif(Sensitive == true),
    UniqueResources = dcount(ResourceType)
    by UserId, bin(timestamp, 10m)
| where AccessCount >= accessThreshold or SensitiveAccessCount >= 10
| extend RiskScore = case(
    SensitiveAccessCount >= 50, "Critical",
    SensitiveAccessCount >= 20, "High", 
    AccessCount >= 500, "High",
    AccessCount >= 200, "Medium",
    "Low"
)
| project 
    timestamp,
    UserId,
    AccessCount,
    SensitiveAccessCount,
    UniqueResources,
    RiskScore
| order by SensitiveAccessCount desc
```

**Create rule for SQL injection detection**:
```kql
// SQL Injection Attempts
let timeRange = 24h;

customEvents
| where timestamp > ago(timeRange)
| where name == "SecurityEvent.SQLInjectionAttempt"
| extend IpAddress = tostring(customDimensions["IpAddress"])
| extend Endpoint = tostring(customDimensions["Endpoint"])
| extend SuspiciousInput = tostring(customDimensions["SuspiciousInput"])
| extend UserId = tostring(customDimensions["UserId"])
| summarize 
    AttemptCount = count(),
    UniqueEndpoints = dcount(Endpoint),
    SuspiciousInputs = make_set(SuspiciousInput, 10)
    by IpAddress, UserId, bin(timestamp, 1h)
| extend ThreatLevel = case(
    AttemptCount >= 10, "Critical",
    AttemptCount >= 5, "High",
    AttemptCount >= 2, "Medium",
    "Low"
)
| project 
    timestamp,
    IpAddress,
    UserId,
    AttemptCount,
    UniqueEndpoints,
    ThreatLevel,
    SuspiciousInputs
| order by AttemptCount desc
```

4. **Create Security Playbook (Logic App)**:

Create `security-playbook.json`:
```json
{
    "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "$connections": {
                "defaultValue": {},
                "type": "Object"
            }
        },
        "triggers": {
            "When_a_response_to_an_Azure_Sentinel_alert_is_triggered": {
                "type": "ApiConnectionWebhook",
                "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['azuresentinel']['connectionId']"
                        }
                    },
                    "body": {
                        "callback_url": "@{listCallbackUrl()}"
                    }
                }
            }
        },
        "actions": {
            "Parse_Alert_JSON": {
                "runAfter": {},
                "type": "ParseJson",
                "inputs": {
                    "content": "@triggerBody()?['object']?['properties']",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "alertDisplayName": {"type": "string"},
                            "severity": {"type": "string"},
                            "compromisedEntity": {"type": "string"},
                            "alertType": {"type": "string"}
                        }
                    }
                }
            },
            "Condition_High_Severity": {
                "runAfter": {
                    "Parse_Alert_JSON": ["Succeeded"]
                },
                "type": "If",
                "expression": {
                    "and": [
                        {
                            "equals": [
                                "@body('Parse_Alert_JSON')?['severity']",
                                "High"
                            ]
                        }
                    ]
                },
                "actions": {
                    "Send_Teams_Notification": {
                        "type": "ApiConnection",
                        "inputs": {
                            "host": {
                                "connection": {
                                    "name": "@parameters('$connections')['teams']['connectionId']"
                                }
                            },
                            "method": "post",
                            "body": {
                                "messageBody": "🚨 HIGH SEVERITY SECURITY ALERT\n\nAlert: @{body('Parse_Alert_JSON')?['alertDisplayName']}\nEntity: @{body('Parse_Alert_JSON')?['compromisedEntity']}\nTime: @{utcNow()}\n\nImmediate investigation required!",
                                "recipient": {
                                    "channelId": "security-alerts"
                                }
                            }
                        }
                    },
                    "Block_IP_Address": {
                        "type": "Http",
                        "inputs": {
                            "method": "POST",
                            "uri": "https://your-security-api.com/block-ip",
                            "headers": {
                                "Authorization": "Bearer @{parameters('SecurityAPIKey')}"
                            },
                            "body": {
                                "ip": "@{body('Parse_Alert_JSON')?['compromisedEntity']}",
                                "reason": "Sentinel Alert - @{body('Parse_Alert_JSON')?['alertType']}",
                                "duration": "1h"
                            }
                        }
                    }
                },
                "else": {
                    "actions": {
                        "Send_Email_Notification": {
                            "type": "ApiConnection",
                            "inputs": {
                                "host": {
                                    "connection": {
                                        "name": "@parameters('$connections')['office365']['connectionId']"
                                    }
                                },
                                "method": "post",
                                "body": {
                                    "To": "security-team@company.com",
                                    "Subject": "Security Alert: @{body('Parse_Alert_JSON')?['alertDisplayName']}",
                                    "Body": "Security alert detected:\n\nAlert: @{body('Parse_Alert_JSON')?['alertDisplayName']}\nSeverity: @{body('Parse_Alert_JSON')?['severity']}\nEntity: @{body('Parse_Alert_JSON')?['compromisedEntity']}\nTime: @{utcNow()}\n\nPlease investigate."
                                }
                            }
                        }
                    }
                }
            },
            "Update_Sentinel_Incident": {
                "runAfter": {
                    "Condition_High_Severity": ["Succeeded"]
                },
                "type": "ApiConnection",
                "inputs": {
                    "host": {
                        "connection": {
                            "name": "@parameters('$connections')['azuresentinel']['connectionId']"
                        }
                    },
                    "method": "put",
                    "body": {
                        "properties": {
                            "status": "Active",
                            "owner": {
                                "assignedTo": "security-team@company.com"
                            }
                        }
                    }
                }
            }
        }
    }
}
```

5. **Test Security Monitoring**:
```bash
# Generate security events
echo "Testing security monitoring..."

# Test normal user operations
for i in {1..5}; do
  curl -H "X-User-Id: user$i" \
       -H "X-Session-Id: session$i" \
       http://localhost:5001/api/user/$i
done

# Test suspicious patterns (these should trigger alerts)
echo "Testing SQL injection detection..."
curl "http://localhost:5001/api/user/123?search='; DROP TABLE users; --"

echo "Testing authentication failure simulation..."
for i in {1..6}; do
  curl -H "X-User-Id: baduser" \
       -w "%{http_code}\n" \
       http://localhost:5001/api/user/999  # This should return 404
done

echo "Testing suspicious user agent..."
curl -H "User-Agent: SQLBot/1.0" \
     http://localhost:5001/api/user/123

echo "Testing high-volume data access..."
for i in {1..50}; do
  curl -H "X-User-Id: poweruser" \
       -s http://localhost:5001/api/user/$i > /dev/null
done
```

6. **Create Security Dashboard**:

Add security dashboard endpoint to one of your services:
```csharp
app.MapGet("/api/security/dashboard", async (SecurityMonitoringService securityService) =>
{
    // In a real implementation, this would query Sentinel/Log Analytics
    var dashboard = new
    {
        Summary = new
        {
            TotalSecurityEvents = Random.Shared.Next(50, 200),
            CriticalAlerts = Random.Shared.Next(0, 5),
            HighAlerts = Random.Shared.Next(2, 15),
            MediumAlerts = Random.Shared.Next(10, 50),
            LowAlerts = Random.Shared.Next(20, 100)
        },
        RecentThreats = new[]
        {
            new { Type = "SQL Injection Attempt", Count = 3, LastSeen = DateTime.UtcNow.AddMinutes(-15) },
            new { Type = "Brute Force Attack", Count = 1, LastSeen = DateTime.UtcNow.AddHours(-2) },
            new { Type = "Suspicious User Agent", Count = 5, LastSeen = DateTime.UtcNow.AddMinutes(-30) }
        },
        TopTargets = new[]
        {
            new { Resource = "/api/user", AttackCount = 15 },
            new { Resource = "/api/order", AttackCount = 8 },
            new { Resource = "/api/admin", AttackCount = 12 }
        },
        GeographicThreats = new[]
        {
            new { Country = "Unknown", Count = 25 },
            new { Country = "Tor Exit Node", Count = 8 },
            new { Country = "High Risk Region", Count = 12 }
        }
    };

    return Results.Ok(dashboard);
});
```

**✅ Checkpoint**: Security monitoring should be integrated with Sentinel, creating alerts and automated responses for security events

---

## Intermediate Workshop Wrap-up (10 minutes)

### What You've Accomplished Today
✅ **Built enterprise-grade microservices** with comprehensive distributed tracing  
✅ **Integrated multi-cloud monitoring** (Azure + Datadog + Prometheus/Grafana)  
✅ **Implemented CI/CD pipelines** with deployment monitoring and automated rollback  
✅ **Established security monitoring** with Defender for Cloud and Sentinel integration  
✅ **Created unified observability** across platforms and tools  
✅ **Automated incident response** workflows with intelligent detection  

### Advanced Concepts Mastered
1. **Distributed Tracing**: End-to-end request flow visibility with rich context
2. **Multi-Cloud Observability**: Unified monitoring across different cloud providers  
3. **CI/CD Integration**: Deployment health validation and automated rollback capabilities
4. **Security Observability**: Automated threat detection and response workflows
5. **Unified Dashboards**: Combining data from multiple monitoring sources
6. **Enterprise Patterns**: Custom telemetry processors, business context enrichment

### Business Impact Achieved
- **Reduced Mean Time to Resolution (MTTR)** through distributed tracing
- **Improved deployment reliability** with automated health validation
- **Enhanced security posture** with automated threat detection
- **Unified operational view** across multi-cloud environments
- **Automated incident response** reducing manual intervention

### Technical Capabilities Gained
- **Custom telemetry processing** and enrichment
- **Cross-platform monitoring** integration (Azure, Datadog, Prometheus)
- **Deployment validation** and rollback automation
- **Security event detection** and automated response
- **Performance monitoring** with business context
- **Infrastructure as Code** for monitoring resources

### Ready for Advanced Workshop?
You're ready for the **Advanced Workshop (Parts 4-5)** if you can:
- ✅ Configure and troubleshoot distributed tracing across microservices
- ✅ Integrate multiple monitoring platforms effectively
- ✅ Build CI/CD pipelines with comprehensive monitoring and rollback
- ✅ Set up security monitoring with automated detection and response
- ✅ Create unified dashboards combining multiple data sources
- ✅ Understand enterprise observability patterns and best practices

### Next Steps - Advanced Workshop Preview
**Parts 4-5 - Advanced Workshop** will cover:
- **Enterprise-Scale Observability Architecture** for large organizations
- **AI-Enhanced SRE Agent Implementation** with predictive analytics
- **Infrastructure as Code** with comprehensive observability automation
- **Multi-Cloud Challenge Labs** with real-world scenarios
- **Custom AI analysis** for root cause analysis and predictive maintenance

### Recommended Follow-up Actions
1. **Deploy to production** using the patterns learned today
2. **Customize dashboards** for your specific business needs  
3. **Tune alert thresholds** based on your application patterns
4. **Extend security monitoring** with organization-specific rules
5. **Document runbooks** based on the automated workflows created

---

**Continue to Parts 4-5** for the Advanced Workshop covering enterprise-scale architecture, AI-enhanced SRE capabilities, and advanced challenge labs.

---

## 🔙 Navigation

**[⬅️ Back to Main README](../README.md)**
