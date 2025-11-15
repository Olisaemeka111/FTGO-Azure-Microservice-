# Variables for Azure AKS on Azure Stack HCI Architecture

# General Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-gentic-app"
}

variable "location" {
  description = "Azure region location"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "Gentic-App"
  }
}

# Azure Kubernetes Service Configuration
variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on for AKS clusters"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring (optional, will create if not provided)"
  type        = string
  default     = ""
}

variable "enable_keyvault_secrets_provider" {
  description = "Enable Azure Key Vault secrets provider"
  type        = bool
  default     = false
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.96.0.0/16"
}

# Networking Configuration
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "vnet-gentic-app"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "management_subnet_cidr" {
  description = "CIDR block for management subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "workload_subnet_cidr" {
  description = "CIDR block for workload subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# Kubernetes Configuration
variable "use_latest_kubernetes_version" {
  description = "Use the latest available Kubernetes version (recommended)"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version for the clusters (used if use_latest_kubernetes_version is false)"
  type        = string
  default     = "1.29.0"
}

# Management Cluster Configuration
variable "management_cluster_name" {
  description = "Name of the management cluster"
  type        = string
  default     = "gentic-app-management"
}

variable "management_control_plane_count" {
  description = "Number of control plane nodes for management cluster"
  type        = number
  default     = 1
}

variable "management_node_count" {
  description = "Number of worker nodes for management cluster"
  type        = number
  default     = 1
}

variable "management_node_vm_size" {
  description = "VM size for management cluster nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

# Workload Cluster Configuration
variable "workload_cluster_name" {
  description = "Name of the workload cluster"
  type        = string
  default     = "gentic-app-workload"
}

variable "workload_control_plane_count" {
  description = "Number of control plane nodes for workload cluster"
  type        = number
  default     = 3
}

variable "enable_control_plane_ha" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = true
}

# Linux Node Pools
variable "linux_node_pools" {
  description = "Configuration for Linux node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = [
    {
      name       = "linuxpool1"
      node_count = 2
      vm_size    = "Standard_D4s_v3"
      os_type    = "Linux"
    },
    {
      name       = "linuxpool2"
      node_count = 2
      vm_size    = "Standard_D4s_v3"
      os_type    = "Linux"
    }
  ]
}

# Windows Node Pools
variable "windows_node_pools" {
  description = "Configuration for Windows node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = [
    {
      name       = "winpool1"
      node_count = 2
      vm_size    = "Standard_D4s_v3"
      os_type    = "Windows"
    }
  ]
}

# Load Balancer Configuration
variable "load_balancer_sku" {
  description = "SKU for load balancer"
  type        = string
  default     = "Standard"
}

variable "api_server_sku" {
  description = "SKU for API server"
  type        = string
  default     = "Standard"
}

# Storage Configuration
variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "stgenticapp"
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "storage_container_names" {
  description = "List of storage container names"
  type        = list(string)
  default     = ["cluster-data", "backups", "logs"]
}

# Azure Arc Configuration
variable "enable_azure_arc" {
  description = "Enable Azure Arc integration"
  type        = bool
  default     = true
}

variable "enable_windows_admin_center" {
  description = "Enable Windows Admin Center integration"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Azure Defender for Kubernetes"
  type        = bool
  default     = false
}

variable "enable_gitops" {
  description = "Enable GitOps with Flux"
  type        = bool
  default     = false
}

# Auto Scaling Configuration
variable "enable_metrics_server" {
  description = "Enable Metrics Server for HPA (Horizontal Pod Autoscaler)"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler for automatic node scaling"
  type        = bool
  default     = true
}

variable "enable_node_pool_autoscaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
  default     = true
}

variable "autoscaler_expander" {
  description = "Type of node group expander (random, most-pods, least-waste, priority)"
  type        = string
  default     = "least-waste"
}

variable "scale_down_enabled" {
  description = "Enable scale down for cluster autoscaler"
  type        = bool
  default     = true
}

variable "scale_down_delay_after_add" {
  description = "How long after scale up that scale down evaluation resumes"
  type        = string
  default     = "10m"
}

variable "scale_down_unneeded_time" {
  description = "How long a node should be unneeded before scale down"
  type        = string
  default     = "10m"
}

variable "scale_down_utilization_threshold" {
  description = "Node utilization threshold for scale down (0.0-1.0)"
  type        = number
  default     = 0.5
}

variable "linux_node_pool_min_count" {
  description = "Minimum number of nodes per Linux pool"
  type        = number
  default     = 1
}

variable "linux_node_pool_max_count" {
  description = "Maximum number of nodes per Linux pool"
  type        = number
  default     = 10
}

variable "windows_node_pool_min_count" {
  description = "Minimum number of nodes per Windows pool"
  type        = number
  default     = 1
}

variable "windows_node_pool_max_count" {
  description = "Maximum number of nodes per Windows pool"
  type        = number
  default     = 10
}

variable "enable_keda" {
  description = "Enable KEDA (Kubernetes Event-Driven Autoscaling)"
  type        = bool
  default     = false
}

