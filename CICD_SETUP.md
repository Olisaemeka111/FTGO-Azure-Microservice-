# CI/CD Setup Guide for FTGO Application

## Overview

This guide covers the complete CI/CD setup for building container images and deploying the FTGO application to Azure Kubernetes Service (AKS).

## Components Created

### 1. Azure Container Registry (ACR)
- **Name**: `acrgenticapp2932`
- **Registry**: `acrgenticapp2932.azurecr.io`
- **Resource Group**: `rg-gentic-app`
- **Location**: `eastus`
- **SKU**: Basic
- **Status**: Created and configured

### 2. AKS Integration
- AKS cluster has been granted access to ACR
- No authentication needed when pulling images from ACR

### 3. CI/CD Pipeline

#### GitHub Actions Workflow
- **Location**: `ftgo-application/.github/workflows/build-and-push.yml`
- **Triggers**: 
  - Push to master/main branches
  - Pull requests
  - Manual workflow dispatch
- **Actions**:
  - Builds Java services with Gradle
  - Builds Docker images
  - Pushes images to ACR

#### Local Build Script
- **Location**: `build-ftgo-images.ps1`
- **Purpose**: Build and push images manually from local machine
- **Usage**: `.\build-ftgo-images.ps1`

## Setup Instructions

### Step 1: Configure GitHub Secrets

For the GitHub Actions workflow to work, you need to add Azure credentials as a secret:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:

**Secret Name**: `AZURE_CREDENTIALS`

**Secret Value** (JSON format):
```json
{
  "clientId": "<your-service-principal-client-id>",
  "clientSecret": "<your-service-principal-secret>",
  "subscriptionId": "657bf059-e3b7-401b-816d-367cac7b220a",
  "tenantId": "<your-azure-tenant-id>"
}
```

#### Create Service Principal (if needed):
```powershell
az ad sp create-for-rbac --name "ftgo-cicd-sp" --role contributor --scopes /subscriptions/657bf059-e3b7-401b-816d-367cac7b220a/resourceGroups/rg-gentic-app --sdk-auth
```

This command outputs the JSON you need for the `AZURE_CREDENTIALS` secret.

### Step 2: Update GitHub Actions Workflow

If your repository is not in the `ftgo-application` folder structure, update the workflow file paths accordingly.

### Step 3: Test Local Build (Optional)

Before pushing to GitHub, you can test building images locally:

```powershell
# Login to ACR
az acr login --name acrgenticapp2932

# Run build script
.\build-ftgo-images.ps1
```

### Step 4: Push to GitHub

Once `.gitignore` is in place and secrets are configured:

```powershell
cd ftgo-application
git add .
git commit -m "Add CI/CD pipeline for ACR"
git push origin main
```

## ACR Credentials

**Registry**: `acrgenticapp2932.azurecr.io`
**Username**: `acrgenticapp2932`
**Password**: `[REDACTED - Store in Azure Key Vault or secure location]`

To get the password:
```powershell
az acr credential show --name acrgenticapp2932 --query "passwords[0].value" -o tsv
```

**Note**: Store these credentials securely. Consider using Azure Key Vault for production.

## Images to be Built

The CI/CD pipeline will build and push the following images:

### Application Services
1. `ftgo-api-gateway`
2. `ftgo-consumer-service`
3. `ftgo-restaurant-service`
4. `ftgo-order-service`
5. `ftgo-kitchen-service`
6. `ftgo-accounting-service`
7. `ftgo-order-history-service`

### Infrastructure Services
8. `dynamodblocal-init`
9. `mysql`

## Viewing Images in ACR

```powershell
# List all repositories
az acr repository list --name acrgenticapp2932 --output table

# List tags for a specific image
az acr repository show-tags --name acrgenticapp2932 --repository ftgo-api-gateway --output table

# View all images
az acr repository list --name acrgenticapp2932 --output table
```

## Updating Kubernetes Manifests

After images are built, update the Kubernetes YAML files to use ACR images:

**Change from**:
```yaml
image: msapatterns/ftgo-api-gateway:latest
```

**Change to**:
```yaml
image: acrgenticapp2932.azurecr.io/ftgo-api-gateway:latest
```

## Troubleshooting

### GitHub Actions Fails
- Check that `AZURE_CREDENTIALS` secret is correctly set
- Verify service principal has correct permissions
- Check workflow logs for specific errors

### Local Build Fails
- Ensure Docker is running
- Verify ACR login: `az acr login --name acrgenticapp2932`
- Check Java and Gradle are installed
- Review build logs for specific errors

### Image Pull Errors in AKS
- Verify AKS has access to ACR (already configured)
- Check image names match exactly
- Verify image tags exist in ACR

## Next Steps

1. ACR created
2. AKS access configured
3. CI/CD pipeline created
4. Build script created
5. Configure GitHub secrets
6. Push code to GitHub
7. Trigger CI/CD pipeline
8. Update Kubernetes manifests with ACR images
9. Deploy to AKS

## Files Created

- `ftgo-application/.github/workflows/build-and-push.yml` - GitHub Actions workflow
- `build-ftgo-images.ps1` - Local build script
- `.gitignore` - Git ignore file
- `CICD_SETUP.md` - This documentation

