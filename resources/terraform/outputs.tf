# Azure Observability Workshop - Terraform Outputs
# This file consolidates all important output values from the infrastructure deployment

# Basic resource information
output "subscription_id" {
  description = "Azure Subscription ID used for deployment"
  value       = var.subscription_id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = var.location
}

# Resource Group
output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

# Monitoring Resources
output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_key" {
  description = "Log Analytics Workspace primary key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "application_insights_name" {
  description = "Application Insights name"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Container Registry
output "container_registry_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Azure Container Registry admin username"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Azure Container Registry admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# AKS Cluster
output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

# Security Resources
output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

# Network Resources
output "virtual_network_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = azurerm_subnet.aks.id
}

# Storage
output "storage_account_name" {
  description = "Storage account name for diagnostics"
  value       = azurerm_storage_account.diagnostics.name
}

output "storage_account_key" {
  description = "Storage account primary key"
  value       = azurerm_storage_account.diagnostics.primary_access_key
  sensitive   = true
}

# Consolidated connection information for workshop scripts
output "workshop_connection_details" {
  description = "Consolidated connection details for workshop automation"
  value = {
    subscription_id    = var.subscription_id
    resource_group     = azurerm_resource_group.main.name
    location          = var.location
    aks_cluster       = azurerm_kubernetes_cluster.main.name
    acr_name          = azurerm_container_registry.main.name
    acr_login_server  = azurerm_container_registry.main.login_server
    law_workspace_id  = azurerm_log_analytics_workspace.main.id
    app_insights_name = azurerm_application_insights.main.name
    key_vault_name    = azurerm_key_vault.main.name
  }
  sensitive = false
}