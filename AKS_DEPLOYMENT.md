# AKS Deployment Guide

## Overview

The CI/CD pipeline now includes automatic deployment to AKS after building and pushing images to ACR.

## Deployment Process

### 1. Build and Push (Job 1)
- Builds all Docker images
- Pushes to Azure Container Registry
- Tags with commit SHA and `latest`

### 2. Deploy to AKS (Job 2)
- Connects to AKS cluster
- Creates `ftgo` namespace
- Deploys infrastructure services (MySQL, Kafka, Zookeeper, DynamoDB)
- Deploys application services (7 microservices)
- Deploys API Gateway with LoadBalancer service
- Waits for all services to be ready
- Outputs Load Balancer URL

## Kubernetes Manifests

All AKS-specific manifests are in: `ftgo-application/deployment/kubernetes/aks/`

### Infrastructure Services
- `ftgo-zookeeper-aks.yml` - Zookeeper StatefulSet
- `ftgo-kafka-aks.yml` - Kafka StatefulSet
- `ftgo-mysql-aks.yml` - MySQL StatefulSet (uses ACR image)
- `ftgo-dynamodb-aks.yml` - DynamoDB Local + Init Job (uses ACR images)

### Application Services
- `ftgo-services-aks.yml` - All 7 microservices (Consumer, Restaurant, Order, Kitchen, Accounting, Order History)
- `ftgo-api-gateway-lb.yml` - API Gateway with LoadBalancer service

## Key Features

### ACR Images
All services use images from ACR: `acrgenticapp2932.azurecr.io`

### LoadBalancer Service
API Gateway is exposed via Azure Load Balancer with a public IP

### Node Selectors
All pods use `kubernetes.io/os: linux` to ensure they run on Linux nodes

### Resource Limits
All services have resource requests and limits configured

### Health Checks
All services have liveness and readiness probes

### Rolling Updates
Deployments use rolling update strategy with zero downtime

## Deployment Order

1. **Namespace**: `ftgo` namespace is created
2. **Secrets**: Database secret is deployed
3. **Infrastructure** (in parallel):
   - Zookeeper
   - Kafka
   - MySQL
   - DynamoDB Local
4. **Wait**: Infrastructure services become ready
5. **DynamoDB Init**: Tables are created
6. **Application Services** (in parallel):
   - Consumer Service
   - Restaurant Service
   - Order Service
   - Kitchen Service
   - Accounting Service
   - Order History Service
7. **API Gateway**: Deployed with LoadBalancer service
8. **Wait**: All deployments become available
9. **Output**: Load Balancer URL is displayed

## Accessing the Application

### Load Balancer URL

After deployment, the Load Balancer URL will be displayed in:
- GitHub Actions workflow summary
- Workflow logs
- Can be retrieved with: `kubectl get service ftgo-api-gateway -n ftgo`

### Example URLs

- **API Gateway**: `http://<LOAD_BALANCER_IP>`
- **Swagger UI** (if configured): `http://<LOAD_BALANCER_IP>/swagger-ui.html`

## Manual Deployment

If you need to deploy manually:

```bash
# Get AKS credentials
az aks get-credentials --resource-group rg-gentic-app --name gentic-app-workload

# Create namespace
kubectl create namespace ftgo

# Deploy database secret
kubectl apply -f ftgo-application/deployment/kubernetes/stateful-services/ftgo-db-secret.yml -n ftgo

# Deploy infrastructure
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-zookeeper-aks.yml -n ftgo
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-kafka-aks.yml -n ftgo
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-mysql-aks.yml -n ftgo
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-dynamodb-aks.yml -n ftgo

# Wait for infrastructure
kubectl wait --for=condition=ready pod -l role=ftgo-mysql -n ftgo --timeout=300s

# Deploy application services
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-services-aks.yml -n ftgo
kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-api-gateway-lb.yml -n ftgo

# Get Load Balancer URL
kubectl get service ftgo-api-gateway -n ftgo
```

## Monitoring Deployment

### Check Pod Status

```bash
kubectl get pods -n ftgo
```

### Check Services

```bash
kubectl get services -n ftgo
```

### Check Load Balancer

```bash
kubectl get service ftgo-api-gateway -n ftgo
```

### View Logs

```bash
# API Gateway logs
kubectl logs -f deployment/ftgo-api-gateway -n ftgo

# Any service logs
kubectl logs -f deployment/<service-name> -n ftgo
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n ftgo

# Check events
kubectl get events -n ftgo --sort-by='.lastTimestamp'
```

### Image Pull Errors

- Verify ACR access: `az aks check-acr --name gentic-app-workload --resource-group rg-gentic-app --acr acrgenticapp2932`
- Check images exist: `az acr repository list --name acrgenticapp2932`

### Load Balancer Not Assigned

- Azure Load Balancer can take 2-5 minutes to assign IP
- Check service: `kubectl describe service ftgo-api-gateway -n ftgo`
- Verify Standard Load Balancer is configured in AKS

### Services Not Ready

- Check pod logs: `kubectl logs <pod-name> -n ftgo`
- Check health probes: `kubectl describe pod <pod-name> -n ftgo`
- Verify dependencies (MySQL, Kafka) are running

## Next Steps

After successful deployment:
1. Application is accessible via Load Balancer URL
2. All services are running in `ftgo` namespace
3. API Gateway routes traffic to backend services
4. Test the application endpoints
5. Configure monitoring and logging (optional)

