# Azure Arc Module - For Standard AKS
# Note: Standard AKS clusters are natively managed by Azure
# Azure Arc is optional and mainly used for connecting external clusters
# This module provides optional Arc extensions for enhanced management

# Azure Monitor for Containers
# NOTE: Monitoring is already enabled via oms_agent in the cluster configuration
# The separate extension requires additional RBAC permissions and is redundant
# For standard AKS, oms_agent provides all necessary monitoring capabilities
# Removed azurerm_kubernetes_cluster_extension for monitoring to avoid permission errors

# Azure Policy is enabled via azure_policy_enabled in cluster config
# No separate extension needed for standard AKS clusters
# Microsoft.PolicyInsights extension is not supported for standard AKS

# Azure Defender for Kubernetes - Management Cluster
resource "azurerm_kubernetes_cluster_extension" "arc_management_defender" {
  count              = var.arc_enabled && var.enable_defender ? 1 : 0
  name               = "microsoft-defender-mgmt"
  cluster_id         = var.management_cluster_id
  extension_type     = "microsoft.azuredefender.kubernetes"
  release_train      = "Stable"

  depends_on = []
}

# Azure Defender for Kubernetes - Workload Cluster
resource "azurerm_kubernetes_cluster_extension" "arc_workload_defender" {
  count              = var.arc_enabled && var.enable_defender ? 1 : 0
  name               = "microsoft-defender-workload"
  cluster_id         = var.workload_cluster_id
  extension_type     = "microsoft.azuredefender.kubernetes"
  release_train      = "Stable"

  depends_on = []
}

# GitOps with Flux - Management Cluster
resource "azurerm_kubernetes_cluster_extension" "arc_management_gitops" {
  count              = var.arc_enabled && var.enable_gitops ? 1 : 0
  name               = "flux-mgmt"
  cluster_id         = var.management_cluster_id
  extension_type     = "microsoft.flux"
  release_train      = "Stable"

  depends_on = []
}

# GitOps with Flux - Workload Cluster
resource "azurerm_kubernetes_cluster_extension" "arc_workload_gitops" {
  count              = var.arc_enabled && var.enable_gitops ? 1 : 0
  name               = "flux-workload"
  cluster_id         = var.workload_cluster_id
  extension_type     = "microsoft.flux"
  release_train      = "Stable"

  depends_on = []
}
