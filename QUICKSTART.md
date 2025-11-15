# Quick Start Guide - Azure AKS on Azure Stack HCI

Get your Azure AKS infrastructure on Azure Stack HCI up and running in minutes!

## Prerequisites Check

Ensure you have:

- ✅ Azure subscription
- ✅ Azure Stack HCI cluster with AKS extension
- ✅ Terraform >= 1.5.0
- ✅ Azure CLI
- ✅ 10-15 minutes

## 5-Step Deployment

### Step 1: Get Resource IDs

```bash
# Login to Azure
az login

# Get your Azure Stack HCI cluster resource ID
az stack-hci cluster show \
  --name "YOUR_HCI_CLUSTER_NAME" \
  --resource-group "YOUR_HCI_RG" \
  --query id -o tsv

# Get your AKS HCI extension resource ID
az k8s-extension show \
  --resource-group "YOUR_HCI_RG" \
  --cluster-name "YOUR_HCI_CLUSTER_NAME" \
  --cluster-type connectedClusters \
  --name "aks-hci-extension" \
  --query id -o tsv
```

Save these IDs - you'll need them next!

### Step 2: Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your favorite editor
nano terraform.tfvars
```

**Minimum required changes**:
```hcl
subscription_id            = "YOUR-SUBSCRIPTION-ID"
azure_stack_hci_cluster_id = "PASTE-HCI-CLUSTER-ID-FROM-STEP-1"
aks_hci_extension_id       = "PASTE-EXTENSION-ID-FROM-STEP-1"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

Expected: ✅ "Terraform has been successfully initialized!"

### Step 4: Deploy

```bash
# Plan (optional but recommended)
terraform plan

# Apply
terraform apply
```

Type `yes` when prompted. Deployment takes ~30-45 minutes. ☕

### Step 5: Access Your Cluster

```bash
# Get kubeconfig
terraform output -raw workload_cluster_kubeconfig > kubeconfig.yaml

# Set environment variable
export KUBECONFIG=./kubeconfig.yaml

# Verify access
kubectl get nodes
```

Expected output:
```
NAME                STATUS   ROLES    AGE   VERSION
linuxpool1-xxxxx    Ready    agent    5m    v1.28.3
linuxpool1-yyyyy    Ready    agent    5m    v1.28.3
winpool1-xxxxx      Ready    agent    5m    v1.28.3
winpool1-yyyyy      Ready    agent    5m    v1.28.3
```

## 🎉 You're Done!

Your infrastructure is ready. Now let's deploy something!

## Deploy Your First Application

### Linux Application (NGINX)

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest --replicas=3

# Expose service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get external IP (may take a few minutes)
kubectl get service nginx --watch
```

Once you see an external IP, access it in your browser!

### Windows Application (IIS)

```bash
# Create Windows deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-demo
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
  name: iis-demo
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: iis
EOF

# Check status
kubectl get pods -l app=iis
kubectl get service iis-demo
```

## Common Commands

### Cluster Info

```bash
# View all resources
terraform output

# Get deployment summary
terraform output deployment_summary

# Check cluster info
kubectl cluster-info
```

### Node Management

```bash
# List nodes
kubectl get nodes -o wide

# Describe a node
kubectl describe node <node-name>

# View node resources
kubectl top nodes
```

### Pod Management

```bash
# List all pods
kubectl get pods --all-namespaces

# View pod logs
kubectl logs <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash
```

### Service Management

```bash
# List services
kubectl get services --all-namespaces

# View service details
kubectl describe service <service-name>

# Delete service
kubectl delete service <service-name>
```

## Scaling

### Scale Deployment

```bash
# Scale up
kubectl scale deployment nginx --replicas=5

# Scale down
kubectl scale deployment nginx --replicas=1
```

### Scale Node Pool

Edit `terraform.tfvars`:
```hcl
linux_node_pools = [
  {
    name       = "linuxpool1"
    node_count = 4  # Changed from 2
    vm_size    = "Standard_D4s_v3"
    os_type    = "Linux"
  }
]
```

Apply changes:
```bash
terraform apply
```

## Monitoring

### Azure Portal

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to your resource group
3. Click on your cluster
4. View monitoring, metrics, and logs

### Command Line

```bash
# Watch pods
kubectl get pods --all-namespaces --watch

# View events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods
```

## Troubleshooting

### Can't connect to cluster?

```bash
# Re-export kubeconfig
export KUBECONFIG=./kubeconfig.yaml

# Or use Azure CLI
az connectedk8s proxy \
  --name $(terraform output -raw workload_cluster_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

### Pods not starting?

```bash
# Check pod status
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>

# Check events
kubectl get events
```

### LoadBalancer IP pending?

```bash
# Wait a few minutes, then check again
kubectl get services --watch

# Check load balancer status
az network lb list \
  --resource-group $(terraform output -raw resource_group_name)
```

### Terraform apply failed?

```bash
# Enable debug mode
export TF_LOG=DEBUG

# Try again
terraform apply

# Check Azure activity logs
az monitor activity-log list \
  --resource-group $(terraform output -raw resource_group_name)
```

## Clean Up

### Delete Applications

```bash
# Delete deployments
kubectl delete deployment nginx
kubectl delete deployment iis-demo

# Delete services
kubectl delete service nginx
kubectl delete service iis-demo
```

### Destroy Infrastructure

⚠️ **Warning**: This deletes everything!

```bash
terraform destroy
```

Type `yes` when prompted.

## Next Steps

Now that you have a working cluster, explore:

1. **[Full Documentation](README.md)** - Detailed configuration options
2. **[Architecture Guide](ARCHITECTURE.md)** - Deep dive into the design
3. **[Deployment Guide](DEPLOYMENT.md)** - Complete deployment procedures
4. **Enable Azure Arc Features** - Monitoring, Policy, GitOps
5. **Set Up CI/CD** - Automate deployments
6. **Configure Backup** - Protect your data

## Get Help

Having issues? Check:

- **Outputs**: `terraform output`
- **Azure Portal**: Check resource status
- **Logs**: `kubectl logs` and Azure activity logs
- **Documentation**: README.md and DEPLOYMENT.md

## Configuration Examples

### Minimal Configuration (Development)

```hcl
# Small cluster for testing
management_node_count = 1
workload_control_plane_count = 1
enable_control_plane_ha = false

linux_node_pools = [
  {
    name       = "linuxpool"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
    os_type    = "Linux"
  }
]

windows_node_pools = []  # No Windows nodes
```

### Production Configuration

```hcl
# Highly available production cluster
management_node_count = 1
workload_control_plane_count = 3
enable_control_plane_ha = true

linux_node_pools = [
  {
    name       = "linuxpool1"
    node_count = 4
    vm_size    = "Standard_D8s_v3"
    os_type    = "Linux"
  },
  {
    name       = "linuxpool2"
    node_count = 4
    vm_size    = "Standard_D8s_v3"
    os_type    = "Linux"
  }
]

windows_node_pools = [
  {
    name       = "winpool1"
    node_count = 3
    vm_size    = "Standard_D8s_v3"
    os_type    = "Windows"
  }
]

enable_azure_arc = true
enable_monitoring = true
```

## Useful Links

- 📘 [README.md](README.md) - Full documentation
- 🏗️ [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture details
- 🚀 [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- 🔗 [Azure Stack HCI Docs](https://docs.microsoft.com/azure-stack/hci/)
- 🔗 [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- 🔗 [Kubernetes Docs](https://kubernetes.io/docs/)

## Tips & Tricks

### Save Time

```bash
# Create aliases
alias k=kubectl
alias tf=terraform

# Quick cluster access
export KUBECONFIG=./kubeconfig.yaml

# Watch resources
watch kubectl get pods,svc
```

### Resource Labels

Add labels to organize resources:

```bash
kubectl label deployment nginx env=production
kubectl label deployment nginx team=platform

# Filter by labels
kubectl get pods -l env=production
```

### Port Forwarding

Test services without LoadBalancer:

```bash
# Forward local port to pod
kubectl port-forward deployment/nginx 8080:80

# Access at http://localhost:8080
```

### Debugging

```bash
# Run temporary debug pod
kubectl run debug --rm -it --image=busybox -- /bin/sh

# Inside pod, test connectivity
wget -O- http://nginx
```

---

**⏱️ Total Time**: ~45 minutes from start to deployed application

**💰 Cost**: Based on Azure Stack HCI licensing + Azure services

**🎯 Difficulty**: Intermediate (with this guide!)

Happy containerizing! 🚀

