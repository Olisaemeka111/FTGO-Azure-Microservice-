# FTGO Application Analysis for AKS Deployment

## Application Overview

The **FTGO (Food To Go)** application is a microservices-based food delivery application that demonstrates various microservice patterns from the book "Microservice Patterns" by Chris Richardson.

### Architecture Components

#### Microservices (7 services)
1. **ftgo-api-gateway** - API Gateway (Entry point)
2. **ftgo-consumer-service** - Consumer Service
3. **ftgo-restaurant-service** - Restaurant Service
4. **ftgo-order-service** - Order Service (Orchestrates sagas)
5. **ftgo-kitchen-service** - Kitchen Service
6. **ftgo-accounting-service** - Accounting Service (Uses event sourcing)
7. **ftgo-order-history-service** - Order History Service (CQRS view)

#### Infrastructure Services (Stateful)
1. **MySQL** - Database for most services
2. **Apache Kafka** - Message broker for event-driven communication
3. **Zookeeper** - Required by Kafka
4. **DynamoDB Local** - Used by order-history-service

## Deployment Structure

### Kubernetes Deployment Files Location

```
ftgo-application/
├── deployment/kubernetes/
│   ├── stateful-services/          # Infrastructure services
│   │   ├── ftgo-mysql-deployment.yml
│   │   ├── ftgo-kafka-deployment.yml
│   │   ├── ftgo-zookeeper-deployment.yml
│   │   ├── ftgo-dynamodb-local.yml
│   │   └── ftgo-db-secret.yml
│   ├── cdc-service/                # Change Data Capture
│   │   └── ftgo-cdc-service.yml
│   └── scripts/                    # Deployment scripts
│       ├── kubernetes-deploy-all.sh
│       ├── kubernetes-delete-all.sh
│       └── kubernetes-wait-for-ready-pods.sh
└── [service-name]/src/deployment/kubernetes/
    └── ftgo-[service-name].yml     # Individual service deployments
```

## Deployment Requirements

### 1. Infrastructure Services (Deploy First)

#### MySQL
- **Type**: StatefulSet
- **Storage**: 1Gi PersistentVolume
- **Image**: `msapatterns/mysql:latest`
- **Port**: 3306
- **Credentials**: 
  - Root password: `rootpassword`
  - User: `mysqluser`
  - Password: `mysqlpw`

#### Zookeeper
- **Type**: StatefulSet
- **Storage**: 1Gi PersistentVolume
- **Image**: `confluentinc/cp-zookeeper:5.2.4`
- **Port**: 2181
- **Required by**: Kafka

#### Kafka
- **Type**: StatefulSet
- **Storage**: 1Gi PersistentVolume
- **Image**: `confluentinc/cp-kafka:5.2.4`
- **Port**: 9092
- **Dependencies**: Zookeeper

#### DynamoDB Local
- **Type**: Deployment
- **Image**: `amazon/dynamodb-local:latest`
- **Port**: 8000
- **Used by**: Order History Service

### 2. Application Services (Deploy After Infrastructure)

All services follow a similar pattern:
- **Type**: Deployment
- **Image**: `msapatterns/ftgo-[service-name]:latest`
- **Image Pull Policy**: Always
- **Port**: 8080 (except API Gateway on 80)
- **Health Checks**: Liveness and Readiness probes on `/actuator/health`

#### Service Dependencies

```
API Gateway
  ├── Order Service
  ├── Order History Service
  └── Consumer Service

Order Service
  ├── MySQL
  ├── Kafka
  ├── Consumer Service
  ├── Kitchen Service
  └── Accounting Service

Kitchen Service
  ├── MySQL
  └── Kafka

Consumer Service
  ├── MySQL
  └── Kafka

Restaurant Service
  ├── MySQL
  └── Kafka

Accounting Service
  ├── MySQL
  └── Kafka

Order History Service
  └── DynamoDB Local
```

## Issues to Address for AKS Deployment

### 1. API Version Updates
- **Current**: Uses deprecated `apps/v1beta1` and `extensions/v1beta1`
- **Required**: Update to `apps/v1` for StatefulSets and Deployments

### 2. Image Availability
- **Images**: All services use `msapatterns/*` images
- **Action**: Verify images are available on Docker Hub or build/push to Azure Container Registry

### 3. Storage Classes
- **Current**: Uses default storage class
- **Recommended**: Use Azure-managed storage class for AKS
  - `managed-premium` or `azurefile` for Azure Files

### 4. Service Types
- **Current**: Most services use ClusterIP
- **API Gateway**: Should use LoadBalancer for external access

### 5. Resource Limits
- **Current**: No resource requests/limits defined
- **Recommended**: Add resource requests and limits for proper scheduling

### 6. Node Selectors
- **Current**: No node selectors
- **Recommended**: Add `kubernetes.io/os: linux` to ensure Linux nodes

### 7. Namespace
- **Current**: Deploys to default namespace
- **Recommended**: Create dedicated namespace (e.g., `ftgo`)

## Deployment Order

1. **Infrastructure Services** (StatefulSets)
   - Zookeeper
   - Kafka
   - MySQL
   - DynamoDB Local

2. **Wait for Infrastructure** (Ensure all pods are ready)

3. **Application Services**
   - Consumer Service
   - Restaurant Service
   - Kitchen Service
   - Accounting Service
   - Order Service
   - Order History Service
   - API Gateway (Last)

## Resource Requirements

### Estimated Resource Needs
- **CPU**: ~8-10 cores total
- **Memory**: ~16-20 GB total
- **Storage**: ~5-10 GB (PersistentVolumes)
- **Nodes**: Minimum 3-4 nodes recommended

### Current AKS Configuration
- **Linux Nodes**: 3 nodes (systempool + 2 linux pools)
- **Windows Node**: 1 node (not needed for this app)
- **VM Size**: Standard_D2s_v3 (2 vCPU, 8GB RAM each)
- **Total Capacity**: 6 vCPU, 24GB RAM (Linux nodes)

**Note**: Current cluster may need scaling for full deployment.

## Next Steps

1. Repository cloned and analyzed
2. Update Kubernetes manifests for AKS compatibility
3. Create Azure Container Registry (or verify Docker Hub access)
4. Build/push container images
5. Create namespace
6. Deploy infrastructure services
7. Deploy application services
8. Configure LoadBalancer for API Gateway
9. Test deployment

## Files to Modify

1. All YAML files in `deployment/kubernetes/stateful-services/`
2. All YAML files in `*/src/deployment/kubernetes/`
3. Update API versions
4. Add storage class annotations
5. Add resource limits
6. Add node selectors
7. Update service types (LoadBalancer for API Gateway)

