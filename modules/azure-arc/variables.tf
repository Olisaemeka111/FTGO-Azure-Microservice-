# Azure Arc Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "arc_enabled" {
  description = "Enable Azure Arc integration"
  type        = bool
  default     = true
}

variable "management_cluster_id" {
  description = "ID of the management cluster"
  type        = string
}

variable "workload_cluster_id" {
  description = "ID of the workload cluster"
  type        = string
}

variable "windows_admin_center_enabled" {
  description = "Enable Windows Admin Center integration"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for Kubernetes"
  type        = bool
  default     = false
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

