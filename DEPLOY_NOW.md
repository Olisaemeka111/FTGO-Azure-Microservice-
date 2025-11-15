# 🚀 DEPLOY NOW - Quick Guide

## ⚠️ IMPORTANT: Before You Deploy

Your `terraform.tfvars` file needs **3 critical values** updated:

1. ✅ **subscription_id** - Already updated! (`657bf059-e3b7-401b-816d-367cac7b220a`)
2. ⏳ **azure_stack_hci_cluster_id** - **NEEDS YOUR VALUE**
3. ⏳ **aks_hci_extension_id** - **NEEDS YOUR VALUE**

---

## 📋 Option 1: Use the Deployment Script (Easiest)

```powershell
# Run the automated deployment script
.\deploy.ps1
```

This script will:
- ✅ Check all prerequisites
- ✅ Initialize Terraform
- ✅ Validate configuration
- ✅ Plan the deployment
- ✅ Ask for confirmation before deploying

---

## 📋 Option 2: Manual Deployment Steps

### Step 1: Update terraform.tfvars

**You need to get these 2 values:**

#### Get HCI Cluster ID:
```powershell
# First, install the stack-hci extension (if needed)
az extension add --name stack-hci

# List your HCI clusters
az stack-hci cluster list --query "[].{Name:name, ResourceGroup:resourceGroup, Id:id}" -o table

# Get specific cluster ID (replace YOUR_CLUSTER_NAME and YOUR_RG)
az stack-hci cluster show `
  --name "YOUR_CLUSTER_NAME" `
  --resource-group "YOUR_RG" `
  --query id -o tsv
```

#### Get AKS Extension ID:
```powershell
# Get extension ID (replace YOUR_CLUSTER_NAME and YOUR_RG)
az k8s-extension show `
  --resource-group "YOUR_RG" `
  --cluster-name "YOUR_CLUSTER_NAME" `
  --cluster-type connectedClusters `
  --name "aks-hci-extension" `
  --query id -o tsv
```

**Then update terraform.tfvars:**
- Line 12: `azure_stack_hci_cluster_id = "PASTE-YOUR-CLUSTER-ID-HERE"`
- Line 13: `aks_hci_extension_id = "PASTE-YOUR-EXTENSION-ID-HERE"`

---

### Step 2: Initialize Terraform

```powershell
terraform init
```

**Expected output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.80"...
- Installing hashicorp/azurerm v3.XX.X...
- Installing Azure/azapi v1.XX.X...
Terraform has been successfully initialized!
```

---

### Step 3: Validate Configuration

```powershell
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

---

### Step 4: Plan Deployment

```powershell
terraform plan -out=tfplan
```

**This shows what will be created:**
- Resource group
- Virtual network and subnets
- Management cluster
- Workload cluster (6 nodes)
- Load balancers
- Storage account
- Azure Arc extensions

**Review carefully!** Should show ~20-25 resources.

---

### Step 5: Deploy!

```powershell
terraform apply tfplan
```

**Type `yes` when prompted.**

**⏱️ This takes 30-45 minutes**

---

## ✅ After Deployment

```powershell
# Get cluster access
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml
$env:KUBECONFIG = ".\workload-kubeconfig.yaml"

# Verify nodes (should show 6 nodes: 4 Linux + 2 Windows)
kubectl get nodes

# Check cluster info
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces
```

---

## 🆘 Troubleshooting

### "terraform init" fails
- Check internet connection
- Check Terraform version: `terraform version` (needs >= 1.5.0)
- Try: `terraform init -upgrade`

### "terraform plan" shows errors about missing values
- Check `terraform.tfvars` has all 3 required values
- Make sure resource IDs are correct format
- Run: `terraform validate` to see specific errors

### "terraform apply" fails with "subscription not found"
- Check subscription ID is correct
- Verify: `az account show`
- Make sure you have permissions

### "HCI cluster not found"
- Check `azure_stack_hci_cluster_id` is correct
- Verify cluster exists: `az stack-hci cluster list`
- Make sure cluster is registered with Azure

### "Extension not found"
- Check `aks_hci_extension_id` is correct
- Install extension if missing:
  ```powershell
  az k8s-extension create `
    --resource-group "YOUR_RG" `
    --cluster-name "YOUR_CLUSTER_NAME" `
    --cluster-type connectedClusters `
    --extension-type Microsoft.AKSHybrid `
    --name "aks-hci-extension"
  ```

---

## 📊 Current Status

- ✅ Terraform module: Ready
- ✅ Subscription ID: Updated
- ⏳ HCI Cluster ID: **NEEDS YOUR VALUE**
- ⏳ Extension ID: **NEEDS YOUR VALUE**
- ⏳ Ready to deploy: **After updating the 2 IDs above**

---

## 🎯 Quick Commands

```powershell
# Check what you need
az account show                    # Your subscription
az stack-hci cluster list          # Your HCI clusters
az k8s-extension list              # Your extensions

# Deploy
terraform init                     # Initialize
terraform plan                     # Review
terraform apply                    # Deploy

# After deployment
terraform output                   # See all outputs
kubectl get nodes                  # Verify nodes
```

---

## 📚 More Help

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Full Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Troubleshooting**: [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)

---

**🚀 Ready? Update those 2 IDs in terraform.tfvars, then run `.\deploy.ps1` or follow the manual steps above!**

