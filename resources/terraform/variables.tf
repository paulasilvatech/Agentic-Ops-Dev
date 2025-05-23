# Variables for Azure Observability Workshop

variable "subscription_id" {
  description = "Azure Subscription ID - REQUIRED: Provide your Azure subscription ID"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid GUID format."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US 2"
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Central US", "Canada Central", "Canada East",
      "North Europe", "West Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Switzerland North",
      "Norway East", "Sweden Central", "Australia East",
      "Australia Southeast", "East Asia", "Southeast Asia",
      "Japan East", "Japan West", "Korea Central", "Korea South",
      "Central India", "South India", "West India"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod, workshop)"
  type        = string
  default     = "workshop"
  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.environment))
    error_message = "Environment must be 2-10 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "admin_username" {
  description = "Admin username for resources"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for resources"
  type        = string
  default     = "ObservabilityWorkshop@2024!"
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28.0"
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 3
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "enable_monitoring" {
  description = "Enable monitoring addons"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable security features (Defender, policies)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 90
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}