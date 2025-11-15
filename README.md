# Azure AKS Architecture - FTGO Microservices Application

![Architecture](https://img.shields.io/badge/Architecture-Production--Ready-green) ![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-purple) ![Azure](https://img.shields.io/badge/Azure-AKS-blue) ![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-orange)

Complete Azure Kubernetes Service (AKS) infrastructure with CI/CD pipeline for deploying the FTGO microservices application.

## 🏗️ Architecture

- **Management Cluster**: AKS cluster for management and governance
- **Workload Cluster**: AKS cluster for application workloads (Linux + Windows nodes)
- **Azure Container Registry**: Private container registry for Docker images
- **CI/CD Pipeline**: GitHub Actions for automated builds and deployments
- **FTGO Application**: 7 microservices + 4 infrastructure services

## 📋 Quick Start

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

## 🚀 CI/CD Pipeline

### Status: ✅ Operational

The GitHub Actions workflow automatically:
- Builds Docker images on every push
- Pushes images to Azure Container Registry
- Tags images with commit SHA and `latest`

**Workflow**: `.github/workflows/build-and-push.yml`

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

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Complete architecture documentation
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Deployment guide
- **[CLUSTER_ACCESS.md](CLUSTER_ACCESS.md)** - Cluster access instructions
- **[SETUP_GITHUB_SECRETS.md](SETUP_GITHUB_SECRETS.md)** - CI/CD secrets setup
- **[CICD_SETUP.md](CICD_SETUP.md)** - CI/CD pipeline details
- **[FTGO_ANALYSIS.md](FTGO_ANALYSIS.md)** - FTGO application analysis
- **[FTGO_DEPLOYMENT_PLAN.md](FTGO_DEPLOYMENT_PLAN.md)** - Deployment plan

## 🔧 Configuration

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

## 📦 Repository Structure

```
.
├── .github/workflows/          # CI/CD workflows
├── modules/                    # Terraform modules
│   ├── aks-management/        # Management cluster
│   ├── aks-workload/          # Workload cluster
│   ├── networking/            # Network resources
│   ├── storage/               # Storage accounts
│   └── ...
├── ftgo-application/          # FTGO microservices application
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
└── terraform.tfvars          # Variable values
```

## 🔐 Security

- ✅ Secrets excluded from Git (`.gitignore`)
- ✅ Service Principal with limited scope
- ✅ AKS RBAC enabled
- ✅ Private container registry

## 🎯 Current Status

- ✅ Infrastructure deployed
- ✅ ACR created and configured
- ✅ CI/CD pipeline operational
- ✅ All images built and pushed
- ⏳ Ready for application deployment

## 📞 Support

For issues or questions:
1. Check documentation in `/docs`
2. Review GitHub Actions logs
3. Check Azure Portal for resource status

## 📄 License

See LICENSE file for details.
