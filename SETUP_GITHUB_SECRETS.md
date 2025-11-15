# Setup GitHub Secrets for CI/CD

## Step 1: Azure Service Principal Credentials

**File Created**: `azure-credentials-clean.json`

**Add to GitHub as**: `AZURE_CREDENTIALS`

**Value**: Copy the entire JSON from `azure-credentials-clean.json`

The JSON contains:
- `clientId`: Service Principal Application ID
- `clientSecret`: Service Principal Secret
- `subscriptionId`: Your Azure Subscription ID
- `tenantId`: Your Azure Tenant ID

## Step 2: ACR Credentials

### ACR_USERNAME
- **Secret Name**: `ACR_USERNAME`
- **Value**: `acrgenticapp2932`

### ACR_PASSWORD
- **Secret Name**: `ACR_PASSWORD`
- **Value**: Get using: `az acr credential show --name acrgenticapp2932 --query "passwords[0].value" -o tsv`

## Step 3: Add Secrets to GitHub

### Via Web Interface:

1. Go to: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-/settings/secrets/actions

2. Click **"New repository secret"** for each:

   **Secret 1: AZURE_CREDENTIALS**
   - Name: `AZURE_CREDENTIALS`
   - Value: Copy entire content from `azure-credentials-clean.json`
   - Click **Add secret**

   **Secret 2: ACR_USERNAME**
   - Name: `ACR_USERNAME`
   - Value: `acrgenticapp2932`
   - Click **Add secret**

   **Secret 3: ACR_PASSWORD**
   - Name: `ACR_PASSWORD`
   - Value: Get using: `az acr credential show --name acrgenticapp2932 --query "passwords[0].value" -o tsv`
   - Click **Add secret**

### Via GitHub CLI:

```bash
# Add Azure credentials
gh secret set AZURE_CREDENTIALS < azure-credentials-clean.json

# Add ACR credentials
gh secret set ACR_USERNAME --body "acrgenticapp2932"
# Get ACR password first, then add as secret
ACR_PASSWORD=$(az acr credential show --name acrgenticapp2932 --query "passwords[0].value" -o tsv)
gh secret set ACR_PASSWORD --body "$ACR_PASSWORD"
```

## Step 4: Verify Secrets

After adding, verify they exist (you won't see values):

1. Go to: Settings → Secrets and variables → Actions
2. You should see:
   - ✅ AZURE_CREDENTIALS
   - ✅ ACR_USERNAME
   - ✅ ACR_PASSWORD

## What These Secrets Do

### AZURE_CREDENTIALS
- Authenticates GitHub Actions with Azure
- Allows access to ACR and AKS
- Service Principal has Contributor role on resource group

### ACR_USERNAME & ACR_PASSWORD
- Authenticates Docker with Azure Container Registry
- Used to push built images to ACR
- Required for `docker push` commands

## AKS Access

**No separate secret needed!** 

AKS access is automatic because:
- Service Principal has Contributor role on resource group
- AKS cluster is in the same resource group
- Azure login handles AKS authentication

## Testing the Pipeline

After adding secrets:

1. Make a small change to trigger the workflow
2. Go to: Actions tab in GitHub
3. Watch the workflow run
4. Check if images are built and pushed to ACR

## Troubleshooting

### "Authentication failed"
- Verify JSON in `AZURE_CREDENTIALS` is valid
- Check no extra characters or line breaks
- Ensure all 4 fields are present: clientId, clientSecret, subscriptionId, tenantId

### "ACR login failed"
- Verify `ACR_USERNAME` matches ACR name exactly
- Check `ACR_PASSWORD` is correct (no extra spaces)
- Ensure ACR admin user is enabled

### "Permission denied"
- Service Principal needs Contributor role (already set)
- Check service principal exists: `az ad sp show --id <clientId>`

## Security Notes

⚠️ **Important**:
- Never commit these secrets to git (already in `.gitignore`)
- Rotate credentials periodically
- Use Azure Key Vault for production (advanced)
- Service Principal has limited scope (only resource group)

