# AKS Management Cluster Module - Standard Azure AKS

# Log Analytics Workspace (if monitoring is enabled)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_monitoring && var.log_analytics_workspace_id == "" ? 1 : 0
  name                = "${var.cluster_name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Standard AKS Management Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "systempool"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    vnet_subnet_id      = var.subnet_id
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    zones               = []
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = lower(var.load_balancer_sku)
    service_cidr      = "10.96.0.0/16"
    dns_service_ip    = "10.96.0.10"
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled = true

  # Azure Monitor for Containers
  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.main[0].id
    }
  }

  # Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  tags = var.tags
}

# Azure Policy is enabled via azure_policy_enabled in cluster config above
# No separate extension needed for standard AKS clusters
