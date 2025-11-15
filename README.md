# Azure AKS Architecture - FTGO Microservices Application

![Architecture](https://img.shields.io/badge/Architecture-Production--Ready-green) ![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-purple) ![Azure](https://img.shields.io/badge/Azure-AKS-blue) ![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-orange)

Complete Azure Kubernetes Service (AKS) infrastructure with CI/CD pipeline for deploying the FTGO microservices application.

## Architecture

- **Management Cluster**: AKS cluster for management and governance
- **Workload Cluster**: AKS cluster for application workloads (Linux + Windows nodes)
- **Azure Container Registry**: Private container registry for Docker images
- **CI/CD Pipeline**: GitHub Actions for automated builds, scans, and deployments
- **FTGO Application**: 7 microservices + 4 infrastructure services
- **Monitoring Stack**: Prometheus, Grafana, Jaeger, Loki, and observability tools

## Quick Start

### Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.5.0
- kubectl installed
- Access to Azure subscription

### Deploy Infrastructure

```powershell
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy
terraform apply
```

### Access Clusters

```powershell
# Get credentials for workload cluster
az aks get-credentials --resource-group rg-gentic-app --name gentic-app-workload

# Verify access
kubectl get nodes
```

## CI/CD Pipeline

### Status: Operational

The GitHub Actions workflow automatically:
- Runs code linting and quality checks
- Scans dependencies for vulnerabilities
- Builds Docker images on every push
- Scans container images for vulnerabilities (Trivy)
- Pushes images to Azure Container Registry
- Deploys to AKS cluster
- Deploys monitoring stack
- Outputs Load Balancer URLs

**Workflows**:
- `.github/workflows/build-and-push.yml` - Build, scan, and deploy
- `.github/workflows/security-scan.yml` - Security scanning (weekly + on push)

### Images Built

All images are available in ACR: `acrgenticapp2932.azurecr.io`

**Microservices (7):**
- ftgo-api-gateway
- ftgo-consumer-service
- ftgo-restaurant-service
- ftgo-order-service
- ftgo-kitchen-service
- ftgo-accounting-service
- ftgo-order-history-service

**Infrastructure (2):**
- dynamodblocal-init
- mysql

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete architecture documentation
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment guide
- **[AKS_DEPLOYMENT.md](AKS_DEPLOYMENT.md)** - AKS deployment guide
- **[CLUSTER_ACCESS.md](CLUSTER_ACCESS.md)** - Cluster access instructions
- **[SETUP_GITHUB_SECRETS.md](SETUP_GITHUB_SECRETS.md)** - CI/CD secrets setup
- **[CICD_SETUP.md](CICD_SETUP.md)** - CI/CD pipeline details
- **[FTGO_ANALYSIS.md](FTGO_ANALYSIS.md)** - FTGO application analysis
- **[FTGO_DEPLOYMENT_PLAN.md](FTGO_DEPLOYMENT_PLAN.md)** - Deployment plan
- **[MONITORING_SETUP.md](MONITORING_SETUP.md)** - Monitoring and observability setup
- **[SECURITY_SCANNING.md](SECURITY_SCANNING.md)** - Security scanning documentation
- **[SECURITY_BEST_PRACTICES_ANALYSIS.md](SECURITY_BEST_PRACTICES_ANALYSIS.md)** - Security analysis

## Configuration

### Terraform Variables

Edit `terraform.tfvars` to customize:
- Resource names
- Node counts
- VM sizes
- Network configuration

### GitHub Secrets

Required secrets for CI/CD:
- `AZURE_CREDENTIALS` - Azure Service Principal JSON
- `ACR_USERNAME` - ACR username
- `ACR_PASSWORD` - ACR password

See [SETUP_GITHUB_SECRETS.md](SETUP_GITHUB_SECRETS.md) for details.

## Repository Structure

```
.
├── .github/workflows/          # CI/CD workflows
│   ├── build-and-push.yml     # Build, scan, and deploy
│   └── security-scan.yml      # Security scanning
├── modules/                    # Terraform modules
│   ├── aks-management/        # Management cluster
│   ├── aks-workload/          # Workload cluster
│   ├── networking/            # Network resources
│   ├── storage/               # Storage accounts
│   └── ...
├── ftgo-application/          # FTGO microservices application
│   └── deployment/kubernetes/
│       ├── aks/              # AKS-specific manifests
│       ├── monitoring/       # Monitoring stack
│       └── stateful-services/ # Infrastructure services
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
└── terraform.tfvars          # Variable values
```

## Security

### Infrastructure Security
- **Secrets Management**: All secrets excluded from Git (`.gitignore`)
- **Service Principal**: Limited scope (resource group level only)
- **AKS RBAC**: Explicitly enabled with role-based access control
- **Private Container Registry**: ACR with private endpoints
- **Network Policies**: Calico network policies enabled and configured
- **OIDC Integration**: Enabled for secure workload identity

### Application Security
- **Security Context**: All pods run as non-root users with restricted capabilities
- **Read-Only Root Filesystem**: Enabled where possible to prevent tampering
- **Resource Limits**: CPU and memory limits on all containers
- **Health Checks**: Liveness and readiness probes on all services
- **Secrets Management**: Database credentials stored in Kubernetes Secrets
- **Image Security**: 
  - Images from private ACR only
  - Vulnerability scanning with Trivy in CI/CD
  - Always pull latest images for security patches

### CI/CD Security
- **Code Scanning**: Automated linting and quality checks
- **Dependency Scanning**: OWASP Dependency Check for vulnerabilities
- **Container Scanning**: Trivy scans all images before deployment
- **Infrastructure Scanning**: TFLint and Checkov for Terraform security
- **YAML Validation**: Automated YAML linting for Kubernetes manifests

### Network Security
- **Network Policies**: Pod-to-pod communication restricted by policies
- **Load Balancer**: Standard SKU with proper security configuration
- **Private Networking**: Services communicate within cluster network

## Monitoring and Observability

### Monitoring Stack (monitoring namespace)

**Metrics**:
- **Prometheus**: Metrics collection and alerting (LoadBalancer: port 80)
- **Node Exporter**: Node-level metrics (DaemonSet)
- **Kube State Metrics**: Kubernetes object metrics

**Visualization**:
- **Grafana**: Dashboards and visualization (LoadBalancer: port 80, admin/admin)

**Logging**:
- **Loki**: Log aggregation (10Gi storage)
- **Promtail**: Log collection agent (DaemonSet)

**Tracing**:
- **Jaeger**: Distributed tracing (LoadBalancer: port 80)

**Alerting**:
- **Alertmanager**: Alert routing and management

### Access URLs

After deployment, Load Balancer URLs are displayed in:
- GitHub Actions workflow summary
- Workflow logs

All monitoring tools are accessible via LoadBalancer services.

## Current Status

- Infrastructure deployed (Management + Workload clusters)
- ACR created and configured
- CI/CD pipeline operational with security scanning
- All images built, scanned, and pushed to ACR
- Application deployed to AKS (ftgo namespace)
- Monitoring stack deployed (monitoring namespace)
- Security best practices implemented
- Network policies configured
- Secrets management in place

## Support

For issues or questions:
1. Check documentation in `/docs`
2. Review GitHub Actions logs
3. Check Azure Portal for resource status

## License

See LICENSE file for details.
