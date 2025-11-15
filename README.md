# Azure Kubernetes Service (AKS) - Terraform Infrastructure Module

![Architecture](https://img.shields.io/badge/Architecture-Production--Ready-green) ![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-purple) ![Azure](https://img.shields.io/badge/Azure-AKS-blue)

This Terraform module deploys a complete, production-ready Azure Kubernetes Service (AKS) infrastructure on Azure cloud, providing enterprise-grade Kubernetes with cloud-native management capabilities. The solution uses standard Azure AKS clusters with no on-premises dependencies.

---

## 🏗️ Architecture Overview

This module implements the exact architecture from your diagram:

```
┌─────────────────────────────────────────────────────────────────┐
│         Windows Admin Center / Azure Arc                        │
│         (Centralized Management & Governance)                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
    ┌────────────────────┴────────────────────┐
    │                                         │
┌───▼──────────────────┐         ┌───────────▼──────────────────┐
│  Management Cluster  │         │    Workload Cluster          │
│     (AKS Host)       │         │                              │
│                      │         │  ┌────────────────────────┐  │
│  ┌────────────────┐  │         │  │   Load Balancer        │  │
│  │ Load Balancer  │  │         │  └──────────┬─────────────┘  │
│  └────────┬───────┘  │         │             │                │
│           │          │         │  ┌──────────▼─────────────┐  │
│  ┌────────▼───────┐  │         │  │   API Server           │  │
│  │  API Server    │  │         │  └──────────┬─────────────┘  │
│  └────────┬───────┘  │         │             │                │
│           │          │         │  ┌──────────▼─────────────┐  │
│  ┌────────▼───────┐  │         │  │  Control plane (HA)    │  │
│  │      VM        │  │         │  │  3 Nodes - Zone Dist.  │  │
│  └────────────────┘  │         │  └──────────┬─────────────┘  │
│                      │         │             │                │
└──────────────────────┘         │  ┌──────────▼─────────────┐  │
                                 │  │    Pod    │    Pod     │  │
                                 │  │ ┌──────┐  │ ┌──────┐   │  │
                                 │  │ │Ctr 1 │  │ │Ctr 1 │   │  │
                                 │  │ │Ctr 2 │  │ │Ctr 2 │   │  │
                                 │  │ └──────┘  │ └──────┘   │  │
                                 │  └───────────────────────┘  │
                                 │             │                │
                                 │  ┌──────────▼─────────────┐  │
                                 │  │   Worker nodes         │  │
                                 │  │  ┌────┐ ┌────┐ ┌────┐  │  │
                                 │  │  │VM  │ │VM  │ │VM  │  │  │
                                 │  │  │Lin.│ │Lin.│ │Win.│  │  │
                                 │  │  └────┘ └────┘ └────┘  │  │
                                 │  └─────────────────────────┘  │
                                 └──────────────────────────────┘
                                             │
┌────────────────────────────────────────────▼──────────────────┐
│          Azure Cloud Infrastructure                           │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Azure Storage Account                                │   │
│  │  - Blob storage for container images                  │   │
│  │  - File shares for persistent volumes                 │   │
│  │  - Backup and log storage                             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Azure Virtual Network                                │   │
│  │  - Management subnet (10.0.1.0/24)                   │   │
│  │  - Workload subnet (10.0.2.0/24)                     │   │
│  │  - Network Security Groups                            │   │
│  │  - Load Balancers (Standard SKU)                      │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

## 📋 Infrastructure Components

### 1️⃣ **Windows Admin Center / Azure Arc** (Management Layer)
**Purpose**: Centralized management, monitoring, and governance

**Provides**:
- 🖥️ **Windows Admin Center**: GUI-based cluster management
- ☁️ **Azure Arc Integration**: Manage from Azure Portal
- 📊 **Unified Monitoring**: Azure Monitor for containers
- 🔒 **Policy Enforcement**: Azure Policy for Kubernetes
- 🛡️ **Security**: Azure Defender for threat protection

**Module**: `modules/azure-arc/`

---

### 2️⃣ **Management Cluster (AKS Host)**
**Purpose**: Manages the AKS infrastructure and lifecycle operations

```
Management Cluster
├── Load Balancer (Standard SKU)
│   ├── Public IP address
│   ├── Frontend configuration
│   └── Backend pool
├── API Server
│   ├── Kubernetes API endpoint
│   ├── Authentication/Authorization
│   └── Certificate management
└── Worker VM
    ├── System services
    ├── Cluster operations
    └── Infrastructure management
```

**Specifications**:
- **Control Plane**: 1 node (scalable to 3 for HA)
- **Worker Nodes**: 1+ VMs (Linux)
- **VM Size**: Standard_D4s_v3 (configurable)
- **Load Balancer**: Standard SKU with public IP
- **Network**: Dedicated management subnet (10.0.1.0/24)

**Module**: `modules/aks-management/`

---

### 3️⃣ **Workload Cluster** (Production Kubernetes)
**Purpose**: Runs your containerized applications and workloads

```
Workload Cluster
├── Load Balancer (Standard SKU)
│   ├── Public IP address
│   ├── Health probes (HTTP/HTTPS/API)
│   └── Load balancing rules
├── API Server
│   ├── Kubernetes API endpoint
│   ├── RBAC configuration
│   └── Admission controllers
├── Control Plane (High Availability)
│   ├── Node 1 (Zone 1) - etcd, controller-manager, scheduler
│   ├── Node 2 (Zone 2) - etcd, controller-manager, scheduler
│   └── Node 3 (Zone 3) - etcd, controller-manager, scheduler
├── Pods & Containers
│   ├── Pod orchestration
│   ├── Container runtime
│   ├── Service mesh integration
│   └── Network policies (Calico)
└── Worker Nodes
    ├── Linux Node Pools
    │   ├── Pool 1: 2 VMs (Standard_D4s_v3)
    │   └── Pool 2: 2 VMs (Standard_D4s_v3)
    └── Windows Node Pools
        └── Pool 1: 2 VMs (Standard_D4s_v3)
```

**Specifications**:
- **Control Plane**: 3 nodes (HA across availability zones)
- **Linux Workers**: 4 VMs (2 pools × 2 nodes)
- **Windows Workers**: 2 VMs (1 pool × 2 nodes)
- **Total Worker Nodes**: 6 VMs
- **Pod Network**: 10.244.0.0/16 (Calico CNI)
- **Service Network**: 10.96.0.0/16
- **Load Balancer**: Standard SKU with autoscaling

**Supports**:
- ✅ Linux containers (Docker, containerd)
- ✅ Windows containers (Windows Server 2022)
- ✅ Multi-OS workloads simultaneously
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ Cluster Autoscaler

**Module**: `modules/aks-workload/`

---

### 4️⃣ **Azure Cloud Storage & Networking** (Infrastructure Layer)
**Purpose**: Provides compute, storage, and networking resources

```
Azure Stack HCI Datacenter
├── Physical Hosts (4+ servers)
│   ├── Host 1: Hyper-V + VMs + Storage
│   ├── Host 2: Hyper-V + VMs + Storage
│   ├── Host 3: Hyper-V + VMs + Storage
│   └── Host 4: Hyper-V + VMs + Storage
├── Hypervisor
│   ├── Hyper-V (Windows Server)
│   ├── VM management
│   └── Live migration
├── Storage Layer
│   ├── Storage Spaces Direct (S2D)
│   ├── 3-way mirror / Parity
│   ├── NVMe/SSD cache tier
│   └── HDD/SSD capacity tier
└── Network Fabric
    ├── SDN (Software Defined Networking)
    ├── 25Gbps+ network adapters
    └── RDMA support
```

**Minimum Specifications** (per host):
- **CPU**: 32+ cores (Intel Xeon or AMD EPYC)
- **Memory**: 128GB+ RAM
- **Storage**: 4TB+ (NVMe/SSD preferred)
- **Network**: 25Gbps+ network adapters
- **OS**: Windows Server 2022

**Features**:
- Hyperconverged infrastructure
- Software-defined storage and networking
- High availability and failover
- Live migration of VMs
- Cluster-aware updating

**Configuration**: Pre-existing infrastructure (not managed by this module)

---

### 5️⃣ **Networking** (Virtual Network Infrastructure)
**Purpose**: Network isolation, security, and connectivity

```
Virtual Network (10.0.0.0/16)
├── Management Subnet (10.0.1.0/24)
│   ├── Management cluster VMs
│   ├── Management load balancer
│   └── NSG: API (6443), HTTPS (443), SSH (22)
├── Workload Subnet (10.0.2.0/24)
│   ├── Workload cluster VMs
│   ├── Workload load balancer
│   └── NSG: HTTP (80), HTTPS (443), API (6443), NodePorts (30000-32767)
├── Pod Network (10.244.0.0/16)
│   ├── Calico CNI
│   ├── Network policies
│   └── Pod-to-pod communication
└── Service Network (10.96.0.0/16)
    ├── ClusterIP services
    ├── NodePort services
    └── LoadBalancer services
```

**Load Balancers**:
- **Management LB**: API server access, management traffic
- **Workload LB**: Application traffic, ingress

**Security**:
- Network Security Groups (NSGs) per subnet
- Service endpoints for Azure services
- Network policies within Kubernetes
- DDoS protection (Standard LB)

**Module**: `modules/networking/` and `modules/load-balancer/`

---

### 6️⃣ **Storage** (Persistent Data Layer)
**Purpose**: Persistent storage for applications and cluster data

```
Storage Architecture
├── Azure Storage Account
│   ├── Blob Storage
│   │   ├── cluster-data container
│   │   ├── backups container
│   │   └── logs container
│   └── File Shares
│       ├── cluster-data (100GB)
│       └── backups (500GB)
├── Kubernetes Storage
│   ├── Storage Classes
│   │   ├── Standard (HDD)
│   │   └── Premium (SSD)
│   ├── Persistent Volumes (PVs)
│   ├── Persistent Volume Claims (PVCs)
│   └── CSI Drivers
│       ├── NFS CSI Driver
│       └── SMB CSI Driver
└── Azure Stack HCI Storage
    ├── Storage Spaces Direct (S2D)
    ├── Cluster Shared Volumes (CSV)
    └── Snapshots and replication
```

**Features**:
- ✅ Blob versioning enabled
- ✅ 7-day soft delete retention
- ✅ HTTPS-only access (TLS 1.2+)
- ✅ Encryption at rest
- ✅ Dynamic provisioning
- ✅ Snapshot support

**Module**: `modules/storage/`

---

### 7️⃣ **Auto Scaling** (Automatic Resource Management)
**Purpose**: Automatically scale pods and nodes based on demand

```
Auto Scaling Components
├── Metrics Server
│   ├── Collects CPU/memory metrics
│   ├── Provides metrics API
│   └── Enables HPA
├── Horizontal Pod Autoscaler (HPA)
│   ├── CPU-based scaling
│   ├── Memory-based scaling
│   ├── Custom metrics support
│   └── Scale up/down policies
├── Cluster Autoscaler
│   ├── Monitors pending pods
│   ├── Adds nodes when needed
│   ├── Removes underutilized nodes
│   └── Respects min/max limits
└── KEDA (Optional)
    ├── Event-driven scaling
    ├── External metrics
    ├── Scale to zero
    └── Multiple scalers
```

**Configuration**:
- **Min Nodes per Pool**: 1-3 (configurable)
- **Max Nodes per Pool**: 10-50 (configurable)
- **Scale Down Threshold**: 50% utilization (configurable)
- **Scale Down Delay**: 10 minutes (configurable)

**Module**: `modules/autoscaling/`

---

## 📁 Module Structure

```
Azure AKS architecture/
│
├── 📄 main.tf                          # Main Terraform configuration
├── 📄 variables.tf                     # Input variables (all configurable)
├── 📄 outputs.tf                       # Output values
├── 📄 versions.tf                      # Provider version constraints
├── 📄 terraform.tfvars.example         # Example configuration
├── 📄 .gitignore                       # Git ignore rules
│
├── 📚 Documentation/
│   ├── 📘 README.md                    # This file
│   ├── 📗 QUICKSTART.md                # 5-minute deployment guide
│   ├── 📙 DEPLOYMENT.md                # Detailed step-by-step deployment
│   ├── 📕 ARCHITECTURE.md              # In-depth architecture documentation
│   ├── 📔 AUTOSCALING.md               # Complete auto scaling guide
│   ├── 📓 AUTOSCALING_QUICKSTART.md    # 5-minute autoscaling setup
│   └── 📒 SUMMARY.md                   # Complete module summary
│
└── 🗂️ modules/                         # Reusable Terraform modules
    │
    ├── 📦 networking/                  # Virtual network infrastructure
    │   ├── main.tf                     # VNet, subnets, NSGs
    │   ├── variables.tf                # Network variables
    │   └── outputs.tf                  # Network outputs
    │
    ├── 📦 aks-management/              # Management cluster (AKS Host)
    │   ├── main.tf                     # Connected cluster, API server
    │   ├── variables.tf                # Management cluster variables
    │   └── outputs.tf                  # Cluster endpoints, kubeconfig
    │
    ├── 📦 aks-workload/                # Workload cluster (Production)
    │   ├── main.tf                     # HA cluster, node pools
    │   ├── variables.tf                # Workload cluster variables
    │   └── outputs.tf                  # Cluster info, node pools
    │
    ├── 📦 load-balancer/               # Azure Load Balancers
    │   ├── main.tf                     # LB, rules, health probes
    │   ├── variables.tf                # Load balancer variables
    │   └── outputs.tf                  # Frontend IPs, backend pools
    │
    ├── 📦 storage/                     # Storage infrastructure
    │   ├── main.tf                     # Storage account, containers
    │   ├── variables.tf                # Storage variables
    │   └── outputs.tf                  # Storage endpoints, keys
    │
    ├── 📦 azure-arc/                   # Azure Arc integration
    │   ├── main.tf                     # Arc extensions, policies
    │   ├── variables.tf                # Arc configuration
    │   └── outputs.tf                  # Arc status
    │
    └── 📦 autoscaling/                 # Auto scaling configuration
        ├── main.tf                     # Metrics server, autoscaler
        ├── variables.tf                # Scaling parameters
        └── outputs.tf                  # Scaling status
```

---

## 🚀 Quick Start Guide

### Prerequisites Checklist

Before deploying, ensure you have:

- ✅ **Azure Subscription** with Owner or Contributor access
- ✅ **Azure Subscription** with appropriate permissions
- ✅ **Azure CLI** installed and configured
- ✅ **Terraform** 1.5+ installed
- ✅ **Terraform** >= 1.5.0 installed locally
- ✅ **Azure CLI** installed and authenticated (`az login`)
- ✅ **kubectl** installed (for cluster access)
- ✅ **Minimum HCI Capacity**:
  - 128GB+ RAM per host
  - 32+ CPU cores per host
  - 4TB+ storage per host

### 5-Step Deployment

#### Step 1: Get Azure Stack HCI Resource IDs

```bash
# Login to Azure
az login

# Get HCI cluster resource ID
az stack-hci cluster show \
  --name "YOUR_HCI_CLUSTER_NAME" \
  --resource-group "YOUR_HCI_RG" \
  --query id -o tsv

# Get AKS HCI extension resource ID
az k8s-extension show \
  --resource-group "YOUR_HCI_RG" \
  --cluster-name "YOUR_HCI_CLUSTER_NAME" \
  --cluster-type connectedClusters \
  --name "aks-hci-extension" \
  --query id -o tsv
```

Copy these IDs - you'll need them in the next step!

#### Step 2: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Minimum required configuration**:

```hcl
# Azure Configuration
subscription_id            = "YOUR-SUBSCRIPTION-ID"
azure_stack_hci_cluster_id = "PASTE-HCI-CLUSTER-ID-HERE"
aks_hci_extension_id       = "PASTE-EXTENSION-ID-HERE"

# Basic Settings (use defaults or customize)
resource_group_name = "rg-aks-hci-prod"
location            = "eastus"
kubernetes_version  = "1.28.3"

# Network Configuration (or use defaults)
vnet_address_space     = ["10.0.0.0/16"]
management_subnet_cidr = "10.0.1.0/24"
workload_subnet_cidr   = "10.0.2.0/24"
```

#### Step 3: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "~> 3.80"...
- Finding Azure/azapi versions matching "~> 1.10"...

Terraform has been successfully initialized!
```

#### Step 4: Plan and Review

```bash
# Generate execution plan
terraform plan -out=tfplan

# Review the plan - should show ~20-25 resources to create
```

#### Step 5: Deploy Infrastructure

```bash
# Apply the configuration
terraform apply tfplan
```

⏱️ **Deployment Time**: 30-45 minutes

Watch the deployment progress. Terraform will create all resources in the correct order with proper dependencies.

### Access Your Clusters

Once deployment completes:

```bash
# Get workload cluster kubeconfig
terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml

# Set environment variable
export KUBECONFIG=./workload-kubeconfig.yaml

# Verify cluster access
kubectl get nodes

# Expected output:
# NAME                STATUS   ROLES    AGE   VERSION
# linuxpool1-xxxxx    Ready    agent    10m   v1.28.3
# linuxpool1-yyyyy    Ready    agent    10m   v1.28.3
# linuxpool2-xxxxx    Ready    agent    10m   v1.28.3
# linuxpool2-yyyyy    Ready    agent    10m   v1.28.3
# winpool1-xxxxx      Ready    agent    10m   v1.28.3
# winpool1-yyyyy      Ready    agent    10m   v1.28.3

# Check cluster info
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces
```

---

## ⚙️ Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `subscription_id` | Azure subscription ID | `"00000000-0000-0000-0000-000000000000"` |
| `azure_stack_hci_cluster_id` | HCI cluster resource ID | `"/subscriptions/.../clusters/my-hci"` |
| `aks_hci_extension_id` | AKS extension resource ID | `"/subscriptions/.../extensions/aks-hci"` |

### Optional Variables (with defaults)

#### General Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Resource group name | `"rg-aks-hci-prod"` |
| `location` | Azure region | `"eastus"` |
| `kubernetes_version` | Kubernetes version | `"1.28.3"` |

#### Networking Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `vnet_address_space` | VNet address space | `["10.0.0.0/16"]` |
| `management_subnet_cidr` | Management subnet | `"10.0.1.0/24"` |
| `workload_subnet_cidr` | Workload subnet | `"10.0.2.0/24"` |

#### Cluster Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `management_cluster_name` | Management cluster name | `"aks-hci-management"` |
| `workload_cluster_name` | Workload cluster name | `"aks-hci-workload"` |
| `enable_control_plane_ha` | Enable HA control plane | `true` |
| `workload_control_plane_count` | Control plane nodes | `3` |

#### Node Pool Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `linux_node_pools` | Linux node pool config | 2 pools × 2 VMs |
| `windows_node_pools` | Windows node pool config | 1 pool × 2 VMs |
| `management_node_vm_size` | VM size | `"Standard_D4s_v3"` |

#### Auto Scaling Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_cluster_autoscaler` | Enable cluster autoscaler | `true` |
| `enable_metrics_server` | Enable metrics server | `true` |
| `linux_node_pool_min_count` | Min nodes per pool | `1` |
| `linux_node_pool_max_count` | Max nodes per pool | `10` |
| `scale_down_utilization_threshold` | Scale down threshold | `0.5` |

#### Azure Arc Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_azure_arc` | Enable Azure Arc | `true` |
| `enable_windows_admin_center` | Enable WAC integration | `true` |

See `variables.tf` for the complete list of 50+ configurable variables.

---

## 📤 Outputs

The module provides comprehensive outputs for accessing and managing your infrastructure:

### Cluster Outputs

| Output | Description |
|--------|-------------|
| `management_cluster_endpoint` | Management cluster API endpoint |
| `workload_cluster_endpoint` | Workload cluster API endpoint |
| `management_cluster_kubeconfig` | Management cluster kubeconfig (sensitive) |
| `workload_cluster_kubeconfig` | Workload cluster kubeconfig (sensitive) |

### Network Outputs

| Output | Description |
|--------|-------------|
| `vnet_id` | Virtual network ID |
| `management_subnet_id` | Management subnet ID |
| `workload_subnet_id` | Workload subnet ID |
| `management_load_balancer_ip` | Management LB public IP |
| `workload_load_balancer_ip` | Workload LB public IP |

### Storage Outputs

| Output | Description |
|--------|-------------|
| `storage_account_name` | Storage account name |
| `storage_account_id` | Storage account ID |
| `primary_blob_endpoint` | Blob storage endpoint |

### Auto Scaling Outputs

| Output | Description |
|--------|-------------|
| `autoscaling_enabled` | Auto scaling status |
| `autoscaling_configuration` | Complete scaling config |
| `node_pool_scaling_limits` | Min/max node limits |

### Summary Output

```bash
terraform output deployment_summary
```

Provides a complete summary of your deployment including:
- Resource group and location
- Cluster names and endpoints
- Load balancer IPs
- Storage account
- Enabled features (Arc, autoscaling, WAC)

---

## 🎯 Usage Examples

### Deploy Sample Linux Application

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:latest --replicas=3

# Expose as LoadBalancer service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Get external IP
kubectl get service nginx

# Once EXTERNAL-IP shows, access it in your browser
```

### Deploy Sample Windows Application

```yaml
# windows-iis.yaml
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
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 2Gi
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
```

```bash
kubectl apply -f windows-iis.yaml
kubectl get service iis-demo --watch
```

### Enable Auto Scaling

```bash
# Create HPA for CPU-based scaling
kubectl autoscale deployment nginx \
  --cpu-percent=70 \
  --min=3 \
  --max=10

# View HPA status
kubectl get hpa

# Watch it scale
kubectl get hpa nginx --watch
```

### Test Cluster Autoscaling

```bash
# Scale deployment beyond current capacity
kubectl scale deployment nginx --replicas=50

# Watch nodes being added automatically
kubectl get nodes --watch
```

---

## 🔐 Security Features

### Network Security

✅ **Network Isolation**
- Separate subnets for management and workload
- Network Security Groups (NSGs) with strict rules
- Service endpoints for Azure services
- Network policies within Kubernetes (Calico)

✅ **Traffic Control**
- DDoS protection (Standard LB)
- Load balancer security rules
- Pod-to-pod network policies
- Ingress/egress filtering

### Identity & Access

✅ **Authentication**
- Azure AD integration
- RBAC for cluster access
- Service accounts for applications
- Managed identities

✅ **Authorization**
- Kubernetes RBAC
- Azure RBAC for Arc
- Pod security policies
- Admission controllers

### Data Protection

✅ **Encryption**
- TLS for all API communication
- HTTPS-only storage access (TLS 1.2+)
- Secrets encrypted in etcd
- Encryption at rest for storage

✅ **Compliance**
- Azure Policy enforcement
- Security scanning (Defender)
- Audit logging
- Compliance reporting

---

## 📊 Monitoring & Management

### Azure Monitor Integration

When enabled, provides:
- **Container Insights**: CPU, memory, disk, network metrics
- **Log Analytics**: Centralized logging
- **Alerts**: Proactive notifications
- **Workbooks**: Custom dashboards
- **Live Logs**: Real-time log streaming

### Windows Admin Center

Access your clusters through WAC:
1. Open Windows Admin Center
2. Navigate to Azure Kubernetes Service
3. Select your cluster
4. Manage nodes, pods, services through GUI

### Azure Portal

Manage from Azure Portal:
1. Go to portal.azure.com
2. Navigate to Azure Arc → Kubernetes clusters
3. View metrics, logs, and configuration
4. Apply policies and view compliance

### kubectl Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Application monitoring
kubectl get pods --all-namespaces
kubectl top pods --all-namespaces
kubectl logs <pod-name>

# Events
kubectl get events --sort-by='.lastTimestamp'

# Autoscaling status
kubectl get hpa
kubectl describe hpa <hpa-name>
```

---

## 📈 Scalability

### Current Capacity (Default Configuration)

- **Control Plane**: 3 nodes (HA)
- **Worker Nodes**: 6 VMs (4 Linux + 2 Windows)
- **Total vCPUs**: 24 (6 nodes × 4 vCPUs)
- **Total RAM**: 96 GB (6 nodes × 16 GB)
- **Maximum Pods**: ~300 (50 per node × 6 nodes)

### With Auto Scaling Enabled

- **Minimum Nodes**: 2-3 per pool (configurable)
- **Maximum Nodes**: 10-50 per pool (configurable)
- **Maximum Capacity**: Limited by Azure Stack HCI resources
- **Scaling Time**: ~3-5 minutes to provision new nodes
- **Cost Optimization**: Automatic scale-down when underutilized

### Scaling Options

**Horizontal Scaling** (Add more nodes):
```hcl
# In terraform.tfvars
linux_node_pool_max_count = 20
windows_node_pool_max_count = 15
```

**Vertical Scaling** (Larger VMs):
```hcl
# In terraform.tfvars
linux_node_pools = [
  {
    name       = "linuxpool1"
    node_count = 3
    vm_size    = "Standard_D8s_v3"  # 8 vCPUs, 32 GB RAM
    os_type    = "Linux"
  }
]
```

**Add More Node Pools**:
```hcl
# In terraform.tfvars
linux_node_pools = [
  { name = "general", node_count = 3, vm_size = "Standard_D4s_v3", os_type = "Linux" },
  { name = "compute", node_count = 2, vm_size = "Standard_D8s_v3", os_type = "Linux" },
  { name = "memory", node_count = 2, vm_size = "Standard_E4s_v3", os_type = "Linux" }
]
```

---

## 💰 Cost Considerations

### Azure Stack HCI Costs (On-Premises)

- **Physical Hardware**: One-time capital expense
- **HCI Licensing**: ~$10/core/month (Azure billing)
- **Power & Cooling**: Data center operational costs
- **Maintenance**: IT staff and support contracts

### Azure Cloud Services Costs (Monthly Estimates)

| Service | Estimated Cost |
|---------|----------------|
| Storage Account (LRS, 1TB) | ~$20-30 |
| Load Balancers (2 Standard) | ~$20-40 |
| Public IPs (2) | ~$6-10 |
| Azure Arc Services | ~$10-30 |
| Azure Monitor (if enabled) | ~$20-50 |
| **Total Azure Services** | **~$76-160/month** |

*Costs vary by region, usage patterns, and features enabled*

### Cost Optimization Tips

1. **Right-size VMs**: Use appropriate VM sizes for workloads
2. **Auto Scaling**: Enable scale-down to reduce node count
3. **Reserved Capacity**: Consider Azure reservations for Arc
4. **Storage Lifecycle**: Use storage tiers and lifecycle policies
5. **Monitoring**: Track costs with Azure Cost Management
6. **Dev/Test**: Use smaller configurations for non-production

---

## 🔧 Maintenance & Updates

### Upgrading Kubernetes

```hcl
# Update kubernetes_version in terraform.tfvars
kubernetes_version = "1.29.0"
```

```bash
terraform plan
terraform apply
```

### Scaling Node Pools

```hcl
# Update node counts in terraform.tfvars
linux_node_pools = [
  {
    name       = "linuxpool1"
    node_count = 4  # Increased from 2
    vm_size    = "Standard_D4s_v3"
    os_type    = "Linux"
  }
]
```

```bash
terraform apply
```

### Adding Features

```hcl
# Enable additional features in terraform.tfvars
enable_keda = true
enable_monitoring = true
```

```bash
terraform apply
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: Custom location not found

```bash
# Verify HCI cluster registration
az stack-hci cluster show \
  --name "YOUR_CLUSTER" \
  --resource-group "YOUR_RG"

# Verify extension installation
az k8s-extension list \
  --resource-group "YOUR_RG" \
  --cluster-name "YOUR_CLUSTER" \
  --cluster-type connectedClusters
```

#### Issue: Terraform apply fails

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Check Azure activity log
az monitor activity-log list \
  --resource-group rg-aks-hci-prod \
  --max-events 50
```

#### Issue: Cannot connect to cluster

```bash
# Re-export kubeconfig
terraform output -raw workload_cluster_kubeconfig > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml

# Or use Azure CLI proxy
az connectedk8s proxy \
  --name $(terraform output -raw workload_cluster_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

#### Issue: HPA not working

```bash
# Check metrics server
kubectl get deployment metrics-server -n kube-system

# Verify pod has resource requests
kubectl describe pod <pod-name>

# Check HPA status
kubectl describe hpa <hpa-name>
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting procedures.

---

## 📚 Documentation

| Document | Purpose | Reading Time |
|----------|---------|--------------|
| **[README.md](README.md)** | This file - complete overview | 20 minutes |
| **[QUICKSTART.md](QUICKSTART.md)** | Fast 5-minute deployment guide | 5 minutes |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Detailed step-by-step deployment | 30 minutes |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | In-depth architecture details | 30 minutes |
| **[AUTOSCALING.md](AUTOSCALING.md)** | Complete auto scaling guide | 30 minutes |
| **[AUTOSCALING_QUICKSTART.md](AUTOSCALING_QUICKSTART.md)** | Quick autoscaling setup | 5 minutes |
| **[SUMMARY.md](SUMMARY.md)** | Executive summary | 10 minutes |

---

## 🎓 Best Practices

### 1. Resource Requests and Limits

Always define resource requests for HPA and scheduling:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Pod Disruption Budgets

Ensure availability during maintenance:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

### 3. Health Checks

Define liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
```

### 4. Use Labels and Annotations

Organize resources with labels:

```yaml
metadata:
  labels:
    app: myapp
    env: production
    tier: backend
    version: v1.2.0
```

### 5. Implement Network Policies

Control pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
```

### 6. Regular Backups

```bash
# Backup etcd regularly
# Backup persistent volumes
# Export Kubernetes manifests
kubectl get all --all-namespaces -o yaml > backup.yaml
```

### 7. Monitor and Alert

Set up alerts for:
- Node resource usage > 80%
- Pod restart count > 5
- Failed deployments
- Certificate expiration

---

## 🌟 Features Summary

### ✅ Infrastructure as Code
- Complete Terraform automation
- Modular, reusable components
- Version-controlled configuration
- Reproducible deployments

### ✅ High Availability
- 3-node control plane
- Zone-distributed nodes
- Load balanced API servers
- Automatic failover

### ✅ Multi-Platform Support
- Linux containers (Docker, containerd)
- Windows containers (Server 2022)
- Mixed workload support
- Platform-specific node pools

### ✅ Auto Scaling
- Horizontal Pod Autoscaler (HPA)
- Cluster Autoscaler
- Metrics Server integration
- KEDA for event-driven scaling

### ✅ Hybrid Cloud Management
- Azure Arc integration
- Windows Admin Center support
- Azure Portal management
- Unified monitoring and policies

### ✅ Security
- Network isolation and NSGs
- RBAC and Azure AD integration
- Encryption at rest and in transit
- Azure Policy and Defender

### ✅ Production Ready
- HA control plane
- Auto scaling
- Monitoring integration
- Backup and DR capabilities

---

## 🔄 Version History

### v1.1.0 (Current) - Auto Scaling Update
- ✨ Horizontal Pod Autoscaler (HPA) support
- ✨ Cluster Autoscaler for automatic node scaling
- ✨ Metrics Server deployment
- ✨ KEDA for event-driven autoscaling
- ✨ Comprehensive autoscaling documentation
- ✨ Updated README with complete architecture
- 🐛 Fixed resource group ID passing to modules
- 📚 Enhanced documentation suite

### v1.0.0 - Initial Release
- ✅ Management and workload clusters
- ✅ Azure Arc integration
- ✅ Windows Admin Center support
- ✅ Multi-platform node pools (Linux + Windows)
- ✅ Storage and networking configuration
- ✅ Complete documentation set

---

## 🤝 Support & Resources

### Official Documentation
- **Azure Stack HCI**: https://docs.microsoft.com/azure-stack/hci/
- **AKS Hybrid**: https://docs.microsoft.com/azure/aks/hybrid/
- **Azure Arc**: https://docs.microsoft.com/azure/azure-arc/
- **Kubernetes**: https://kubernetes.io/docs/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/

### Community Resources
- **Azure Stack HCI Community**: https://techcommunity.microsoft.com/t5/azure-stack-hci/bd-p/AzureStackHCI
- **Kubernetes Slack**: https://kubernetes.slack.com/
- **Terraform Registry**: https://registry.terraform.io/

---

## 📝 License

This Terraform module is provided as-is for deployment of Azure Kubernetes Service on Azure Stack HCI infrastructure.

---

## 🎉 Getting Started

Ready to deploy? Follow these steps:

1. ✅ **Prerequisites**: Verify you have all requirements
2. 📖 **Quick Start**: Follow the [QUICKSTART.md](QUICKSTART.md) guide
3. ⚙️ **Configure**: Copy and customize `terraform.tfvars`
4. 🚀 **Deploy**: Run `terraform apply`
5. 🎯 **Use**: Deploy your applications
6. 📊 **Monitor**: Track via Azure Portal or Windows Admin Center
7. 📈 **Scale**: Let auto scaling handle demand

---

**🚀 Deploy production-ready Kubernetes on Azure Stack HCI in 30-45 minutes!**

**Made with ❤️ for Azure Stack HCI and Kubernetes enthusiasts**
