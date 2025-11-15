# Main Terraform configuration for Azure Kubernetes Service (AKS) Architecture
# Cloud-native AKS deployment on Azure

# Provider configuration
# Note: required_providers are defined in versions.tf

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}

# Data source to get latest Kubernetes version
data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network for Management and Workload
module "networking" {
  source = "./modules/networking"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  vnet_name               = var.vnet_name
  vnet_address_space      = var.vnet_address_space
  management_subnet_cidr  = var.management_subnet_cidr
  workload_subnet_cidr    = var.workload_subnet_cidr
  tags                    = var.tags
}

# Management Cluster (Standard AKS)
module "management_cluster" {
  source = "./modules/aks-management"

  resource_group_name   = azurerm_resource_group.main.name
  resource_group_id     = azurerm_resource_group.main.id
  location              = azurerm_resource_group.main.location
  cluster_name          = var.management_cluster_name
  subnet_id             = module.networking.management_subnet_id
  kubernetes_version    = var.use_latest_kubernetes_version ? data.azurerm_kubernetes_service_versions.current.latest_version : var.kubernetes_version
  load_balancer_sku     = var.load_balancer_sku
  api_server_sku        = var.api_server_sku
  control_plane_count   = var.management_control_plane_count
  node_count            = var.management_node_count
  node_vm_size          = var.management_node_vm_size
  enable_azure_policy   = var.enable_azure_policy
  enable_monitoring     = var.enable_monitoring
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                  = var.tags

  depends_on = [
    module.networking
  ]
}

# Workload Cluster (AKS)
module "workload_cluster" {
  source = "./modules/aks-workload"

  resource_group_name   = azurerm_resource_group.main.name
  resource_group_id     = azurerm_resource_group.main.id
  location              = azurerm_resource_group.main.location
  cluster_name          = var.workload_cluster_name
  subnet_id             = module.networking.workload_subnet_id
  kubernetes_version    = var.use_latest_kubernetes_version ? data.azurerm_kubernetes_service_versions.current.latest_version : var.kubernetes_version
  load_balancer_sku     = var.load_balancer_sku
  api_server_sku        = var.api_server_sku
  control_plane_count   = var.workload_control_plane_count
  control_plane_ha      = var.enable_control_plane_ha
  
  # Worker node pools
  linux_node_pools      = var.linux_node_pools
  windows_node_pools    = var.windows_node_pools
  
  enable_azure_policy   = var.enable_azure_policy
  enable_monitoring     = var.enable_monitoring
  enable_keyvault_secrets_provider = var.enable_keyvault_secrets_provider
  log_analytics_workspace_id = var.log_analytics_workspace_id
  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  enable_node_pool_autoscaling = var.enable_node_pool_autoscaling
  linux_node_pool_min_count = var.linux_node_pool_min_count
  linux_node_pool_max_count = var.linux_node_pool_max_count
  windows_node_pool_min_count = var.windows_node_pool_min_count
  windows_node_pool_max_count = var.windows_node_pool_max_count
  
  tags                  = var.tags

  depends_on = [
    module.management_cluster
  ]
}

# Storage Configuration
module "storage" {
  source = "./modules/storage"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  storage_account_name     = var.storage_account_name
  storage_account_tier     = var.storage_account_tier
  storage_account_replication = var.storage_account_replication
  storage_container_names  = var.storage_container_names
  tags                     = var.tags
}

# Azure Arc Integration
module "azure_arc" {
  source = "./modules/azure-arc"

  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  arc_enabled                   = var.enable_azure_arc
  management_cluster_id         = module.management_cluster.cluster_id
  workload_cluster_id           = module.workload_cluster.cluster_id
  enable_monitoring             = var.enable_monitoring
  enable_azure_policy           = var.enable_azure_policy
  enable_defender               = var.enable_defender
  enable_gitops                = var.enable_gitops
  log_analytics_workspace_id    = var.log_analytics_workspace_id
  windows_admin_center_enabled  = var.enable_windows_admin_center
  tags                          = var.tags

  depends_on = [
    module.management_cluster,
    module.workload_cluster
  ]
}

# Load Balancer for Management Cluster
module "management_load_balancer" {
  source = "./modules/load-balancer"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  load_balancer_name   = "${var.management_cluster_name}-lb"
  subnet_id            = module.networking.management_subnet_id
  sku                  = var.load_balancer_sku
  backend_pool_name    = "${var.management_cluster_name}-backend"
  tags                 = var.tags
}

# Load Balancer for Workload Cluster
module "workload_load_balancer" {
  source = "./modules/load-balancer"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  load_balancer_name   = "${var.workload_cluster_name}-lb"
  subnet_id            = module.networking.workload_subnet_id
  sku                  = var.load_balancer_sku
  backend_pool_name    = "${var.workload_cluster_name}-backend"
  tags                 = var.tags
}

# Auto Scaling Configuration for Workload Cluster
module "workload_autoscaling" {
  source = "./modules/autoscaling"

  cluster_id                    = module.workload_cluster.cluster_id
  linux_node_pools              = var.linux_node_pools
  windows_node_pools            = var.windows_node_pools
  
  # Metrics Server (Required for HPA)
  enable_metrics_server         = var.enable_metrics_server
  
  # Cluster Autoscaler
  enable_cluster_autoscaler     = var.enable_cluster_autoscaler
  autoscaler_expander           = var.autoscaler_expander
  scale_down_enabled            = var.scale_down_enabled
  scale_down_delay_after_add    = var.scale_down_delay_after_add
  scale_down_unneeded_time      = var.scale_down_unneeded_time
  scale_down_utilization_threshold = var.scale_down_utilization_threshold
  
  # Node Pool Autoscaling
  enable_node_pool_autoscaling  = var.enable_node_pool_autoscaling
  linux_node_pool_min_count     = var.linux_node_pool_min_count
  linux_node_pool_max_count     = var.linux_node_pool_max_count
  windows_node_pool_min_count   = var.windows_node_pool_min_count
  windows_node_pool_max_count   = var.windows_node_pool_max_count
  
  # KEDA (Event-Driven Autoscaling)
  enable_keda                   = var.enable_keda
  
  tags                          = var.tags

  depends_on = [
    module.workload_cluster
  ]
}

