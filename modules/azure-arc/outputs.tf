# Azure Arc Module Outputs

output "management_cluster_connected" {
  description = "Whether management cluster is connected to Azure Arc"
  value       = var.arc_enabled
}

output "workload_cluster_connected" {
  description = "Whether workload cluster is connected to Azure Arc"
  value       = var.arc_enabled
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

output "policy_enabled" {
  description = "Whether Azure Policy is enabled"
  value       = var.enable_azure_policy
}

output "defender_enabled" {
  description = "Whether Azure Defender is enabled"
  value       = var.enable_defender
}

output "gitops_enabled" {
  description = "Whether GitOps is enabled"
  value       = var.enable_gitops
}

output "windows_admin_center_enabled" {
  description = "Whether Windows Admin Center is enabled"
  value       = var.windows_admin_center_enabled
}

