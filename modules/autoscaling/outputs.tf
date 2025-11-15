# Auto Scaling Module Outputs

output "autoscaling_info" {
  description = "Information about autoscaling configuration"
  value = {
    metrics_server_enabled     = var.enable_metrics_server
    cluster_autoscaler_enabled  = var.enable_cluster_autoscaler
    node_pool_autoscaling       = var.enable_node_pool_autoscaling
    linux_min_count             = var.linux_node_pool_min_count
    linux_max_count             = var.linux_node_pool_max_count
    windows_min_count           = var.windows_node_pool_min_count
    windows_max_count           = var.windows_node_pool_max_count
    note                        = "Autoscaling is configured via node pool settings in the AKS cluster"
  }
}
