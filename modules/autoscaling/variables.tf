# Auto Scaling Module Variables

variable "cluster_id" {
  description = "ID of the Kubernetes cluster"
  type        = string
}

variable "linux_node_pools" {
  description = "List of Linux node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = []
}

variable "windows_node_pools" {
  description = "List of Windows node pools"
  type = list(object({
    name       = string
    node_count = number
    vm_size    = string
    os_type    = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Metrics Server Configuration
variable "enable_metrics_server" {
  description = "Enable Metrics Server (required for HPA)"
  type        = bool
  default     = true
}

# Cluster Autoscaler Configuration
variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler for automatic node scaling"
  type        = bool
  default     = true
}

variable "autoscaler_expander" {
  description = "Type of node group expander to be used in scale up (random, most-pods, least-waste, priority)"
  type        = string
  default     = "least-waste"
  
  validation {
    condition     = contains(["random", "most-pods", "least-waste", "priority"], var.autoscaler_expander)
    error_message = "Autoscaler expander must be one of: random, most-pods, least-waste, priority."
  }
}

variable "scale_down_enabled" {
  description = "Should cluster autoscaler scale down nodes"
  type        = bool
  default     = true
}

variable "scale_down_delay_after_add" {
  description = "How long after scale up that scale down evaluation resumes"
  type        = string
  default     = "10m"
}

variable "scale_down_delay_after_delete" {
  description = "How long after node deletion that scale down evaluation resumes"
  type        = string
  default     = "10s"
}

variable "scale_down_delay_after_failure" {
  description = "How long after scale down failure that scale down evaluation resumes"
  type        = string
  default     = "3m"
}

variable "scale_down_unneeded_time" {
  description = "How long a node should be unneeded before it is eligible for scale down"
  type        = string
  default     = "10m"
}

variable "scale_down_utilization_threshold" {
  description = "Node utilization level below which a node can be considered for scale down"
  type        = number
  default     = 0.5
  
  validation {
    condition     = var.scale_down_utilization_threshold > 0 && var.scale_down_utilization_threshold <= 1
    error_message = "Scale down utilization threshold must be between 0 and 1."
  }
}

variable "max_node_provision_time" {
  description = "Maximum time the autoscaler waits for a node to be provisioned"
  type        = string
  default     = "15m"
}

variable "scan_interval" {
  description = "How often cluster is reevaluated for scale up or down"
  type        = string
  default     = "10s"
}

# Node Pool Autoscaling Configuration
variable "enable_node_pool_autoscaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
  default     = true
}

variable "linux_node_pool_min_count" {
  description = "Minimum number of nodes per Linux node pool"
  type        = number
  default     = 1
}

variable "linux_node_pool_max_count" {
  description = "Maximum number of nodes per Linux node pool"
  type        = number
  default     = 10
}

variable "windows_node_pool_min_count" {
  description = "Minimum number of nodes per Windows node pool"
  type        = number
  default     = 1
}

variable "windows_node_pool_max_count" {
  description = "Maximum number of nodes per Windows node pool"
  type        = number
  default     = 10
}

# KEDA Configuration
variable "enable_keda" {
  description = "Enable KEDA (Kubernetes Event-Driven Autoscaling)"
  type        = bool
  default     = false
}

variable "keda_replicas" {
  description = "Number of KEDA operator and metrics server replicas"
  type        = number
  default     = 2
}

# HPA Examples
variable "create_hpa_examples" {
  description = "Create example HPA configurations"
  type        = bool
  default     = false
}

