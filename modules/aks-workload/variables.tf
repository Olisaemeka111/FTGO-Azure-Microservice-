# AKS Workload Cluster Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "cluster_name" {
  description = "Name of the workload cluster"
  type        = string
}

variable "enable_node_pool_autoscaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
  default     = false
}

variable "linux_node_pool_min_count" {
  description = "Minimum node count for Linux pools"
  type        = number
  default     = 1
}

variable "linux_node_pool_max_count" {
  description = "Maximum node count for Linux pools"
  type        = number
  default     = 10
}

variable "windows_node_pool_min_count" {
  description = "Minimum node count for Windows pools"
  type        = number
  default     = 1
}

variable "windows_node_pool_max_count" {
  description = "Maximum node count for Windows pools"
  type        = number
  default     = 8
}

variable "ssh_public_key" {
  description = "SSH public key for Linux nodes"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

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

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "control_plane_vm_size" {
  description = "VM size for control plane nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "control_plane_ha" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = true
}

variable "linux_node_pools" {
  description = "Configuration for Linux node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = []
}

variable "windows_node_pools" {
  description = "Configuration for Windows node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = []
}

variable "pod_cidr" {
  description = "CIDR range for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy extension"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = ""
}

variable "enable_keyvault_secrets_provider" {
  description = "Enable Azure Key Vault secrets provider"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

