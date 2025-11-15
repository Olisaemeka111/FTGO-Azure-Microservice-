# Build and Push FTGO Images to Azure Container Registry
# This script builds all FTGO microservices and pushes them to ACR

param(
    [string]$ACRName = "acrgenticapp2932",
    [string]$ResourceGroup = "rg-gentic-app",
    [string]$ImageTag = "latest",
    [switch]$BuildOnly = $false,
    [switch]$PushOnly = $false
)

$ErrorActionPreference = "Stop"

# ACR Configuration
$ACRRegistry = "$ACRName.azurecr.io"
$FTGOPath = Join-Path $PSScriptRoot "ftgo-application"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "FTGO Image Build and Push Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "ACR Name: $ACRName" -ForegroundColor Yellow
Write-Host "ACR Registry: $ACRRegistry" -ForegroundColor Yellow
Write-Host "Image Tag: $ImageTag" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if ACR exists
Write-Host "Checking ACR..." -ForegroundColor Green
$acr = az acr show --name $ACRName --resource-group $ResourceGroup --query "loginServer" -o tsv 2>$null
if (-not $acr) {
    Write-Host "ERROR: ACR $ACRName not found!" -ForegroundColor Red
    exit 1
}

# Login to ACR
if (-not $PushOnly) {
    Write-Host "Logging in to ACR..." -ForegroundColor Green
    az acr login --name $ACRName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to login to ACR" -ForegroundColor Red
        exit 1
    }
}

# Check if FTGO application directory exists
if (-not (Test-Path $FTGOPath)) {
    Write-Host "ERROR: FTGO application directory not found at $FTGOPath" -ForegroundColor Red
    exit 1
}

# Services to build
$services = @(
    @{Name="ftgo-api-gateway"; Path="ftgo-api-gateway"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-consumer-service"; Path="ftgo-consumer-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-restaurant-service"; Path="ftgo-restaurant-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-order-service"; Path="ftgo-order-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-kitchen-service"; Path="ftgo-kitchen-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-accounting-service"; Path="ftgo-accounting-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"},
    @{Name="ftgo-order-history-service"; Path="ftgo-order-history-service"; BaseImage="eventuateio/eventuate-examples-docker-images-spring-example-base-image:BUILD-15"}
)

$infrastructure = @(
    @{Name="dynamodblocal-init"; Path="dynamodblocal-init"; BaseImage=$null},
    @{Name="mysql"; Path="mysql"; BaseImage=$null}
)

# Build Java services with Gradle
if (-not $PushOnly) {
    Write-Host "`nBuilding Java services with Gradle..." -ForegroundColor Green
    Push-Location $FTGOPath
    
    try {
        # Build all JARs
        Write-Host "Running Gradle build (this may take several minutes)..." -ForegroundColor Yellow
        & .\gradlew.bat clean build -x test
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Gradle build failed" -ForegroundColor Red
            exit 1
        }
        
        # Build individual service JARs
        $serviceModules = @(
            "ftgo-api-gateway",
            "ftgo-consumer-service",
            "ftgo-restaurant-service",
            "ftgo-order-service",
            "ftgo-kitchen-service",
            "ftgo-accounting-service",
            "ftgo-order-history-service"
        )
        
        foreach ($module in $serviceModules) {
            Write-Host "Building JAR for $module..." -ForegroundColor Yellow
            & .\gradlew.bat ":$module`:bootJar"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "WARNING: Failed to build $module" -ForegroundColor Yellow
            }
        }
    }
    finally {
        Pop-Location
    }
}

# Build and push service images
if (-not $PushOnly) {
    Write-Host "`nBuilding Docker images..." -ForegroundColor Green
    
    foreach ($service in $services) {
        $servicePath = Join-Path $FTGOPath $service.Path
        $imageName = "$ACRRegistry/$($service.Name):$ImageTag"
        
        Write-Host "`nBuilding $($service.Name)..." -ForegroundColor Cyan
        Write-Host "  Path: $servicePath" -ForegroundColor Gray
        Write-Host "  Image: $imageName" -ForegroundColor Gray
        
        Push-Location $servicePath
        
        try {
            if ($service.BaseImage) {
                docker build --build-arg baseImageVersion=BUILD-15 -t $imageName .
            } else {
                docker build -t $imageName .
            }
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "ERROR: Failed to build $($service.Name)" -ForegroundColor Red
                continue
            }
            
            Write-Host "  ✓ Built successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Exception building $($service.Name): $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    # Build infrastructure images
    foreach ($infra in $infrastructure) {
        $infraPath = Join-Path $FTGOPath $infra.Path
        $imageName = "$ACRRegistry/$($infra.Name):$ImageTag"
        
        Write-Host "`nBuilding $($infra.Name)..." -ForegroundColor Cyan
        Write-Host "  Path: $infraPath" -ForegroundColor Gray
        Write-Host "  Image: $imageName" -ForegroundColor Gray
        
        Push-Location $infraPath
        
        try {
            docker build -t $imageName .
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "ERROR: Failed to build $($infra.Name)" -ForegroundColor Red
                continue
            }
            
            Write-Host "  ✓ Built successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Exception building $($infra.Name): $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
}

# Push images to ACR
if (-not $BuildOnly) {
    Write-Host "`nPushing images to ACR..." -ForegroundColor Green
    
    $allImages = $services + $infrastructure
    
    foreach ($img in $allImages) {
        $imageName = "$ACRRegistry/$($img.Name):$ImageTag"
        
        Write-Host "Pushing $($img.Name)..." -ForegroundColor Cyan
        docker push $imageName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Failed to push $($img.Name)" -ForegroundColor Red
            continue
        }
        
        Write-Host "  ✓ Pushed successfully" -ForegroundColor Green
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Build and Push Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Registry: $ACRRegistry" -ForegroundColor Yellow
Write-Host "Tag: $ImageTag" -ForegroundColor Yellow
Write-Host "`nTo view images in ACR, run:" -ForegroundColor Cyan
Write-Host "  az acr repository list --name $ACRName --output table" -ForegroundColor White

