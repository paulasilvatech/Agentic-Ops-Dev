# Agentic Operations and Observability

Welcome to the **Agentic Operations & Obervability** Workshop! This hands-on workshop guides you through implementing comprehensive observability solutions for cloud applications using Azure Monitor, Application Insights, and new AI-powered tools like Azure SRE Agent.

[![Workshop Website](https://img.shields.io/badge/Official%20Website-agentic--ops.dev-blue)](https://agentic-ops.dev)
[![GitHub Stars](https://img.shields.io/github/stars/paulasilvatech/Agentic-Ops-Dev?style=social)](https://github.com/paulasilvatech/Agentic-Ops-Dev)
[![License](https://img.shields.io/github/license/paulasilvatech/Agentic-Ops-Dev)](LICENSE)

## Agentic DevOps Workflow - Observability Implementation

![Azure Observability Banner](./images/azure-observability-banner.svg)

## Official Workshop Website: [agentic-ops.dev](https://agentic-ops.dev)

## The Journey to AI-Enhanced Observability

Welcome to the Azure AI Ops Observability Workshop! This repository takes you on a transformative journey from traditional monitoring to the world of AI-assisted observability and agentic DevOps.

As a cloud engineer in today's distributed systems environment, you face a critical challenge: **traditional monitoring only shows you what's wrong, not why or how to fix it**. According to the observability introduction:

* Traditional monitoring approaches only catch problems you anticipated
* High alert fatigue leads to missed critical issues (false positives)
* Difficult to correlate issues across distributed microservices
* Reactive troubleshooting instead of proactive optimization

This workshop provides hands-on guidance to implement modern observability using the three pillars approach - metrics, logs, and traces - enhanced with AI capabilities. We'll demonstrate how Azure SRE Agent and other advanced tools can transform your monitoring strategy.

> "Observability is not about the data you collect, but about the questions you can answer with that data."

## Business Impact

Organizations implementing comprehensive observability report significant benefits:

* **Faster Time to Resolution**: Reduce mean time to recovery (MTTR) from hours to minutes
* **Proactive Issue Detection**: Find problems before customers do
* **Reduced Alert Fatigue**: 80% reduction in false positives with AI-enhanced alerting
* **Cost Optimization**: Identify and eliminate waste in cloud resources
* **Team Efficiency**: Shift from 60% reactive firefighting to 70% proactive improvements

Advanced observability enables the progression through four maturity stages:
1. **Reactive**: Basic monitoring and alerting
2. **Proactive**: Trend analysis and capacity planning
3. **Predictive**: Anomaly detection and forecasting
4. **Autonomous**: Self-healing and optimization

![Agentic DevOps Workflow](./images/agentic-devops-workflow.svg)

## Workshop Structure

The workshop is organized into progressive modules, allowing you to choose the depth of coverage based on your time and experience:

| Level | Duration | Focus | Best For |
|-------|----------|-------|----------|
| **Essential** | 2 hours | Core concepts and setup | Beginners, time-constrained sessions |
| **Standard** | 4 hours | Complete implementation | Intermediate users, standard workshops |
| **Advanced** | 8+ hours | Enterprise-scale solutions | Experienced practitioners, deep dives |

## Learning Path

### Module 1: Introduction to Observability
- Foundation concepts and technologies
- The three pillars: Metrics, Logs, and Traces
- Azure observability ecosystem overview

### Module 2: Beginning Your Observability Journey
- Workshop preparation and account setup
- Creating your first monitoring solution
- Exploring Azure Monitor fundamentals

### Module 3: Building Dashboards and Alerts
- Creating custom dashboards
- Setting up intelligent alerts
- Using GitHub Copilot for monitoring queries

### Module 4: Advanced Application Insights
- Distributed tracing across microservices
- Custom telemetry and business metrics
- Advanced performance monitoring

### Module 5: Multi-Cloud Integration
- Monitoring across Azure, AWS, and GCP
- Centralized observability platform
- Cross-cloud correlation and insights

### Module 6: AI-Enhanced Monitoring
- Azure SRE Agent implementation
- Intelligent incident detection and response
- Predictive analytics and anomaly detection

### Module 7: Enterprise Implementation
- Scalable observability architecture
- Governance and compliance monitoring
- Cost optimization strategies

### Module 8: Hands-On Challenge Labs
- Real-world troubleshooting scenarios
- End-to-end implementation exercises
- Performance optimization tasks

### Troubleshooting Guide
- Common issues and solutions
- Advanced debugging techniques
- Performance optimization strategies

## 🔑 Prerequisites

### Required Accounts
- Create [Azure Free Account](https://go.microsoft.com/fwlink/?linkid=859151)
- GitHub account with [GitHub Copilot Free](https://code.visualstudio.com/docs/copilot/setup-simplified)
- Access to [Azure SRE Agent preview](https://microsoft.qualtrics.com/jfe/form/SV_cw3LUvdoaJ0SdcW)
- Download [VS Code](https://visualstudio.microsoft.com/downloads/)

### Technical Requirements
- Development environment: VS Code, Azure CLI, Git
- Basic understanding of cloud services
- Familiarity with Azure fundamentals

##  Getting Started

###  Quick Start (Recommended)
**Want to start learning immediately?** Use our complete automation:

```bash
# 1. Fork and Clone this Repository
git clone https://github.com/YourUsername/Agentic-Ops-Dev.git
cd Agentic-Ops-Dev

# 2. Deploy Everything Automatically (10-15 minutes)
cd resources
./quick-start.sh deploy YOUR_AZURE_SUBSCRIPTION_ID

# 3. Start Learning with Full Environment
./quick-start.sh start
```

### 📚 Manual Learning Path
For step-by-step understanding:

1. **Register for Workshop Access**
   - Visit [https://agentic-ops.dev](https://agentic-ops.dev) to register
   - Complete the Azure SRE Agent preview registration

2. **Follow the Workshop Structure**
   - Start with [Introduction to Observability](./docs/observability_introduction.md)
   - Progress through the modules based on your experience level
   - Use the [Troubleshooting Guide](./docs/observability_troubleshooting_guide.md) if needed

3. **Leverage Automation Resources**
   - All scripts, templates, and automation tools are in `/resources/`
   - Use individual components: `./resources/scripts/deploy-infrastructure.sh`
   - Access pre-built applications: `./resources/applications/`
   - Deploy with Terraform: `./resources/terraform/`

##  Key Features

- **🤖 Complete Automation**: One-command deployment with `/resources/quick-start.sh`
- **🏗️ Infrastructure as Code**: Production-ready Terraform configurations in `/resources/terraform/`
- ** Ready-to-Use Applications**: Sample apps with full telemetry in `/resources/applications/`
- ** Pre-Built Dashboards**: Grafana dashboards automatically deployed from `/resources/kubernetes/`
- ** Helper Scripts**: Port-forwarding, load generation, and utilities in `/resources/scripts/helpers/`
- **AI-Enhanced Monitoring**: Learn to implement Azure SRE Agent for intelligent observability
- **Multi-Cloud Coverage**: Build unified monitoring across Azure, AWS, and GCP
- **Real-World Scenarios**: Practice with authentic production-like challenges
- **Progressive Learning**: Start from basics and advance to enterprise-scale solutions
- **GitHub Copilot Integration**: Use AI to write monitoring queries and troubleshoot issues

## 🔗 Related Repositories

### [Design-to-Code](https://github.com/paulasilvatech/Design-to-Code-Dev)
A comprehensive guide for transforming Figma designs into production-ready code. This playbook provides a structured approach to converting design assets into high-quality, accessible, and maintainable code with practical workflows, code examples, and hands-on exercises using modern tools like VS Code, GitHub Copilot, and Azure AI.

### [AI Code Development](https://github.com/paulasilvatech/Code-AI-Dev)
A complete guide for leveraging AI tools like GitHub Copilot to optimize and improve code quality in enterprise environments. This repository covers advanced AI-assisted workflows, refactoring techniques, code optimization strategies, and best practices for integrating AI tools into your development process.

### [Agentic Operations & Observability](https://github.com/paulasilvatech/Agentic-Ops-Dev)
A hands-on workshop for implementing comprehensive observability solutions for cloud applications using Azure Monitor, Application Insights, and AI-powered tools like Azure SRE Agent. This repository guides you through the journey from traditional monitoring to AI-enhanced observability, covering the three pillars (metrics, logs, traces), multi-cloud integration, and agentic DevOps practices.

## 👤 Credits

This Azure AI Ops Observability Workshop was developed by [Paula Silva](https://github.com/paulanunes85), Developer Productivity [Global Black Belt at Microsoft Americas](https://www.linkedin.com/in/paulanunes/). The workshop provides a comprehensive approach to implementing AI-enhanced observability solutions for modern cloud applications.
