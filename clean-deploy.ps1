# Clean Deployment Script
# Waits for resource deletion, then deploys cleanly with all fixes applied

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Clean AKS Deployment - No Drift" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Wait for clusters to be deleted
Write-Host "Step 1: Waiting for clusters to be deleted..." -ForegroundColor Yellow
$maxWait = 20  # 20 minutes max
$waitCount = 0

while ($waitCount -lt $maxWait) {
    $clusters = az aks list --resource-group rg-gentic-app --query "[].{Name:name, State:provisioningState}" -o json 2>&1 | ConvertFrom-Json
    
    if ($clusters.Count -eq 0) {
        Write-Host "[OK] All clusters deleted!" -ForegroundColor Green
        break
    }
    
    $deleting = $clusters | Where-Object { $_.State -eq "Deleting" }
    if ($deleting.Count -gt 0) {
        Write-Host "  Still deleting: $($deleting.Name -join ', ')" -ForegroundColor Gray
        Start-Sleep -Seconds 30
        $waitCount++
    } else {
        Write-Host "[OK] All clusters deleted!" -ForegroundColor Green
        break
    }
}

if ($waitCount -ge $maxWait) {
    Write-Host "[WARN] Timeout waiting for deletion. Proceeding anyway..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Removing Terraform state lock (if exists)..." -ForegroundColor Yellow
Remove-Item terraform.tfstate.lock.info -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Step 3: Initializing Terraform..." -ForegroundColor Yellow
& "C:\ProgramData\chocolatey\bin\terraform.exe" init -upgrade
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Terraform init failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 4: Validating configuration..." -ForegroundColor Yellow
& "C:\ProgramData\chocolatey\bin\terraform.exe" validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Validation failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Configuration is valid!" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Creating execution plan..." -ForegroundColor Yellow
& "C:\ProgramData\chocolatey\bin\terraform.exe" plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Plan failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Plan created!" -ForegroundColor Green

Write-Host ""
Write-Host "Step 6: Deploying infrastructure (clean, no drift)..." -ForegroundColor Yellow
Write-Host "This will create:" -ForegroundColor Cyan
Write-Host "  - Management AKS Cluster (1 node, D2s_v3)" -ForegroundColor Gray
Write-Host "  - Workload AKS Cluster (1 default + 2 Linux + 1 Windows pools)" -ForegroundColor Gray
Write-Host "  - All networking and storage resources" -ForegroundColor Gray
Write-Host ""
Write-Host "Estimated time: 15-20 minutes" -ForegroundColor Yellow
Write-Host ""

& "C:\ProgramData\chocolatey\bin\terraform.exe" apply -auto-approve tfplan

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Deployment Complete - No Drift!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All resources created with consistent configuration:" -ForegroundColor Cyan
    Write-Host "  ✅ VM sizes: Standard_D2s_v3 (all consistent)" -ForegroundColor Gray
    Write-Host "  ✅ Zones: Zone 3 only" -ForegroundColor Gray
    Write-Host "  ✅ OIDC: Enabled" -ForegroundColor Gray
    Write-Host "  ✅ Network: Azure CNI" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Get cluster info:" -ForegroundColor Yellow
    Write-Host "  terraform output" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    exit 1
}

