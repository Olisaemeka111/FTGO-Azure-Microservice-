# Outputs for Azure AKS on Azure Stack HCI Architecture

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Note: Custom locations are not needed for standard AKS clusters
# AKS clusters are natively managed by Azure

# Networking Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = module.networking.management_subnet_id
}

output "workload_subnet_id" {
  description = "ID of the workload subnet"
  value       = module.networking.workload_subnet_id
}

# Management Cluster Outputs
output "management_cluster_id" {
  description = "ID of the management cluster"
  value       = module.management_cluster.cluster_id
}

output "management_cluster_name" {
  description = "Name of the management cluster"
  value       = module.management_cluster.cluster_name
}

output "management_cluster_endpoint" {
  description = "API endpoint of the management cluster"
  value       = module.management_cluster.cluster_fqdn
}

output "management_cluster_kubeconfig" {
  description = "Kubeconfig for the management cluster"
  value       = module.management_cluster.kubeconfig
  sensitive   = true
}

# Workload Cluster Outputs
output "workload_cluster_id" {
  description = "ID of the workload cluster"
  value       = module.workload_cluster.cluster_id
}

output "workload_cluster_name" {
  description = "Name of the workload cluster"
  value       = module.workload_cluster.cluster_name
}

output "workload_cluster_endpoint" {
  description = "API endpoint of the workload cluster"
  value       = module.workload_cluster.cluster_endpoint
}

output "workload_cluster_kubeconfig" {
  description = "Kubeconfig for the workload cluster"
  value       = module.workload_cluster.kubeconfig
  sensitive   = true
}

output "workload_cluster_node_pools" {
  description = "Node pool information for the workload cluster"
  value       = module.workload_cluster.node_pools
}

# Load Balancer Outputs
output "management_load_balancer_id" {
  description = "ID of the management load balancer"
  value       = module.management_load_balancer.load_balancer_id
}

output "management_load_balancer_ip" {
  description = "Frontend IP of the management load balancer"
  value       = module.management_load_balancer.frontend_ip_address
}

output "workload_load_balancer_id" {
  description = "ID of the workload load balancer"
  value       = module.workload_load_balancer.load_balancer_id
}

output "workload_load_balancer_ip" {
  description = "Frontend IP of the workload load balancer"
  value       = module.workload_load_balancer.frontend_ip_address
}

# Storage Outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.storage.primary_blob_endpoint
}

output "storage_containers" {
  description = "List of storage containers"
  value       = module.storage.container_names
}

# Azure Arc Outputs
output "arc_enabled" {
  description = "Whether Azure Arc is enabled"
  value       = var.enable_azure_arc
}

output "arc_management_cluster_connected" {
  description = "Azure Arc connection status for management cluster"
  value       = module.azure_arc.management_cluster_connected
}

output "arc_workload_cluster_connected" {
  description = "Azure Arc connection status for workload cluster"
  value       = module.azure_arc.workload_cluster_connected
}

# Auto Scaling Outputs
output "autoscaling_enabled" {
  description = "Whether autoscaling is enabled"
  value       = var.enable_cluster_autoscaler
}

output "autoscaling_configuration" {
  description = "Autoscaling configuration details"
  value       = module.workload_autoscaling.autoscaling_info
}

output "node_pool_scaling_limits" {
  description = "Node pool scaling limits"
  value = {
    linux_min   = var.linux_node_pool_min_count
    linux_max   = var.linux_node_pool_max_count
    windows_min = var.windows_node_pool_min_count
    windows_max = var.windows_node_pool_max_count
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    resource_group           = azurerm_resource_group.main.name
    location                 = azurerm_resource_group.main.location
    management_cluster       = module.management_cluster.cluster_name
    workload_cluster         = module.workload_cluster.cluster_name
    management_lb_ip         = module.management_load_balancer.frontend_ip_address
    workload_lb_ip           = module.workload_load_balancer.frontend_ip_address
    storage_account          = module.storage.storage_account_name
    arc_enabled              = var.enable_azure_arc
    windows_admin_center     = var.enable_windows_admin_center
    autoscaling_enabled      = var.enable_cluster_autoscaler
    metrics_server_enabled   = var.enable_metrics_server
  }
}

