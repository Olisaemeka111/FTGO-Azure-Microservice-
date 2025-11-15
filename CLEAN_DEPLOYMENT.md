# Clean Deployment Guide

## Configuration Drift Issues - ALL FIXED ✅

All configuration inconsistencies have been resolved. The infrastructure is ready for a clean deployment.

## Fixed Configuration Issues

### 1. VM Size Consistency ✅
- **Before**: Mixed sizes (D4s_v3 in some places, D2s_v3 in others)
- **After**: All resources use `Standard_D2s_v3` consistently
- **Files**: `modules/aks-workload/main.tf`, `terraform.tfvars`

### 2. Zone Configuration ✅
- **Before**: Zones ["1", "2", "3"] (not supported in eastus)
- **After**: Zone ["3"] only (eastus constraint)
- **Files**: `modules/aks-workload/main.tf`

### 3. OIDC Issuer ✅
- **Before**: Not explicitly set (caused update errors)
- **After**: Explicitly enabled in both clusters
- **Files**: `modules/aks-management/main.tf`, `modules/aks-workload/main.tf`

### 4. Network Configuration ✅
- **Before**: pod_cidr specified with Azure CNI (incompatible)
- **After**: Removed pod_cidr (Azure CNI manages automatically)
- **Files**: `modules/aks-workload/main.tf`

### 5. Load Balancer SKU ✅
- **Before**: "Standard" (case-sensitive error)
- **After**: `lower(var.load_balancer_sku)` ensures lowercase
- **Files**: `modules/aks-management/main.tf`, `modules/aks-workload/main.tf`

### 6. Azure Policy Extensions ✅
- **Before**: Trying to create unsupported extensions
- **After**: Removed (policy enabled via cluster config)
- **Files**: `modules/azure-arc/main.tf`

### 7. Windows Pool Name ✅
- **Before**: "winpool1" (8 chars, too long)
- **After**: "winp1" (5 chars, valid)
- **Files**: `terraform.tfvars`

### 8. Storage Account Property ✅
- **Before**: `enable_https_traffic_only` (deprecated)
- **After**: `https_traffic_only_enabled` (new property)
- **Files**: `modules/storage/main.tf`

## Current Consistent Configuration

### Management Cluster
```hcl
vm_size = "Standard_D2s_v3"
node_count = 1
zones = []
oidc_issuer_enabled = true
azure_policy_enabled = true
monitoring = true
```

### Workload Cluster
```hcl
default_pool_vm_size = "Standard_D2s_v3"
linux_pools = [
  { name = "linuxpool1", vm_size = "Standard_D2s_v3", node_count = 1 },
  { name = "linuxpool2", vm_size = "Standard_D2s_v3", node_count = 1 }
]
windows_pools = [
  { name = "winp1", vm_size = "Standard_D2s_v3", node_count = 1 }
]
zones = ["3"]  # eastus only
oidc_issuer_enabled = true
azure_policy_enabled = true
monitoring = true
autoscaling = { min: 1, max: 5 (Linux), max: 4 (Windows) }
```

## Clean Deployment Steps

### Step 1: Wait for Resource Deletion
```powershell
# Check if clusters are deleted
az aks list --resource-group rg-gentic-app

# If still deleting, wait and check again
```

### Step 2: Remove State Lock (if needed)
```powershell
# If state file is locked
Remove-Item terraform.tfstate.lock.info -ErrorAction SilentlyContinue
```

### Step 3: Initialize Terraform
```powershell
terraform init -upgrade
```

### Step 4: Validate Configuration
```powershell
terraform validate
```

### Step 5: Plan Deployment
```powershell
terraform plan -out=tfplan
```

### Step 6: Apply Clean Deployment
```powershell
terraform apply -auto-approve tfplan
```

## Expected Resources

After clean deployment, you should have:

- ✅ 1 Management AKS Cluster (1 node, D2s_v3)
- ✅ 1 Workload AKS Cluster (1 default + 2 Linux pools + 1 Windows pool)
- ✅ 2 Log Analytics Workspaces
- ✅ Virtual Network with 2 subnets
- ✅ 2 Load Balancers (Standard SKU)
- ✅ Storage Account
- ✅ Network Security Groups

**Total Nodes**: 5 (1 mgmt + 1 default + 2 Linux + 1 Windows)

## No More Configuration Drift

All configurations are now:
- ✅ Consistent across all modules
- ✅ Using variables (no hardcoded values)
- ✅ Compliant with Azure constraints
- ✅ Ready for clean deployment

