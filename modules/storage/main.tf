# Storage Module

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  account_kind             = "StorageV2"
  
  https_traffic_only_enabled = true
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.storage_container_names)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Storage Account for Cluster Data
resource "azurerm_storage_share" "cluster_data" {
  name                 = "cluster-data"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100
}

# Storage Account for Backups
resource "azurerm_storage_share" "backups" {
  name                 = "backups"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 500
}

# Management Lock to prevent accidental deletion
resource "azurerm_management_lock" "storage" {
  count      = var.enable_delete_lock ? 1 : 0
  name       = "storage-lock"
  scope      = azurerm_storage_account.main.id
  lock_level = "CanNotDelete"
  notes      = "Locked to prevent accidental deletion"
}

