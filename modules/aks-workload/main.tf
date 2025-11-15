# AKS Workload Cluster Module - Standard Azure AKS

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

# Standard AKS Workload Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Default node pool (system pool)
  # Note: Using smaller VM size to match node pool configuration and stay within quota
  default_node_pool {
    name                = "systempool"
    node_count          = 1
    vm_size             = "Standard_D2s_v3"  # Matches node pool VM sizes
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
    vnet_subnet_id      = var.subnet_id
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    zones               = var.control_plane_ha ? ["3"] : []  # eastus only supports zone 3
  }

  # Note: SSH keys for Linux nodes are configured via node pool ssh_key settings

  # Network profile
  # Note: With Azure CNI, pod_cidr is managed automatically
  # pod_cidr is only used with kubenet or Azure CNI in overlay mode
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = lower(var.load_balancer_sku)
    service_cidr      = var.service_cidr
    dns_service_ip    = cidrhost(var.service_cidr, 10)
  }

  identity {
    type = "SystemAssigned"
  }

  # RBAC Configuration
  role_based_access_control_enabled = true

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

# Additional Linux node pools
resource "azurerm_kubernetes_cluster_node_pool" "linux" {
  for_each = {
    for pool in var.linux_node_pools : pool.name => pool
  }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = var.enable_node_pool_autoscaling ? null : each.value.node_count
  vm_size               = each.value.vm_size
  os_type               = "Linux"
  os_disk_size_gb       = 128
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.subnet_id
  enable_auto_scaling   = var.enable_node_pool_autoscaling
  min_count             = var.enable_node_pool_autoscaling ? var.linux_node_pool_min_count : null
  max_count             = var.enable_node_pool_autoscaling ? var.linux_node_pool_max_count : null
  zones                 = var.control_plane_ha ? ["3"] : []  # eastus only supports zone 3

  tags = var.tags

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

# Windows node pools
resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  for_each = {
    for pool in var.windows_node_pools : pool.name => pool
  }

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = var.enable_node_pool_autoscaling ? null : each.value.node_count
  vm_size               = each.value.vm_size
  os_type               = "Windows"
  os_disk_size_gb       = 128
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.subnet_id
  enable_auto_scaling   = var.enable_node_pool_autoscaling
  min_count             = var.enable_node_pool_autoscaling ? var.windows_node_pool_min_count : null
  max_count             = var.enable_node_pool_autoscaling ? var.windows_node_pool_max_count : null
  zones                 = var.control_plane_ha ? ["3"] : []  # eastus only supports zone 3

  tags = var.tags

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}

# Azure Policy is enabled via azure_policy_enabled in cluster config above
# No separate extension needed for standard AKS clusters

# Azure Key Vault Secrets Provider (if enabled)
resource "azurerm_kubernetes_cluster_extension" "keyvault_secrets_provider" {
  count          = var.enable_keyvault_secrets_provider ? 1 : 0
  name           = "akvsecretsprovider"
  cluster_id     = azurerm_kubernetes_cluster.main.id
  extension_type = "microsoft.azurekeyvaultsecretsprovider"
  release_train  = "Stable"

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}
