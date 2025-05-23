# Azure Kubernetes Service Configuration
# Enterprise-grade AKS cluster with monitoring and security

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.base_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aks-${local.base_name}"
  kubernetes_version  = "1.28.0"

  default_node_pool {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    vnet_subnet_id      = azurerm_subnet.aks.id
    min_count          = 1
    max_count          = 5
    
    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Service Principal or Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Network Configuration
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
    load_balancer_sku  = "standard"
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Azure Active Directory Integration
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = []
  }

  # Security
  role_based_access_control_enabled = true

  tags = local.tags
}

# Additional node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = "Standard_D8s_v3"
  node_count           = 2
  vnet_subnet_id       = azurerm_subnet.aks.id
  min_count           = 0
  max_count           = 10

  node_labels = {
    "workload-type" = "application"
  }

  node_taints = [
    "workload=application:NoSchedule"
  ]

  tags = local.tags
}

# Role assignment for ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key            = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key            = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}

# Namespace for monitoring stack
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "name" = "monitoring"
      "istio-injection" = "enabled"
    }
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}

# Namespace for applications
resource "kubernetes_namespace" "applications" {
  metadata {
    name = "applications"
    labels = {
      "name" = "applications"
      "istio-injection" = "enabled"
    }
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}

# Namespace for Istio system
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      "name" = "istio-system"
    }
  }
  depends_on = [azurerm_kubernetes_cluster.main]
}

# Output AKS cluster information
output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}