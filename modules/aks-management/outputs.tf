output "cluster_id" {
  description = "ID of the management cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the management cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "FQDN of the management cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kubeconfig" {
  description = "Kubeconfig for the management cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "cluster_principal_id" {
  description = "Principal ID of the cluster identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
