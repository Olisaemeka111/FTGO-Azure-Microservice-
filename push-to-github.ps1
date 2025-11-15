# Git Push Script for FTGO Azure Microservice Repository
# Run this script to push your code to GitHub

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Git Push to GitHub" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$repoPath = "C:\Users\olisa\OneDrive\Desktop\Azure AKS architecture"
$remoteUrl = "https://github.com/Olisaemeka111/FTGO-Azure-Microservice-.git"

# Find Git executable
$gitExe = $null
$gitPaths = @(
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe",
    "C:\Windows\System32\git.exe",
    (Get-Command git -ErrorAction SilentlyContinue).Source
)

foreach ($path in $gitPaths) {
    if ($path -and (Test-Path $path)) {
        $gitExe = $path
        break
    }
}

if (-not $gitExe) {
    Write-Host "ERROR: Git not found!" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Or use GitHub Desktop: https://desktop.github.com/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Git: $gitExe" -ForegroundColor Green
Write-Host ""

# Change to repository directory
Set-Location $repoPath

# Step 1: Initialize (if needed)
Write-Host "Step 1: Checking git repository..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    Write-Host "  Initializing git repository..." -ForegroundColor Gray
    & $gitExe init
} else {
    Write-Host "  ✓ Repository already initialized" -ForegroundColor Green
}

# Step 2: Add files
Write-Host "`nStep 2: Adding files..." -ForegroundColor Yellow
& $gitExe add .
Write-Host "  ✓ Files staged" -ForegroundColor Green

# Step 3: Check status
Write-Host "`nStep 3: Checking what will be committed..." -ForegroundColor Yellow
$status = & $gitExe status --short
if ($status) {
    Write-Host "  Files to commit:" -ForegroundColor Gray
    $status | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    if ($status.Count -gt 10) {
        Write-Host "    ... and $($status.Count - 10) more files" -ForegroundColor Gray
    }
} else {
    Write-Host "  No changes to commit" -ForegroundColor Yellow
}

# Step 4: Commit
Write-Host "`nStep 4: Committing files..." -ForegroundColor Yellow
$commitMsg = "first commit"
& $gitExe commit -m $commitMsg
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Committed successfully" -ForegroundColor Green
} else {
    Write-Host "  ⚠ No changes to commit or commit failed" -ForegroundColor Yellow
}

# Step 5: Set branch to main
Write-Host "`nStep 5: Setting branch to main..." -ForegroundColor Yellow
& $gitExe branch -M main
Write-Host "  ✓ Branch set to main" -ForegroundColor Green

# Step 6: Add remote
Write-Host "`nStep 6: Configuring remote..." -ForegroundColor Yellow
$remotes = & $gitExe remote -v
if ($remotes -match "origin") {
    Write-Host "  Remote 'origin' already exists" -ForegroundColor Yellow
    Write-Host "  Updating remote URL..." -ForegroundColor Gray
    & $gitExe remote set-url origin $remoteUrl
} else {
    Write-Host "  Adding remote 'origin'..." -ForegroundColor Gray
    & $gitExe remote add origin $remoteUrl
}
Write-Host "  ✓ Remote configured" -ForegroundColor Green

# Step 7: Push
Write-Host "`nStep 7: Pushing to GitHub..." -ForegroundColor Yellow
Write-Host "  Repository: $remoteUrl" -ForegroundColor Gray
Write-Host "  Branch: main" -ForegroundColor Gray
Write-Host ""
Write-Host "  ⚠ You may be prompted for GitHub credentials:" -ForegroundColor Yellow
Write-Host "     - Username: Your GitHub username" -ForegroundColor White
Write-Host "     - Password: Use a Personal Access Token (not your password)" -ForegroundColor White
Write-Host ""
Write-Host "  To create a token: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host ""

& $gitExe push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "✓ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository URL: $remoteUrl" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "✗ Push failed" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Authentication failed - Use Personal Access Token" -ForegroundColor White
    Write-Host "  2. Repository doesn't exist - Create it on GitHub first" -ForegroundColor White
    Write-Host "  3. No write permissions - Check repository access" -ForegroundColor White
    Write-Host ""
    Write-Host "See GIT_PUSH_INSTRUCTIONS.md for detailed help" -ForegroundColor Cyan
}

