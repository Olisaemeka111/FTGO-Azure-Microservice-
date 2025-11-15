# AKS Workload Cluster Module Outputs

output "cluster_id" {
  description = "ID of the workload cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the workload cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "API endpoint of the workload cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kubeconfig" {
  description = "Kubeconfig for the workload cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "node_pools" {
  description = "Node pool information"
  value = {
    linux_pools   = var.linux_node_pools
    windows_pools = var.windows_node_pools
  }
}

output "cluster_resource_id" {
  description = "Full resource ID of the cluster"
  value       = azurerm_kubernetes_cluster.main.id
}
