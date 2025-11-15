# 🚀 START HERE - Deployment Instructions

## Current Status

✅ **Terraform module**: Complete and ready
✅ **terraform.tfvars**: Created (needs your values)
⏳ **Terraform init**: Needs to run
⏳ **Configuration**: Needs your Azure details

---

## 🎯 3 Simple Steps to Deploy

### Step 1: Edit terraform.tfvars (5 minutes)

Open `terraform.tfvars` and update these 3 lines with YOUR values:

```hcl
# Line 5 - Your Azure subscription ID
subscription_id = "YOUR-SUBSCRIPTION-ID-HERE"

# Line 12 - Your HCI cluster resource ID  
azure_stack_hci_cluster_id = "/subscriptions/.../clusters/YOUR-CLUSTER"

# Line 13 - Your AKS extension resource ID
aks_hci_extension_id = "/subscriptions/.../extensions/aks-hci-extension"
```

**How to get these values:**

```powershell
# 1. Login to Azure
az login

# 2. Get subscription ID
az account show --query id -o tsv

# 3. Get HCI cluster ID (replace YOUR_CLUSTER_NAME and YOUR_RG)
az stack-hci cluster show `
  --name "YOUR_CLUSTER_NAME" `
  --resource-group "YOUR_RG" `
  --query id -o tsv

# 4. Get extension ID
az k8s-extension show `
  --resource-group "YOUR_RG" `
  --cluster-name "YOUR_CLUSTER_NAME" `
  --cluster-type connectedClusters `
  --name "aks-hci-extension" `
  --query id -o tsv
```

---

### Step 2: Initialize Terraform (2 minutes)

```powershell
terraform init
```

**You should see:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.80"...
- Installing hashicorp/azurerm v3.XX.X...
- Installing Azure/azapi v1.XX.X...
Terraform has been successfully initialized!
```

**If you see errors:**
- Make sure Terraform is installed: `terraform version` (needs >= 1.5.0)
- Check internet connection
- Make sure Azure CLI is installed: `az --version`

---

### Step 3: Deploy (45 minutes)

```powershell
# First, review what will be created
terraform plan

# Then deploy (type 'yes' when prompted)
terraform apply
```

**This will create:**
- Resource group
- Virtual network
- Management cluster
- Workload cluster (6 nodes: 4 Linux + 2 Windows)
- Load balancers
- Storage account
- Azure Arc integration

**Takes 30-45 minutes** ⏱️

---

## ✅ After Deployment

```powershell
# Get cluster access
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml
$env:KUBECONFIG = ".\workload-kubeconfig.yaml"

# Verify nodes
kubectl get nodes

# Should show 6 nodes (4 Linux + 2 Windows)
```

---

## 🆘 Common Issues

### "terraform init" doesn't work
- Check Terraform version: `terraform version`
- Check internet connection
- Try: `terraform init -upgrade`

### "terraform plan" shows errors
- Check `terraform.tfvars` has all 3 required values
- Check resource IDs are correct
- Run: `terraform validate`

### "terraform apply" fails
- Check Azure login: `az account show`
- Check permissions (need Owner/Contributor)
- Check HCI cluster is running
- Check extension is installed

---

## 📚 More Help

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Full Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Troubleshooting**: [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)

---

## 🎯 Right Now, Do This:

1. **Open** `terraform.tfvars` in notepad
2. **Update** the 3 required values (subscription_id, cluster_id, extension_id)
3. **Save** the file
4. **Run** `terraform init`
5. **Run** `terraform plan` to review
6. **Run** `terraform apply` to deploy

**That's it! 🚀**

