# FTGO Application - AKS Deployment Plan

## Prerequisites Checklist

- [x] AKS cluster deployed and accessible
- [x] kubectl configured to connect to workload cluster
- [x] FTGO application repository cloned
- [ ] Azure Container Registry (ACR) created OR Docker Hub access verified
- [ ] Container images available (msapatterns/* images)
- [ ] Storage class configured for AKS

## Current Cluster Status

- **Cluster**: gentic-app-workload
- **Nodes**: 3 Linux nodes (Ready)
- **Kubernetes Version**: v1.34.0
- **Storage**: Azure-managed storage available

## Deployment Strategy

### Phase 1: Preparation
1. Create namespace for FTGO application
2. Verify/configure storage class
3. Check image availability
4. Update YAML files for AKS compatibility

### Phase 2: Infrastructure Deployment
1. Deploy Zookeeper (StatefulSet)
2. Deploy Kafka (StatefulSet) - depends on Zookeeper
3. Deploy MySQL (StatefulSet)
4. Deploy DynamoDB Local (StatefulSet)
5. Wait for all infrastructure pods to be Ready

### Phase 3: Application Services Deployment
1. Deploy Consumer Service
2. Deploy Restaurant Service
3. Deploy Kitchen Service
4. Deploy Accounting Service
5. Deploy Order Service
6. Deploy Order History Service
7. Deploy API Gateway (with LoadBalancer)

### Phase 4: Verification
1. Check all pods are Running
2. Verify services are accessible
3. Test API Gateway endpoint
4. Run health checks

## Required Modifications

### 1. API Version Updates
- Change `apps/v1beta1` → `apps/v1`
- Change `extensions/v1beta1` → `apps/v1`

### 2. Storage Class
- Add `storageClassName: managed-premium` to all PVCs
- Or use `azurefile` for Azure Files (ReadWriteMany)

### 3. Node Selectors
- Add to all deployments:
  ```yaml
  nodeSelector:
    kubernetes.io/os: linux
  ```

### 4. Resource Limits
- Add resource requests and limits to all containers
- Example:
  ```yaml
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  ```

### 5. Service Type Updates
- API Gateway: Change to `LoadBalancer` for external access
- Other services: Keep as `ClusterIP`

### 6. Namespace
- Create `ftgo` namespace
- Add `namespace: ftgo` to all resources

## Resource Estimates

### Per Service (Approximate)
- **CPU**: 250-500m per service
- **Memory**: 512Mi-1Gi per service
- **Total Application Services**: ~3-4 CPU, ~6-8GB RAM

### Infrastructure Services
- **MySQL**: 500m CPU, 1Gi RAM
- **Kafka**: 500m CPU, 1Gi RAM
- **Zookeeper**: 250m CPU, 512Mi RAM
- **DynamoDB Local**: 250m CPU, 512Mi RAM
- **Total Infrastructure**: ~1.5 CPU, ~3GB RAM

### Total Requirements
- **CPU**: ~5-6 cores
- **Memory**: ~10-12 GB
- **Storage**: ~5GB (4x 1Gi PVCs)

## Deployment Commands

### Step 1: Create Namespace
```powershell
kubectl create namespace ftgo
```

### Step 2: Deploy Infrastructure
```powershell
cd ftgo-application
kubectl apply -f deployment/kubernetes/stateful-services/ -n ftgo
```

### Step 3: Wait for Infrastructure
```powershell
kubectl wait --for=condition=ready pod -l role=ftgo-zookeeper -n ftgo --timeout=300s
kubectl wait --for=condition=ready pod -l role=ftgo-kafka -n ftgo --timeout=300s
kubectl wait --for=condition=ready pod -l role=ftgo-mysql -n ftgo --timeout=300s
```

### Step 4: Deploy Application Services
```powershell
kubectl apply -f ftgo-consumer-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-restaurant-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-kitchen-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-accounting-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-order-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-order-history-service/src/deployment/kubernetes/ -n ftgo
kubectl apply -f ftgo-api-gateway/src/deployment/kubernetes/ -n ftgo
```

### Step 5: Check Status
```powershell
kubectl get pods -n ftgo
kubectl get services -n ftgo
kubectl get pvc -n ftgo
```

## Troubleshooting

### If pods are in ImagePullBackOff
- Check if images are accessible: `docker pull msapatterns/ftgo-api-gateway:latest`
- May need to build images or use Azure Container Registry

### If pods are in Pending
- Check node resources: `kubectl describe nodes`
- Check PVC status: `kubectl get pvc -n ftgo`
- Verify storage class: `kubectl get storageclass`

### If services are not accessible
- Check service endpoints: `kubectl get endpoints -n ftgo`
- Check pod logs: `kubectl logs <pod-name> -n ftgo`
- Verify network policies (if enabled)

## Next Actions

1. Review and update YAML files for AKS compatibility
2. Create namespace
3. Verify image availability
4. Deploy infrastructure services
5. Deploy application services
6. Test the deployment

