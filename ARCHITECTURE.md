# Architecture Documentation - Azure AKS Cloud-Native Deployment

This document provides detailed architecture information for the cloud-native Azure Kubernetes Service (AKS) deployment with FTGO microservices application.

## Overview

This architecture implements a production-ready Azure Kubernetes Service (AKS) infrastructure on Azure cloud, featuring:

- **Cloud-Native Architecture**: Fully managed AKS clusters on Azure
- **High Availability**: Redundant control planes and load balancers
- **Multi-Platform Support**: Both Linux and Windows container workloads
- **Azure Integration**: Azure Monitor, Policy, and Defender capabilities
- **Security**: Network isolation, RBAC, security contexts, and encrypted communications
- **Observability**: Complete monitoring stack with Prometheus, Grafana, Jaeger, and Loki
- **CI/CD**: Automated build, scan, and deployment pipeline

## Architecture Diagram Components

### 1. Management Cluster (AKS)

**Purpose**: Infrastructure management and governance

**Architecture**:
```
┌─────────────────────────────────┐
│    Management Cluster           │
│  ┌─────────────────────────┐    │
│  │   Azure Load Balancer   │    │
│  │   (Standard SKU)        │    │
│  └──────────┬──────────────┘    │
│             │                   │
│  ┌──────────▼──────────────┐    │
│  │   Control Plane (HA)    │    │
│  │   - API Server          │    │
│  │   - etcd                │    │
│  │   - Scheduler           │    │
│  └──────────┬──────────────┘    │
│             │                   │
│  ┌──────────▼──────────────┐    │
│  │   System Node Pool      │    │
│  │   - System Services     │    │
│  │   - Monitoring         │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Specifications**:
- **Control Plane**: Managed by Azure (HA)
- **System Node Pool**: 1 node
- **VM Size**: Standard_D2s_v3
- **OS**: Linux
- **Purpose**: AKS infrastructure management and governance

**Key Features**:
- RBAC enabled
- OIDC issuer enabled
- Azure Policy integration
- Azure Monitor integration

### 2. Workload Cluster

**Purpose**: Run production containerized applications (FTGO microservices)

**Architecture**:
```
┌──────────────────────────────────────────────┐
│           Workload Cluster                   │
│  ┌────────────────────────────────────────┐  │
│  │      Load Balancer (Standard)          │  │
│  │      Frontend IP + Backend Pool        │  │
│  └────────────┬───────────────────────────┘  │
│               │                              │
│  ┌────────────▼───────────────────────────┐  │
│  │      API Server + Control Plane (HA)   │  │
│  │      3 Nodes across Availability Zones │  │
│  └────────────┬───────────────────────────┘  │
│               │                              │
│  ┌────────────▼───────────────────────────┐  │
│  │          Pod Orchestration             │  │
│  │  ┌────────┐  ┌────────┐  ┌────────┐    │  │
│  │  │  Pod   │  │  Pod   │  │  Pod   │    │  │
│  │  │ ┌────┐ │  │ ┌────┐ │  │ ┌────┐ │    │  │
│  │  │ │Ctr1│ │  │ │Ctr1│ │  │ │Ctr1│ │    │  │
│  │  │ │Ctr2│ │  │ │Ctr2│ │  │ │Ctr2│ │    │  │
│  │  │ └────┘ │  │ └────┘ │  │ └────┘ │    │  │
│  │  └────────┘  └────────┘  └────────┘    │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │         Worker Nodes                   │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐  │  │
│  │  │Linux VM │ │Linux VM │ │Win VM   │  │  │
│  │  │Pool 1   │ │Pool 2   │ │Pool 1   │  │  │
│  │  │(2 VMs)  │ │(2 VMs)  │ │(2 VMs)  │  │  │
│  │  └─────────┘ └─────────┘ └─────────┘  │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

**Specifications**:
- **Control Plane**: Managed by Azure (HA)
- **System Node Pool**: 1 node (Standard_D2s_v3)
- **Linux Node Pools**: Autoscaling enabled
- **Windows Node Pool**: 1 pool (winp1)
- **VM Size**: Standard_D2s_v3
- **Availability Zone**: Zone 3 (eastus)
- **Purpose**: Production application workloads

**Key Features**:
- RBAC enabled
- OIDC issuer enabled
- Network Policy: Calico
- Auto-scaling enabled
- Standard Load Balancer

### 3. Monitoring and Observability Stack

**Purpose**: Complete observability for metrics, logs, and traces

**Namespace**: `monitoring`

**Components**:
```
┌──────────────────────────────────────────────┐
│         Monitoring Namespace                 │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Metrics Collection                     │ │
│  │  - Prometheus (metrics)                 │ │
│  │  - Node Exporter (node metrics)         │ │
│  │  - Kube State Metrics (K8s metrics)     │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Visualization                          │ │
│  │  - Grafana (dashboards)                 │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Logging                                │ │
│  │  - Loki (log aggregation)              │ │
│  │  - Promtail (log collection)           │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Tracing                                │ │
│  │  - Jaeger (distributed tracing)         │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Alerting                               │ │
│  │  - Alertmanager (alert routing)         │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

**Load Balancers**:
- Grafana: Port 80 (admin/admin)
- Prometheus: Port 80
- Jaeger: Port 80

**Access**: All tools accessible via LoadBalancer services

## Network Architecture

### Network Topology

```
┌────────────────────────────────────────────────────┐
│          Virtual Network (10.0.0.0/16)             │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Management Subnet (10.0.1.0/24)             │ │
│  │                                              │ │
│  │  - Management Cluster                        │ │
│  │  - API Server                                │ │
│  │  - Load Balancer                             │ │
│  │  - NSG: Management Rules                     │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Workload Subnet (10.0.2.0/24)               │ │
│  │                                              │ │
│  │  - Workload Cluster                          │ │
│  │  - Worker Nodes                              │ │
│  │  - Load Balancer                             │ │
│  │  - NSG: Workload Rules                       │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Pod Network (10.244.0.0/16)                 │ │
│  │  Calico Network Policy                       │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Service Network (10.96.0.0/16)              │ │
│  │  ClusterIP Services                          │ │
│  └──────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
```

### Network Security Groups

**Management NSG Rules**:
- Allow TCP 6443 (Kubernetes API)
- Allow TCP 443 (HTTPS)
- Allow TCP 22 (SSH)
- Deny all other inbound traffic

**Workload NSG Rules**:
- Allow TCP 6443 (Kubernetes API)
- Allow TCP 80 (HTTP)
- Allow TCP 443 (HTTPS)
- Allow TCP 30000-32767 (NodePort Services)
- Deny all other inbound traffic

### Load Balancers

**Management Load Balancer**:
- **Type**: Standard SKU
- **Frontend**: Public IP
- **Backend Pool**: Management cluster VMs
- **Rules**: API Server (6443), HTTPS (443)
- **Health Probes**: TCP on port 6443

**Workload Load Balancer**:
- **Type**: Standard SKU
- **Frontend**: Public IP
- **Backend Pool**: Workload cluster VMs
- **Rules**: HTTP (80), HTTPS (443), API Server (6443)
- **Health Probes**: TCP on ports 80, 443, 6443

## Storage Architecture

### Storage Layers

```
┌─────────────────────────────────────────────┐
│     Application Storage                     │
│  ┌─────────────────────────────────────┐    │
│  │  Persistent Volume Claims (PVCs)    │    │
│  │  - MySQL (1Gi)                      │    │
│  │  - Kafka (1Gi)                      │    │
│  │  - Zookeeper (1Gi)                  │    │
│  │  - DynamoDB (1Gi)                   │    │
│  │  - Loki (10Gi)                      │    │
│  └──────────────┬──────────────────────┘    │
│                 │                           │
│  ┌──────────────▼──────────────────────┐    │
│  │  Persistent Volumes (PVs)           │    │
│  │  - Azure Managed Disks              │    │
│  │  - Dynamic Provisioning             │    │
│  └──────────────┬──────────────────────┘    │
│                 │                           │
│  ┌──────────────▼──────────────────────┐    │
│  │  Storage Classes                    │    │
│  │  - default (Azure Managed Disks)    │    │
│  │  - managed-premium (SSD)            │    │
│  └──────────────┬──────────────────────┘    │
└─────────────────┼───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│     Azure Storage Account                   │
│  ┌─────────────────────────────────────┐    │
│  │  Blob Storage                       │    │
│  │  - Container images (ACR)           │    │
│  │  - Terraform state                  │    │
│  │  - Backups                          │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │  File Shares                        │    │
│  │  - Shared storage (optional)        │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Storage Features

- **Azure Managed Disks**: Automatic PV creation
- **Storage Classes**: Default and premium options
- **Dynamic Provisioning**: Automatic volume creation
- **Security**: Encrypted at rest
- **Redundancy**: LRS (locally redundant storage)
- **Backup**: Azure Backup integration available

## Application Architecture

### FTGO Microservices Application

**Namespace**: `ftgo`

**Application Services (7 microservices)**:
1. **ftgo-api-gateway** - API Gateway (LoadBalancer, port 80)
2. **ftgo-consumer-service** - Consumer Service
3. **ftgo-restaurant-service** - Restaurant Service
4. **ftgo-order-service** - Order Service
5. **ftgo-kitchen-service** - Kitchen Service
6. **ftgo-accounting-service** - Accounting Service
7. **ftgo-order-history-service** - Order History Service

**Infrastructure Services**:
1. **MySQL** - Database (StatefulSet, 1Gi storage)
2. **Apache Kafka** - Message broker (StatefulSet, 1Gi storage)
3. **Zookeeper** - Required by Kafka (StatefulSet, 1Gi storage)
4. **DynamoDB Local** - Used by order-history-service (StatefulSet, 1Gi storage)
5. **CDC Service** - Change Data Capture service

**Deployment Features**:
- All services use ACR images
- Security contexts (non-root, read-only filesystem)
- Resource limits and requests
- Health checks (liveness/readiness)
- Network policies for service isolation
- Secrets for database credentials

## Security Architecture

### Security Layers

```
┌──────────────────────────────────────────────┐
│  Identity & Access Management               │
│  - Azure RBAC                                │
│  - Kubernetes RBAC                           │
│  - Service Principals                        │
│  - Managed Identities                        │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Network Security                            │
│  - NSGs (Firewall Rules)                     │
│  - Service Endpoints                         │
│  - Network Policies (Calico)                 │
│  - Private Endpoints                         │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Cluster Security                            │
│  - TLS Encryption                            │
│  - Secrets Management                        │
│  - Pod Security Policies                     │
│  - Image Scanning                            │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Data Security                               │
│  - Encryption at Rest                        │
│  - Encryption in Transit                     │
│  - Key Management                            │
│  - Backup Encryption                         │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Monitoring & Compliance                     │
│  - Azure Monitor                             │
│  - Azure Security Center                     │
│  - Azure Policy                              │
│  - Audit Logs                                │
└──────────────────────────────────────────────┘
```

### Security Features

1. **Network Isolation**
   - Separate subnets for management and workload
   - NSG rules for traffic filtering
   - Network policies within Kubernetes

2. **Authentication & Authorization**
   - Azure AD integration
   - RBAC for cluster access
   - Service accounts for applications

3. **Encryption**
   - TLS for all API communication
   - HTTPS-only storage access
   - Encrypted secrets in etcd

4. **Compliance**
   - Azure Policy enforcement
   - Security scanning
   - Audit logging

## High Availability & Disaster Recovery

### HA Components

```
┌───────────────────────────────────────────────┐
│  Control Plane HA (Zone Redundant)           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │  CP-1   │  │  CP-2   │  │  CP-3   │       │
│  │ Zone 1  │  │ Zone 2  │  │ Zone 3  │       │
│  └────┬────┘  └────┬────┘  └────┬────┘       │
│       │            │            │             │
│       └────────────┴────────────┘             │
│                    │                          │
└────────────────────┼──────────────────────────┘
                     │
┌────────────────────▼──────────────────────────┐
│  etcd Cluster (Distributed State)             │
│  - 3 replicas for quorum                      │
│  - Automatic leader election                  │
└────────────────────┬──────────────────────────┘
                     │
┌────────────────────▼──────────────────────────┐
│  Worker Nodes (Replicated)                    │
│  - Multiple node pools                        │
│  - Pod replicas across nodes                  │
│  - Automatic rescheduling                     │
└────────────────────┬──────────────────────────┘
                     │
┌────────────────────▼──────────────────────────┐
│  Storage (Resilient)                          │
│  - Azure Stack HCI 3-way mirror               │
│  - Storage Spaces Direct                      │
│  - Azure Storage geo-redundancy (optional)    │
└───────────────────────────────────────────────┘
```

### DR Strategy

1. **Backup**
   - etcd snapshots (daily)
   - Application data backups
   - Configuration backups

2. **Replication**
   - Storage replication within HCI
   - Azure Storage for off-cluster backups
   - GitOps for configuration as code

3. **Recovery**
   - Automated cluster recovery
   - Terraform for infrastructure recreation
   - Application redeployment from GitOps

### RTO/RPO Targets

- **RTO** (Recovery Time Objective): 1 hour
- **RPO** (Recovery Point Objective): 5 minutes
- **Availability SLA**: 99.95%

## Scalability

### Scaling Dimensions

1. **Horizontal Scaling (Nodes)**
   - Add/remove worker nodes
   - Auto-scaling with Kubernetes HPA
   - Cluster autoscaler

2. **Vertical Scaling (Resources)**
   - Increase VM sizes
   - Add physical hosts to HCI
   - Expand storage capacity

3. **Application Scaling**
   - Horizontal Pod Autoscaler (HPA)
   - Vertical Pod Autoscaler (VPA)
   - Cluster Autoscaler

### Capacity Planning

**Per Worker Node** (Standard_D4s_v3):
- 4 vCPUs
- 16 GB RAM
- ~50 pods maximum

**Current Capacity**:
- 6 worker nodes
- 24 vCPUs total
- 96 GB RAM total
- ~300 pods maximum

## Monitoring & Observability

### Monitoring Stack Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Monitoring Namespace                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Prometheus (Metrics Collection)                 │  │
│  │  - Scrapes: K8s API, Nodes, Pods, Services       │  │
│  │  - Storage: 30 days retention                     │  │
│  │  - LoadBalancer: Port 80                          │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                              │
│  ┌───────────────────────▼──────────────────────────┐  │
│  │  Grafana (Visualization)                         │  │
│  │  - Pre-configured: Prometheus datasource         │  │
│  │  - Dashboards: Kubernetes, Node, Application    │  │
│  │  - LoadBalancer: Port 80 (admin/admin)          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Loki + Promtail (Log Aggregation)               │  │
│  │  - Promtail: DaemonSet (collects from all nodes) │  │
│  │  - Loki: StatefulSet (10Gi storage)              │  │
│  │  - Query: Via Grafana Logs panel                 │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Jaeger (Distributed Tracing)                    │  │
│  │  - Collector: Receives traces                   │  │
│  │  - Query: UI for trace visualization            │  │
│  │  - Agent: DaemonSet for trace collection        │  │
│  │  - LoadBalancer: Port 80                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Alertmanager (Alert Routing)                    │  │
│  │  - Receives alerts from Prometheus              │  │
│  │  - Routes to: Email, Slack, Webhooks            │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Node Exporter (Node Metrics)                   │  │
│  │  - DaemonSet: One per node                      │  │
│  │  - Metrics: CPU, Memory, Disk, Network         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Kube State Metrics (K8s Object Metrics)       │  │
│  │  - Deployment, Pod, Service metrics             │  │
│  │  - Resource quotas, limits                      │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Metrics Collected

**Infrastructure Metrics**:
- Node CPU, memory, disk, network
- Pod resource usage
- Kubernetes object states
- API server metrics

**Application Metrics**:
- FTGO service metrics (via Prometheus annotations)
- Request rates and latency
- Error rates
- Custom business metrics

**Log Aggregation**:
- Pod logs from all namespaces
- Container logs
- Application logs
- System logs

**Distributed Tracing**:
- Request traces across services
- Service dependencies
- Performance bottlenecks
- Error propagation

### Key Metrics

- **Cluster Health**: Node status, pod status, deployment health
- **Resource Utilization**: CPU, memory, storage per node/pod
- **Application Performance**: Response time, throughput, error rates
- **Network**: Bandwidth, latency, connection errors
- **Security**: Failed authentications, policy violations, vulnerability scans

## CI/CD Pipeline Architecture

### GitHub Actions Workflow

**Workflow**: `.github/workflows/build-and-push.yml`

**Stages**:
1. **Build and Push**:
   - Code linting and quality checks
   - Dependency vulnerability scanning
   - Build Java services with Gradle
   - Build Docker images
   - Container vulnerability scanning (Trivy)
   - Push images to ACR

2. **Deploy to AKS**:
   - Create namespaces (ftgo, monitoring)
   - Deploy secrets
   - Deploy infrastructure services
   - Deploy monitoring stack
   - Deploy application services
   - Deploy network policies
   - Wait for services to be ready
   - Output Load Balancer URLs

**Security Scanning**:
- Code linting (Gradle check, Spotless)
- Dependency scanning (OWASP Dependency Check)
- Container scanning (Trivy on all images)
- Infrastructure scanning (TFLint, Checkov)
- YAML validation (yamllint)

**Separate Security Workflow**: `.github/workflows/security-scan.yml`
- Weekly scheduled scans
- Comprehensive security analysis
- Results in GitHub Security tab

## Cost Optimization

### Cost Breakdown

1. **Azure AKS Clusters**
   - Control plane: Free (managed by Azure)
   - Worker nodes: VM costs
   - Load balancers: Standard SKU costs

2. **Azure Services**
   - Storage account (blob and file shares)
   - Container Registry (ACR)
   - Public IPs
   - Monitoring (optional Azure Monitor)

3. **Compute Resources**
   - Management cluster nodes
   - Workload cluster nodes
   - Monitoring stack resources

### Optimization Strategies

- Use smaller VM sizes for non-production
- Reduce node counts in development
- Enable cluster autoscaling
- Use spot instances for non-critical workloads
- Right-size monitoring stack resources
- Clean up unused resources regularly

## Current Deployment State

### Infrastructure
- Management Cluster: Deployed and operational
- Workload Cluster: Deployed with Linux and Windows node pools
- Azure Container Registry: Created and configured
- Storage Account: Created with blob and file share support
- Network: Virtual network with subnets and NSGs

### Application
- FTGO Application: 7 microservices + 4 infrastructure services
- Namespace: `ftgo`
- All services deployed with security contexts
- Network policies configured
- Secrets management implemented

### Monitoring
- Monitoring Stack: Fully deployed in `monitoring` namespace
- Prometheus: Metrics collection and alerting
- Grafana: Visualization and dashboards
- Jaeger: Distributed tracing
- Loki + Promtail: Log aggregation
- Alertmanager: Alert routing
- Node Exporter: Node metrics
- Kube State Metrics: Kubernetes object metrics

### CI/CD
- Build Pipeline: Operational
- Security Scanning: Integrated
- Deployment Pipeline: Automated
- All images: Built and pushed to ACR

## References

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico Network Policy](https://docs.projectcalico.org/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

---

**Last Updated**: Current as of latest deployment  
**Target Kubernetes Version**: Latest stable  
**Architecture**: Cloud-native Azure AKS

