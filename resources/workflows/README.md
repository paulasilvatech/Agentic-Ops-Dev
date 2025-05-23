# GitHub Actions Workflows for Observability

This directory contains GitHub Actions workflows that demonstrate DevOps best practices with integrated observability. These workflows are designed to work with the Azure Observability Workshop infrastructure.

## 📋 Available Workflows

### 1. Deploy Observability Infrastructure (`deploy-observability.yml`)
**Purpose**: Automates the deployment of the complete observability stack including Azure infrastructure, monitoring tools, and sample applications.

**Triggers**:
- Manual workflow dispatch with environment selection
- Configurable options for AI monitoring deployment

**Key Features**:
- Infrastructure validation before deployment
- Terraform-based Azure resource provisioning
- Automated application container builds
- Monitoring stack deployment (Prometheus, Grafana, Jaeger)
- AI-enhanced monitoring setup (optional)
- Integration testing and validation

**Required Secrets**:
- `AZURE_CREDENTIALS`: Azure service principal credentials
- `SLACK_WEBHOOK`: Slack notification webhook (optional)

### 2. Application CI/CD with Observability (`application-cicd.yml`)
**Purpose**: Demonstrates a complete CI/CD pipeline with integrated observability at every stage.

**Triggers**:
- Push to main or develop branches
- Pull requests to main branch
- Changes to application code

**Key Features**:
- Code quality and security scanning
- Unit testing with coverage reporting
- Container image building with telemetry
- Staged deployments (staging → production)
- Performance validation between stages
- Blue-green deployment strategy
- Progressive rollout with health monitoring
- Comprehensive observability validation

**Required Secrets**:
- `AZURE_CREDENTIALS`: Azure service principal credentials
- `APP_INSIGHTS_KEY`: Application Insights instrumentation key
- `APP_INSIGHTS_CONNECTION_STRING`: Full connection string
- `SONAR_TOKEN`: SonarCloud authentication token
- `SNYK_TOKEN`: Snyk security scanning token
- `GRAFANA_API_KEY`: Grafana API key for annotations

### 3. Observability Health Check (`observability-monitoring.yml`)
**Purpose**: Scheduled monitoring to ensure all observability components are functioning correctly.

**Triggers**:
- Hourly schedule (cron)
- Manual dispatch with environment selection
- Optional deep analysis mode

**Key Features**:
- Prometheus health and target validation
- Log ingestion rate monitoring
- Distributed tracing validation
- Alert routing verification
- Dashboard performance checks
- SLO compliance monitoring
- AI monitoring validation
- Comprehensive health reporting

**Validation Checks**:
- Metrics collection and freshness
- Log parsing and retention
- Trace propagation completeness
- Alert manager functionality
- Dashboard query performance
- SLO/SLI calculations
- AI agent health

## 🚀 Getting Started

### Prerequisites
1. Fork this repository to your GitHub account
2. Set up required GitHub secrets in your repository settings
3. Ensure Azure subscription is properly configured
4. Have the workshop infrastructure deployed

### Setting Up Secrets

Navigate to your repository's Settings → Secrets and variables → Actions, then add:

```yaml
# Azure Authentication
AZURE_CREDENTIALS: |
  {
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "subscriptionId": "your-subscription-id",
    "tenantId": "your-tenant-id"
  }

# Application Insights
APP_INSIGHTS_KEY: "your-instrumentation-key"
APP_INSIGHTS_CONNECTION_STRING: "InstrumentationKey=...;IngestionEndpoint=..."

# Third-party Services
SONAR_TOKEN: "your-sonarcloud-token"
SNYK_TOKEN: "your-snyk-token"
GRAFANA_API_KEY: "your-grafana-api-key"

# Notifications (Optional)
SLACK_WEBHOOK: "https://hooks.slack.com/services/..."
```

### Running Workflows

1. **Deploy Infrastructure**:
   ```bash
   gh workflow run deploy-observability.yml \
     -f environment=development \
     -f azure_subscription_id=your-sub-id \
     -f deploy_ai_monitoring=true
   ```

2. **Trigger CI/CD Pipeline**:
   - Simply push code changes to trigger automatic builds
   - Create pull requests for code review with automated testing

3. **Manual Health Check**:
   ```bash
   gh workflow run observability-monitoring.yml \
     -f environment=production \
     -f deep_analysis=true
   ```

## 📊 Workflow Integration Points

### Metrics Collection
All workflows send custom metrics to Application Insights:
- Build duration and success rates
- Deployment frequency and lead time
- Test execution results
- Performance benchmarks

### Distributed Tracing
Workflows demonstrate trace context propagation:
- Build-to-deployment correlation
- Cross-service transaction tracking
- Performance bottleneck identification

### Logging
Structured logging throughout workflows:
- Consistent log formatting
- Correlation IDs for tracking
- Error aggregation and analysis

### Alerting
Automated alerts for:
- Build failures
- Deployment issues
- Performance degradation
- SLO violations

## 🔧 Customization

### Adding New Applications
1. Add application to the build matrix in `application-cicd.yml`
2. Ensure Dockerfile includes telemetry configuration
3. Add corresponding Kubernetes manifests

### Modifying Deployment Strategies
The workflows support multiple deployment patterns:
- **Blue-Green**: Modify `blue-green-deploy.sh` script
- **Canary**: Adjust `progressive-rollout.sh` parameters
- **Rolling**: Configure in Kubernetes deployment specs

### Extending Health Checks
Add new validation steps to `observability-monitoring.yml`:
```yaml
- name: Custom Validation
  run: |
    ./resources/scripts/your-custom-check.sh \
      --environment ${{ inputs.environment }}
```

## 📈 Monitoring Workflow Performance

### Workflow Metrics Dashboard
Import the included Grafana dashboard to monitor:
- Workflow execution times
- Success/failure rates
- Resource utilization
- Cost analysis

### Workflow Observability
Each workflow includes:
- Detailed logging at each step
- Performance timing annotations
- Error tracking and reporting
- Resource usage monitoring

## 🛠️ Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify Azure credentials are correctly formatted JSON
   - Check service principal permissions
   - Ensure subscription ID matches

2. **Container Registry Access**
   - Verify ACR authentication in workflows
   - Check repository permissions
   - Ensure image tags are correct

3. **Monitoring Stack Errors**
   - Check Kubernetes cluster connectivity
   - Verify namespace creation
   - Review resource quotas

### Debug Mode
Enable debug logging in workflows:
```yaml
env:
  ACTIONS_RUNNER_DEBUG: true
  ACTIONS_STEP_DEBUG: true
```

## 🤝 Contributing

When adding new workflows:
1. Follow the existing naming conventions
2. Include comprehensive documentation
3. Add error handling and retries
4. Include observability integration
5. Test in a development environment first

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure DevOps Integration](https://docs.microsoft.com/en-us/azure/devops/)
- [Grafana API Documentation](https://grafana.com/docs/grafana/latest/http_api/)
- [Prometheus Operator](https://prometheus-operator.dev/)

## 📝 Workshop Integration

These workflows are designed to complement the workshop modules:
- **Module 2**: Basic monitoring setup → `deploy-observability.yml`
- **Module 3**: Dashboards and alerts → Dashboard validation in workflows
- **Module 4**: Distributed tracing → Trace validation steps
- **Module 6**: AI monitoring → AI agent validation
- **Module 7**: Enterprise patterns → Full CI/CD demonstration

Use these workflows as reference implementations for your own observability-integrated CI/CD pipelines! 