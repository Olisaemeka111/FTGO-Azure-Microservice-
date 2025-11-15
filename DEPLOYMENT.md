# Deployment Guide - Azure AKS on Azure Stack HCI

This guide walks you through deploying the complete Azure AKS infrastructure on Azure Stack HCI using this Terraform module.

## Prerequisites Checklist

Before beginning deployment, ensure you have:

- [ ] Azure subscription with Owner or Contributor access
- [ ] Azure Stack HCI cluster deployed and running
- [ ] AKS HCI extension installed on the Azure Stack HCI cluster
- [ ] Custom location created for the HCI cluster
- [ ] Terraform >= 1.5.0 installed on your machine
- [ ] Azure CLI installed and configured
- [ ] kubectl installed (for cluster access post-deployment)
- [ ] Sufficient Azure Stack HCI capacity:
  - Storage: ~500GB minimum
  - Memory: ~128GB minimum
  - CPUs: ~32 cores minimum

## Step-by-Step Deployment

### Step 1: Prepare Azure Stack HCI

#### 1.1 Register Azure Stack HCI Cluster

```bash
# Login to Azure
az login

# Register the HCI cluster
az stack-hci cluster register \
  --name "my-hci-cluster" \
  --resource-group "rg-stack-hci" \
  --location "eastus"
```

#### 1.2 Install AKS HCI Extension

```bash
# Install the AKS HCI extension
az k8s-extension create \
  --resource-group "rg-stack-hci" \
  --cluster-name "my-hci-cluster" \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AKSHybrid \
  --name "aks-hci-extension"
```

#### 1.3 Create Custom Location

```bash
# Get the HCI cluster resource ID
HCI_CLUSTER_ID=$(az stack-hci cluster show \
  --name "my-hci-cluster" \
  --resource-group "rg-stack-hci" \
  --query id -o tsv)

# Get the extension resource ID
EXTENSION_ID=$(az k8s-extension show \
  --resource-group "rg-stack-hci" \
  --cluster-name "my-hci-cluster" \
  --cluster-type connectedClusters \
  --name "aks-hci-extension" \
  --query id -o tsv)

# Create custom location
az customlocation create \
  --name "custom-location-aks-hci" \
  --resource-group "rg-stack-hci" \
  --location "eastus" \
  --host-resource-id $HCI_CLUSTER_ID \
  --namespace "default" \
  --cluster-extension-ids $EXTENSION_ID
```

### Step 2: Configure Terraform

#### 2.1 Copy Example Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

#### 2.2 Edit terraform.tfvars

Update the following values in `terraform.tfvars`:

```hcl
# Replace with your actual values
subscription_id = "YOUR-SUBSCRIPTION-ID"

# Get these values from Step 1
azure_stack_hci_cluster_id = "/subscriptions/YOUR-SUB-ID/resourceGroups/rg-stack-hci/providers/Microsoft.AzureStackHCI/clusters/my-hci-cluster"
aks_hci_extension_id = "/subscriptions/YOUR-SUB-ID/resourceGroups/rg-stack-hci/providers/Microsoft.KubernetesConfiguration/extensions/aks-hci-extension"

# Network configuration
vnet_address_space     = ["10.0.0.0/16"]
management_subnet_cidr = "10.0.1.0/24"
workload_subnet_cidr   = "10.0.2.0/24"

# Cluster configuration
management_cluster_name        = "aks-hci-management"
workload_cluster_name          = "aks-hci-workload"
kubernetes_version             = "1.28.3"
enable_control_plane_ha        = true

# Node pools - adjust based on your capacity
linux_node_pools = [
  {
    name       = "linuxpool1"
    node_count = 2
    vm_size    = "Standard_D4s_v3"
    os_type    = "Linux"
  }
]

windows_node_pools = [
  {
    name       = "winpool1"
    node_count = 2
    vm_size    = "Standard_D4s_v3"
    os_type    = "Windows"
  }
]

# Features
enable_azure_arc            = true
enable_windows_admin_center = true
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform and download providers
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
# Validate the Terraform configuration
terraform validate
```

### Step 5: Plan the Deployment

```bash
# Generate and review the execution plan
terraform plan -out=tfplan
```

Review the plan carefully. It should show:
- 1 Resource Group
- 1 Custom Location
- 1 Virtual Network with 2 Subnets
- 2 Network Security Groups
- 2 AKS Clusters (Management + Workload)
- 2 Load Balancers
- 1 Storage Account
- Azure Arc extensions (if enabled)

### Step 6: Deploy Infrastructure

```bash
# Apply the Terraform configuration
terraform apply tfplan
```

This will take approximately 30-45 minutes. Monitor the output for any errors.

### Step 7: Verify Deployment

#### 7.1 Check Terraform Outputs

```bash
# View all outputs
terraform output

# View specific outputs
terraform output management_cluster_endpoint
terraform output workload_cluster_endpoint
terraform output deployment_summary
```

#### 7.2 Verify in Azure Portal

1. Navigate to the resource group in Azure Portal
2. Verify all resources are created:
   - Connected Clusters (2)
   - Load Balancers (2)
   - Storage Account (1)
   - Virtual Network (1)

### Step 8: Access the Clusters

#### 8.1 Get Kubeconfig for Management Cluster

```bash
# Export management cluster kubeconfig
terraform output -raw management_cluster_kubeconfig > management-kubeconfig.yaml

# Or use Azure CLI
az connectedk8s proxy \
  --name aks-hci-management \
  --resource-group rg-aks-hci-prod
```

#### 8.2 Get Kubeconfig for Workload Cluster

```bash
# Export workload cluster kubeconfig
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml

# Or use Azure CLI
az connectedk8s proxy \
  --name aks-hci-workload \
  --resource-group rg-aks-hci-prod
```

#### 8.3 Verify Cluster Access

```bash
# Set kubeconfig
export KUBECONFIG=./workload-kubeconfig.yaml

# Check nodes
kubectl get nodes

# Expected output:
# NAME                           STATUS   ROLES    AGE   VERSION
# linuxpool1-xxxxx               Ready    agent    10m   v1.28.3
# linuxpool1-yyyyy               Ready    agent    10m   v1.28.3
# winpool1-xxxxx                 Ready    agent    10m   v1.28.3
# winpool1-yyyyy                 Ready    agent    10m   v1.28.3

# Check pods
kubectl get pods --all-namespaces
```

### Step 9: Deploy Sample Application

#### 9.1 Deploy a Linux Application

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx:latest

# Expose as a service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check the service
kubectl get service nginx
```

#### 9.2 Deploy a Windows Application

```bash
# Create a Windows deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis
spec:
  replicas: 2
  selector:
    matchLabels:
      app: iis
  template:
    metadata:
      labels:
        app: iis
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      containers:
      - name: iis
        image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: iis
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: iis
EOF
```

### Step 10: Configure Windows Admin Center (Optional)

If you enabled Windows Admin Center:

1. Open Windows Admin Center
2. Click "Add" > "Azure Kubernetes Service"
3. Select your clusters from the list
4. Connect and manage through the GUI

### Step 11: Configure Azure Arc Features (Optional)

#### Enable Azure Monitor

```bash
# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group rg-aks-hci-prod \
  --workspace-name la-aks-hci

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-aks-hci-prod \
  --workspace-name la-aks-hci \
  --query id -o tsv)

# Update terraform.tfvars
# Add: log_analytics_workspace_id = "$WORKSPACE_ID"
# Add: enable_monitoring = true

# Apply changes
terraform apply
```

#### Enable Azure Policy

```bash
# Update terraform.tfvars
# Add: enable_azure_policy = true

# Apply changes
terraform apply
```

## Post-Deployment Configuration

### Configure Storage Classes

```bash
# Check available storage classes
kubectl get storageclass

# Set default storage class
kubectl patch storageclass <storage-class-name> \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

### Configure Network Policies

```bash
# Install Calico (if not already installed)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Create a sample network policy
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### Configure RBAC

```bash
# Create a service account
kubectl create serviceaccount app-deployer

# Create a role
kubectl create role deployment-manager \
  --verb=create,get,list,update,delete \
  --resource=deployments,services,pods

# Bind role to service account
kubectl create rolebinding deployment-manager-binding \
  --role=deployment-manager \
  --serviceaccount=default:app-deployer
```

## Troubleshooting

### Issue: Custom Location Not Found

**Solution:**
```bash
# Verify custom location exists
az customlocation show \
  --name "custom-location-aks-hci" \
  --resource-group "rg-stack-hci"

# Recreate if necessary
az customlocation create \
  --name "custom-location-aks-hci" \
  --resource-group "rg-stack-hci" \
  --location "eastus" \
  --host-resource-id $HCI_CLUSTER_ID \
  --namespace "default" \
  --cluster-extension-ids $EXTENSION_ID
```

### Issue: Terraform Apply Fails

**Solution:**
```bash
# Enable debug logging
export TF_LOG=DEBUG

# Re-run apply
terraform apply

# Check Azure activity log
az monitor activity-log list \
  --resource-group rg-aks-hci-prod \
  --max-events 50
```

### Issue: Cannot Connect to Cluster

**Solution:**
```bash
# Check cluster status
az connectedk8s show \
  --name aks-hci-workload \
  --resource-group rg-aks-hci-prod

# Verify connectivity
az connectedk8s proxy \
  --name aks-hci-workload \
  --resource-group rg-aks-hci-prod

# In another terminal, test kubectl
kubectl get nodes
```

### Issue: Nodes Not Ready

**Solution:**
```bash
# Check node status
kubectl get nodes -o wide

# Describe problematic node
kubectl describe node <node-name>

# Check system pods
kubectl get pods -n kube-system

# Check logs
kubectl logs -n kube-system <pod-name>
```

## Cleanup

To destroy all resources:

```bash
# Destroy all infrastructure
terraform destroy

# Confirm by typing 'yes' when prompted
```

**Warning**: This will delete all resources including storage. Ensure you have backups if needed.

## Next Steps

After successful deployment:

1. **Configure CI/CD**: Set up Azure DevOps or GitHub Actions
2. **Set up Monitoring**: Configure Azure Monitor and alerts
3. **Implement GitOps**: Configure Flux for GitOps workflows
4. **Security Hardening**: Apply security policies and scan containers
5. **Backup Strategy**: Configure regular backups
6. **Documentation**: Document your specific configurations

## Support and Resources

- [Azure Stack HCI Documentation](https://docs.microsoft.com/azure-stack/hci/)
- [AKS Hybrid Documentation](https://docs.microsoft.com/azure/aks/hybrid/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## Deployment Checklist

Use this checklist to track your deployment progress:

- [ ] Prerequisites verified
- [ ] Azure Stack HCI cluster registered
- [ ] AKS HCI extension installed
- [ ] Custom location created
- [ ] terraform.tfvars configured
- [ ] Terraform initialized
- [ ] Configuration validated
- [ ] Plan reviewed
- [ ] Infrastructure deployed
- [ ] Deployment verified
- [ ] Clusters accessible
- [ ] Sample application deployed
- [ ] Windows Admin Center configured (optional)
- [ ] Azure Arc features enabled (optional)
- [ ] Post-deployment configuration completed
- [ ] Documentation updated

---

**Deployment Time Estimate**: 45-60 minutes (excluding prerequisites)

**Resource Count**: ~20-25 Azure resources

