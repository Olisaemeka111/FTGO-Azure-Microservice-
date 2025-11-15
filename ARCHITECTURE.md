# Architecture Documentation - Azure AKS on Azure Stack HCI

This document provides detailed architecture information for the Azure AKS on Azure Stack HCI deployment.

## Overview

This architecture implements a production-ready Azure Kubernetes Service (AKS) infrastructure on Azure Stack HCI, featuring:

- **Hybrid Cloud Architecture**: On-premises HCI infrastructure with Azure management
- **High Availability**: Redundant control planes and load balancers
- **Multi-Platform Support**: Both Linux and Windows container workloads
- **Azure Integration**: Azure Arc, Monitor, Policy, and Defender capabilities
- **Security**: Network isolation, RBAC, and encrypted communications

## Architecture Diagram Components

### 1. Windows Admin Center / Azure Arc

**Purpose**: Management and governance layer

**Components**:
- Windows Admin Center for GUI-based management
- Azure Arc for Azure Portal integration
- Centralized monitoring and policy enforcement

**Capabilities**:
- Cluster lifecycle management
- Application deployment
- Monitoring and diagnostics
- Policy compliance
- Security management

### 2. Management Cluster (AKS Host)

**Purpose**: Infrastructure management and control

**Architecture**:
```
┌─────────────────────────────────┐
│    Management Cluster           │
│  ┌─────────────────────────┐    │
│  │   Load Balancer         │    │
│  │   (Public IP)           │    │
│  └──────────┬──────────────┘    │
│             │                   │
│  ┌──────────▼──────────────┐    │
│  │   API Server            │    │
│  │   (Kubernetes Control)  │    │
│  └──────────┬──────────────┘    │
│             │                   │
│  ┌──────────▼──────────────┐    │
│  │   Worker VM             │    │
│  │   (System Services)     │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Specifications**:
- **Control Plane**: 1 node (scalable)
- **Worker Nodes**: 1+ VMs
- **VM Size**: Standard_D4s_v3 (default)
- **OS**: Linux
- **Purpose**: AKS infrastructure management

**Key Services**:
- Cluster API
- Lifecycle management
- Certificate management
- Authentication/Authorization

### 3. Workload Cluster

**Purpose**: Run production containerized applications

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
- **Control Plane**: 3 nodes (HA configuration)
- **Linux Node Pools**: 2 pools × 2 VMs = 4 VMs
- **Windows Node Pools**: 1 pool × 2 VMs = 2 VMs
- **Total Worker Nodes**: 6 VMs
- **VM Size**: Standard_D4s_v3 (configurable)

**High Availability Features**:
- Multi-node control plane
- Availability zone distribution
- Automatic failover
- Load balancer health probes

### 4. Azure Stack HCI Datacenter

**Purpose**: Physical infrastructure layer

**Architecture**:
```
┌──────────────────────────────────────────────────────────┐
│         Azure Stack HCI Datacenter                       │
│                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Physical    │  │ Physical    │  │ Physical    │ ... │
│  │ Host 1      │  │ Host 2      │  │ Host 3      │     │
│  │             │  │             │  │             │     │
│  │ - Hyper-V   │  │ - Hyper-V   │  │ - Hyper-V   │     │
│  │ - VMs       │  │ - VMs       │  │ - VMs       │     │
│  │ - Storage   │  │ - Storage   │  │ - Storage   │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│         └────────────────┴────────────────┘             │
│                          │                              │
│                  ┌───────▼────────┐                     │
│                  │  Shared Storage │                     │
│                  │  (Cluster Disk) │                     │
│                  │  - Volumes      │                     │
│                  │  - Snapshots    │                     │
│                  └─────────────────┘                     │
└──────────────────────────────────────────────────────────┘
```

**Components**:
- **Physical Hosts**: 4 servers (minimum 2 for HA)
- **Hypervisor**: Hyper-V on each host
- **Storage**: Storage Spaces Direct (S2D)
- **Networking**: SDN (Software Defined Networking)

**Specifications** (Minimum):
- **CPUs**: 32+ cores per host
- **Memory**: 128GB+ per host
- **Storage**: 4TB+ per host (NVMe/SSD)
- **Network**: 25Gbps+ network adapters

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
│  │  - StatefulSets                     │    │
│  │  - Database Storage                 │    │
│  │  - Application Data                 │    │
│  └──────────────┬──────────────────────┘    │
│                 │                           │
│  ┌──────────────▼──────────────────────┐    │
│  │  Persistent Volumes (PVs)           │    │
│  │  - CSI Drivers (NFS/SMB)            │    │
│  │  - Dynamic Provisioning             │    │
│  └──────────────┬──────────────────────┘    │
│                 │                           │
│  ┌──────────────▼──────────────────────┐    │
│  │  Storage Classes                    │    │
│  │  - Standard                         │    │
│  │  - Premium                          │    │
│  └──────────────┬──────────────────────┘    │
└─────────────────┼───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│     Azure Storage Account                   │
│  ┌─────────────────────────────────────┐    │
│  │  Blob Storage                       │    │
│  │  - cluster-data container           │    │
│  │  - backups container                │    │
│  │  - logs container                   │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │  File Shares                        │    │
│  │  - cluster-data (100GB)             │    │
│  │  - backups (500GB)                  │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│     Azure Stack HCI Storage                 │
│  ┌─────────────────────────────────────┐    │
│  │  Storage Spaces Direct (S2D)        │    │
│  │  - NVMe/SSD Cache Tier              │    │
│  │  - HDD/SSD Capacity Tier            │    │
│  │  - 3-way Mirror or Parity           │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Storage Features

- **CSI Drivers**: NFS and SMB support
- **Dynamic Provisioning**: Automatic PV creation
- **Versioning**: Blob versioning enabled
- **Retention**: 7-day soft delete
- **Security**: HTTPS-only, TLS 1.2+
- **Redundancy**: LRS (locally redundant)

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

### Monitoring Stack

```
┌──────────────────────────────────────────────┐
│  Azure Monitor (Central)                     │
│  - Metrics                                   │
│  - Logs                                      │
│  - Alerts                                    │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Container Insights                          │
│  - Node metrics                              │
│  - Pod metrics                               │
│  - Container logs                            │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Kubernetes Metrics                          │
│  - CPU/Memory usage                          │
│  - Network I/O                               │
│  - Storage I/O                               │
│  - API server metrics                        │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│  Application Metrics                         │
│  - Custom metrics                            │
│  - APM traces                                │
│  - Error rates                               │
└──────────────────────────────────────────────┘
```

### Key Metrics

- **Cluster Health**: Node status, pod status
- **Resource Utilization**: CPU, memory, storage
- **Application Performance**: Response time, throughput
- **Network**: Bandwidth, latency, errors
- **Security**: Failed authentications, policy violations

## Cost Optimization

### Cost Breakdown

1. **Azure Stack HCI Licensing**
   - Per core licensing
   - Azure billing for Arc services

2. **Azure Services**
   - Storage account
   - Load balancers
   - Public IPs
   - Arc-enabled services

3. **Operational Costs**
   - Power and cooling
   - Maintenance
   - Support

### Optimization Strategies

- Use smaller VM sizes for non-production
- Reduce node counts in development
- Use Basic load balancer for test environments
- Disable optional Arc services when not needed
- Leverage Azure Hybrid Benefit

## References

- [Azure Stack HCI Documentation](https://docs.microsoft.com/azure-stack/hci/)
- [AKS Hybrid Overview](https://docs.microsoft.com/azure/aks/hybrid/)
- [Azure Arc-enabled Kubernetes](https://docs.microsoft.com/azure/azure-arc/kubernetes/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico Network Policy](https://docs.projectcalico.org/)

---

**Last Updated**: Based on Terraform module v1.0.0  
**Target Kubernetes Version**: 1.28.3  
**Target Azure Stack HCI Version**: 23H2

