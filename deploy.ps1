# Azure AKS on Azure Stack HCI - Deployment Script
# Run this script to deploy the infrastructure

# Function to show timestamped messages
function Write-TimestampedMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

# Function to run command with verbose output
function Invoke-VerboseCommand {
    param(
        [string]$Command,
        [string]$Description,
        [switch]$ShowOutput = $true
    )
    
    Write-TimestampedMessage "Starting: $Description" "Yellow"
    Write-Host ""
    
    if ($ShowOutput) {
        # Run command and show all output in real-time
        & $Command.Split(' ') | ForEach-Object {
            Write-Host $_ -NoNewline
        }
    } else {
        # Capture output but still show it
        $output = & $Command.Split(' ') 2>&1
        $output | ForEach-Object { Write-Host $_ }
    }
    
    Write-Host ""
    Write-TimestampedMessage "Completed: $Description" "Green"
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure AKS on Azure Stack HCI Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants verbose/debug logging
$verboseLogging = Read-Host "Enable verbose Terraform logging? (y/N)"
if ($verboseLogging -eq "y" -or $verboseLogging -eq "Y") {
    $env:TF_LOG = "DEBUG"
    $env:TF_LOG_PATH = "terraform-debug.log"
    Write-Host "[OK] Verbose logging enabled (TF_LOG=DEBUG)" -ForegroundColor Green
    Write-Host "   Log file: terraform-debug.log" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[INFO] Standard logging mode" -ForegroundColor Gray
    Write-Host ""
}

# Step 1: Check prerequisites
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow

# Check Terraform
$terraformCmd = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraformCmd) {
    Write-Host "[ERROR] Terraform not found in PATH. Please install Terraform >= 1.5.0" -ForegroundColor Red
    Write-Host "   Download from: https://www.terraform.io/downloads" -ForegroundColor Gray
    exit 1
}

try {
    $terraformVersion = & terraform version 2>&1
    if ($terraformVersion -match "Terraform v(\d+\.\d+)") {
        $version = $matches[1]
        Write-Host "[OK] Terraform found (v$version)" -ForegroundColor Green
    } else {
        Write-Host "[OK] Terraform found" -ForegroundColor Green
        Write-Host "   $($terraformVersion[0])" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARN] Terraform found but version check failed" -ForegroundColor Yellow
    Write-Host "   Continuing anyway..." -ForegroundColor Gray
}

# Check Azure CLI
$azCmd = Get-Command az -ErrorAction SilentlyContinue
if (-not $azCmd) {
    Write-Host "[ERROR] Azure CLI not found in PATH. Please install Azure CLI" -ForegroundColor Red
    Write-Host "   Install with: winget install Microsoft.AzureCLI" -ForegroundColor Gray
    exit 1
}

try {
    $azVersion = & az --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Azure CLI found but version check failed" -ForegroundColor Yellow
    Write-Host "   Continuing anyway..." -ForegroundColor Gray
}

# Check Azure login
try {
    $azAccount = & az account show 2>&1
    if ($azAccount -match "error" -or $azAccount -match "Please run 'az login'") {
        throw "Not logged in"
    }
    $accountJson = $azAccount | ConvertFrom-Json
    $subName = $accountJson.name
    $subId = $accountJson.id
    Write-Host "[OK] Logged into Azure" -ForegroundColor Green
    Write-Host "   Subscription: $subName" -ForegroundColor Gray
    Write-Host "   ID: $subId" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Not logged into Azure. Please run: az login" -ForegroundColor Red
    exit 1
}

# Check terraform.tfvars
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "[ERROR] terraform.tfvars not found. Please create it from terraform.tfvars.example" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] terraform.tfvars found" -ForegroundColor Green

# Check for placeholder values
$tfvarsContent = Get-Content "terraform.tfvars" -Raw
if ($tfvarsContent -match "00000000-0000-0000-0000-000000000000") {
    Write-Host "[WARN] WARNING: terraform.tfvars contains placeholder values!" -ForegroundColor Yellow
    Write-Host "   Please update subscription_id, azure_stack_hci_cluster_id, and aks_hci_extension_id" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Deployment cancelled. Please update terraform.tfvars first." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-TimestampedMessage "[2/5] Initializing Terraform..." "Yellow"
Write-Host "Running: terraform init -upgrade -input=false" -ForegroundColor Gray
Write-Host ""

# Run terraform init with verbose output
$initOutput = & terraform init -upgrade -input=false 2>&1
$initOutput | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-TimestampedMessage "[ERROR] Terraform initialization failed (Exit Code: $LASTEXITCODE)" "Red"
    exit 1
}
Write-TimestampedMessage "[OK] Terraform initialized successfully" "Green"

Write-Host ""
Write-TimestampedMessage "[3/5] Validating configuration..." "Yellow"
Write-Host "Running: terraform validate" -ForegroundColor Gray
Write-Host ""

# Run terraform validate with verbose output
$validateOutput = & terraform validate 2>&1
$validateOutput | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
    Write-TimestampedMessage "[ERROR] Configuration validation failed (Exit Code: $LASTEXITCODE)" "Red"
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "- Check terraform.tfvars has all required values" -ForegroundColor Gray
    Write-Host "- Verify variable types match" -ForegroundColor Gray
    Write-Host "- Check for syntax errors" -ForegroundColor Gray
    exit 1
}
Write-TimestampedMessage "[OK] Configuration is valid" "Green"

Write-Host ""
Write-TimestampedMessage "[4/5] Planning deployment..." "Yellow"
Write-Host "Running: terraform plan -out=tfplan -detailed-exitcode" -ForegroundColor Gray
Write-Host "This will show all resources that will be created..." -ForegroundColor Gray
Write-Host ""

# Run terraform plan with detailed output
$planOutput = & terraform plan -out=tfplan -detailed-exitcode 2>&1
$planOutput | ForEach-Object { Write-Host $_ }

$planExitCode = $LASTEXITCODE
if ($planExitCode -eq 1) {
    Write-TimestampedMessage "[ERROR] Terraform plan failed (Exit Code: $planExitCode)" "Red"
    exit 1
} elseif ($planExitCode -eq 2) {
    Write-TimestampedMessage "[INFO] Plan shows changes (Exit Code: $planExitCode - this is normal)" "Yellow"
} elseif ($planExitCode -eq 0) {
    Write-TimestampedMessage "[INFO] No changes detected (Exit Code: $planExitCode)" "Cyan"
} else {
    Write-TimestampedMessage "[OK] Plan completed (Exit Code: $planExitCode)" "Green"
}

Write-Host ""
Write-TimestampedMessage "[5/5] Ready to deploy!" "Yellow"
Write-Host ""
$confirm = Read-Host "Do you want to proceed with deployment? This will take 30-45 minutes. (yes/no)"
if ($confirm -eq "yes") {
    Write-Host ""
    Write-TimestampedMessage "[DEPLOY] Starting deployment..." "Cyan"
    Write-Host "Running: terraform apply tfplan" -ForegroundColor Gray
    Write-Host "This will take approximately 30-45 minutes..." -ForegroundColor Gray
    Write-Host "Watch the progress below..." -ForegroundColor Gray
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
    
    # Run terraform apply with verbose output in real-time
    $startTime = Get-Date
    
    Write-Host "Executing: terraform apply -auto-approve tfplan" -ForegroundColor DarkGray
    Write-Host ""
    
    # Run terraform apply - execute directly to avoid pipeline issues
    Write-Host "Executing terraform apply (this will show all output)..." -ForegroundColor Gray
    Write-Host ""
    
    # Find the correct terraform executable (avoid system32 stub)
    $terraformPaths = @(
        "C:\ProgramData\chocolatey\bin\terraform.exe",
        "C:\terraform_1.6.3_windows_amd64\terraform.exe",
        (Get-Command terraform -ErrorAction SilentlyContinue).Source
    )
    
    $terraformExe = $null
    foreach ($path in $terraformPaths) {
        if ($path -and (Test-Path $path)) {
            $terraformExe = $path
            break
        }
    }
    
    if (-not $terraformExe) {
        # Fallback to just 'terraform' if nothing found
        $terraformExe = "terraform"
    }
    
    Write-Host "Using Terraform: $terraformExe" -ForegroundColor DarkGray
    Write-Host ""
    
    # Execute terraform apply directly
    if ($terraformExe -like "*.exe") {
        # Use full path to executable
        & $terraformExe apply -auto-approve tfplan
    } else {
        # Use command name
        terraform apply -auto-approve tfplan
    }
    
    # Capture exit code
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq $null) {
        $exitCode = 0
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
    
    if ($exitCode -eq 0) {
        Write-TimestampedMessage "[SUCCESS] Deployment completed successfully!" "Green"
        Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Get kubeconfig: terraform output -raw workload_cluster_kubeconfig > workload-kubeconfig.yaml" -ForegroundColor Gray
        Write-Host "2. Set kubeconfig: `$env:KUBECONFIG = '.\workload-kubeconfig.yaml'" -ForegroundColor Gray
        Write-Host "3. Verify nodes: kubectl get nodes" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Getting cluster information..." -ForegroundColor Yellow
        & terraform output
    } else {
        Write-TimestampedMessage "[ERROR] Deployment failed (Exit Code: $exitCode)" "Red"
        Write-Host ""
        Write-Host "Check the error messages above for details." -ForegroundColor Yellow
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "- Subscription permissions" -ForegroundColor Gray
        Write-Host "- Resource group conflicts" -ForegroundColor Gray
        Write-Host "- HCI cluster not accessible" -ForegroundColor Gray
        Write-Host "- Network connectivity issues" -ForegroundColor Gray
    }
} else {
    Write-TimestampedMessage "Deployment cancelled by user" "Yellow"
}

