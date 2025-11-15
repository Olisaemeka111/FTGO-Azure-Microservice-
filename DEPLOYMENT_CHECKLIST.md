# ✅ Deployment Checklist

## Current Status

- ✅ Terraform module created
- ✅ Documentation complete
- ✅ `terraform.tfvars` created (needs your values)
- ⏳ Terraform initialization (in progress)
- ⏳ Configuration (needs your Azure details)
- ⏳ Deployment (ready to start)

---

## Step-by-Step Deployment

### ✅ Step 1: Configure terraform.tfvars

**File created**: `terraform.tfvars` (from example)

**You need to edit it with YOUR values:**

```bash
# Open in notepad
notepad terraform.tfvars
```

**Required changes:**

1. **Line 5**: `subscription_id = "YOUR-SUBSCRIPTION-ID"`
   ```bash
   # Get it with:
   az account show --query id -o tsv
   ```

2. **Line 12**: `azure_stack_hci_cluster_id = "YOUR-HCI-CLUSTER-ID"`
   ```bash
   # Get it with:
   az stack-hci cluster show \
     --name "YOUR_CLUSTER_NAME" \
     --resource-group "YOUR_RG" \
     --query id -o tsv
   ```

3. **Line 13**: `aks_hci_extension_id = "YOUR-EXTENSION-ID"`
   ```bash
   # Get it with:
   az k8s-extension show \
     --resource-group "YOUR_RG" \
     --cluster-name "YOUR_CLUSTER_NAME" \
     --cluster-type connectedClusters \
     --name "aks-hci-extension" \
     --query id -o tsv
   ```

**Optional changes:**
- Resource group name (line 8)
- Location (line 9)
- Cluster names
- Node counts (for testing, use smaller numbers)

---

### ⏳ Step 2: Initialize Terraform

```bash
terraform init
```

**Expected output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.80"...
- Finding Azure/azapi versions matching "~> 1.10"...
- Installing hashicorp/azurerm v3.XX.X...
- Installing Azure/azapi v1.XX.X...
Terraform has been successfully initialized!
```

**If you see errors:**
- Check Terraform version: `terraform version` (needs >= 1.5.0)
- Check internet connection
- Check Azure CLI: `az login`

---

### ⏳ Step 3: Validate Configuration

```bash
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

**If you see errors:**
- Check `terraform.tfvars` syntax
- Check all required variables are set
- Check variable types match

---

### ⏳ Step 4: Review Plan

```bash
terraform plan
```

**This shows what will be created:**
- Resource group
- Virtual network and subnets
- Management cluster
- Workload cluster
- Load balancers
- Storage account
- Azure Arc extensions

**Review carefully!** Make sure it matches what you want.

**Expected output:**
```
Plan: 20 to add, 0 to change, 0 to destroy.
```

---

### ⏳ Step 5: Deploy Infrastructure

```bash
terraform apply
```

**Type `yes` when prompted.**

**This takes 30-45 minutes.** ⏱️

**What happens:**
1. Resource group created (1 min)
2. Virtual network created (2 min)
3. Management cluster deployed (10-15 min)
4. Workload cluster deployed (15-20 min)
5. Load balancers configured (5 min)
6. Storage account created (2 min)
7. Azure Arc extensions installed (5-10 min)

**Watch for errors!** If something fails, check the error message.

---

### ⏳ Step 6: Verify Deployment

```bash
# Get deployment summary
terraform output deployment_summary

# Get workload cluster kubeconfig
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml

# Set kubeconfig
$env:KUBECONFIG = ".\workload-kubeconfig.yaml"

# Verify nodes
kubectl get nodes
```

**Expected output:**
```
NAME                STATUS   ROLES    AGE   VERSION
linuxpool1-xxxxx    Ready    agent    10m   v1.28.3
linuxpool1-yyyyy    Ready    agent    10m   v1.28.3
linuxpool2-xxxxx    Ready    agent    10m   v1.28.3
linuxpool2-yyyyy    Ready    agent    10m   v1.28.3
winpool1-xxxxx      Ready    agent    10m   v1.28.3
winpool1-yyyyy      Ready    agent    10m   v1.28.3
```

**You should see 6 nodes (4 Linux + 2 Windows)**

---

## 🆘 Troubleshooting

### "terraform init" fails

**Check:**
- Terraform version: `terraform version` (needs >= 1.5.0)
- Internet connection
- Azure CLI logged in: `az account show`

**Fix:**
```bash
# Update Terraform if needed
# Or check provider versions in versions.tf
```

---

### "terraform plan" shows errors

**Common issues:**
- Missing required variables in `terraform.tfvars`
- Wrong variable types
- Invalid resource IDs

**Fix:**
- Check `terraform.tfvars` has all required values
- Verify resource IDs are correct
- Check variable types match

---

### "terraform apply" fails

**Common errors:**

1. **"Subscription not found"**
   - Check `subscription_id` in `terraform.tfvars`
   - Verify: `az account show`

2. **"Resource group not found"**
   - Terraform will create it, or create manually first

3. **"HCI cluster not found"**
   - Check `azure_stack_hci_cluster_id`
   - Verify cluster exists: `az stack-hci cluster list`

4. **"Extension not found"**
   - Check `aks_hci_extension_id`
   - Install extension if missing

**Fix:**
- Read the error message carefully
- Check the resource IDs
- Verify Azure permissions

---

### Can't connect to cluster

```bash
# Re-export kubeconfig
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml
$env:KUBECONFIG = ".\workload-kubeconfig.yaml"

# Or use Azure CLI proxy
az connectedk8s proxy \
  --name $(terraform output -raw workload_cluster_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

---

## 📋 Pre-Deployment Checklist

Before running `terraform apply`, verify:

- [ ] `terraform.tfvars` has your subscription ID
- [ ] `terraform.tfvars` has your HCI cluster ID
- [ ] `terraform.tfvars` has your extension ID
- [ ] Azure CLI is logged in: `az account show`
- [ ] You have Owner/Contributor permissions
- [ ] Azure Stack HCI cluster is running
- [ ] AKS extension is installed
- [ ] You have sufficient HCI capacity
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` shows expected resources

---

## 🎯 Quick Commands Reference

```bash
# Check Terraform version
terraform version

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Show outputs
terraform output

# Show specific output
terraform output workload_cluster_name

# Destroy (if needed)
terraform destroy
```

---

## 📚 Need Help?

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Full Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Troubleshooting**: [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting)
- **Architecture**: [README.md](README.md)

---

## ✅ Next Actions

1. **Edit `terraform.tfvars`** with your Azure values
2. **Run `terraform init`** (if not done)
3. **Run `terraform plan`** to review
4. **Run `terraform apply`** to deploy

**Good luck! 🚀**

