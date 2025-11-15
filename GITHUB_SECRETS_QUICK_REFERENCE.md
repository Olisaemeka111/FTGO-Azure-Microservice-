# GitHub Secrets - Quick Reference

## Secrets to Add to GitHub

Go to: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

### Required Secrets

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AZURE_CREDENTIALS` | JSON from `azure-credentials.json` | Azure Service Principal for authentication |
| `ACR_USERNAME` | `acrgenticapp2932` | Azure Container Registry username |
| `ACR_PASSWORD` | `[Get from: az acr credential show --name acrgenticapp2932]` | Azure Container Registry password |

## Current Values

### ACR Credentials
- **Registry**: `acrgenticapp2932.azurecr.io`
- **Username**: `acrgenticapp2932`
- **Password**: `[Retrieve using: az acr credential show --name acrgenticapp2932 --query "passwords[0].value" -o tsv]`

### Azure Service Principal
- **File**: `azure-credentials.json`
- **Format**: JSON with `clientId`, `clientSecret`, `subscriptionId`, `tenantId`

## Quick Setup Steps

1. **Get Azure Credentials**:
   ```powershell
   # Already created - check azure-credentials.json
   Get-Content azure-credentials.json
   ```

2. **Add to GitHub**:
   - Repository: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-
   - Go to: Settings → Secrets → Actions
   - Add each secret listed above

3. **Verify**:
   - Push a change to trigger the workflow
   - Check Actions tab for build status

## AKS Access

**No separate secret needed!** AKS access is handled via Azure login using the service principal.

The service principal has:
- ✅ Contributor role on `rg-gentic-app`
- ✅ Access to ACR (via Azure login)
- ✅ Access to AKS (via Azure RBAC)

