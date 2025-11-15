# Cluster Access Guide

## Quick Access Commands

### Switch Between Clusters

```powershell
# Switch to workload cluster (for application deployments)
kubectl config use-context gentic-app-workload

# Switch to management cluster
kubectl config use-context gentic-app-management
```

### Get Cluster Credentials

```powershell
# Workload cluster
az aks get-credentials --resource-group rg-gentic-app --name gentic-app-workload --overwrite-existing

# Management cluster
az aks get-credentials --resource-group rg-gentic-app --name gentic-app-management --overwrite-existing
```

## Current Cluster Status

### Workload Cluster (gentic-app-workload)
- **Endpoint**: `gentic-app-workload-wc96eqzg.hcp.eastus.azmk8s.io`
- **Kubernetes Version**: v1.34.0
- **Current Context**: gentic-app-workload (active)

### Management Cluster (gentic-app-management)
- **Endpoint**: `gentic-app-management-yhp6y6q9.hcp.eastus.azmk8s.io`
- **Kubernetes Version**: v1.34.0

## Node Information

### Workload Cluster Nodes
- **Linux Nodes**: 3 nodes
  - `aks-systempool-23138687-vmss000000` (System pool)
  - `aks-linuxpool1-33795332-vmss000000` (Linux pool 1)
  - `aks-linuxpool2-12298390-vmss000000` (Linux pool 2)
- **Windows Node**: 1 node
  - `akswinp1000000` (Windows pool)

All nodes are in **Ready** status.

## Test Deployment Status

### Nginx Test Application
- **Deployment**: `nginx-test`
- **Pods**: 2/2 Running
  - `nginx-test-5744cff95-kkdqw` on `aks-linuxpool2-12298390-vmss000000`
  - `nginx-test-5744cff95-tj7pl` on `aks-linuxpool1-33795332-vmss000000`
- **Service**: `nginx-test-service` (LoadBalancer)
- **External IP**: `48.223.198.88`
- **Access URL**: http://48.223.198.88

## Useful Commands

### Check Cluster Status
```powershell
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespaces
```

### Deploy Applications
```powershell
# Deploy from YAML file
kubectl apply -f <your-deployment.yaml>

# Check deployment status
kubectl get deployments
kubectl get pods -o wide
kubectl get services
```

### View Logs
```powershell
# View pod logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>

# View logs from all pods in deployment
kubectl logs -l app=<app-label>
```

### Troubleshooting
```powershell
# Describe pod for detailed information
kubectl describe pod <pod-name>

# Get events
kubectl get events --sort-by='.lastTimestamp'

# Check pod status
kubectl get pods -o wide
```

## Important Notes

1. **Node Selector**: When deploying Linux containers, always include:
   ```yaml
   nodeSelector:
     kubernetes.io/os: linux
   ```
   This ensures pods are scheduled on Linux nodes, not Windows nodes.

2. **LoadBalancer Services**: External IPs are assigned automatically by Azure. It may take 1-2 minutes for the IP to be assigned.

3. **Resource Groups**: 
   - `rg-gentic-app`: Main resource group (managed by you)
   - `MC_rg-gentic-app_gentic-app-workload_eastus`: Auto-created by AKS for node infrastructure
   - `MC_rg-gentic-app_gentic-app-management_eastus`: Auto-created by AKS for management cluster nodes

4. **Default Namespaces**:
   - `default`: For your applications
   - `kube-system`: Kubernetes system components
   - `calico-system`: Network policy components
   - `gatekeeper-system`: Azure Policy components

## Next Steps

1. Deploy your applications to the workload cluster
2. Use the management cluster for administrative tasks
3. Monitor deployments using `kubectl get` commands
4. Access applications via LoadBalancer external IPs
