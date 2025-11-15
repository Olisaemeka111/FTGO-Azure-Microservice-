# Security Scanning and Linting

## Overview

The CI/CD pipeline includes comprehensive security scanning, linting, and vulnerability detection for both code and container images.

## Scanning Components

### 1. Code Quality & Linting

#### Gradle Checks
- **Location**: Build job, before Docker builds
- **Tools**: 
  - Gradle `check` task (compiles and runs tests)
  - Spotless (code formatting check)
- **Action**: Runs on every build

#### YAML Linting
- **Location**: Separate security-scan workflow
- **Tool**: yamllint
- **Scope**: All Kubernetes YAML files
- **Schedule**: On push/PR and weekly

### 2. Dependency Vulnerability Scanning

#### Gradle Dependencies
- **Location**: Build job
- **Tool**: OWASP Dependency Check (via Gradle plugin)
- **Output**: HTML report uploaded as artifact
- **Action**: Scans all Java dependencies for known vulnerabilities

### 3. Container Image Scanning

#### Trivy Scanner
- **Location**: After each Docker image build
- **Tool**: Aqua Security Trivy
- **Scans**:
  - OS packages
  - Application dependencies
  - Known CVEs
- **Severity**: CRITICAL and HIGH vulnerabilities
- **Output**: 
  - Table format in logs
  - SARIF format for GitHub Security tab
- **Action**: Scans all images before pushing to ACR

#### Images Scanned
- ftgo-api-gateway
- ftgo-consumer-service
- ftgo-restaurant-service
- ftgo-order-service
- ftgo-kitchen-service
- ftgo-accounting-service
- ftgo-order-history-service
- dynamodblocal-init
- mysql

### 4. Infrastructure as Code Scanning

#### Terraform Security
- **Location**: Separate security-scan workflow
- **Tools**:
  - **TFLint**: Terraform linting
  - **Checkov**: Security and compliance scanning
- **Scope**: All Terraform files
- **Output**: SARIF format for GitHub Security tab

## Workflow Structure

### Main Build Workflow (`build-and-push.yml`)
1. **Linting**: Code quality checks
2. **Dependency Scan**: Gradle dependencies
3. **Build**: Docker images
4. **Image Scan**: Trivy on each image
5. **Push**: Only if scans pass

### Security Scan Workflow (`security-scan.yml`)
1. **Code Scan**: Dependency vulnerability check
2. **Container Scan**: All images in ACR
3. **YAML Lint**: Kubernetes manifests
4. **Terraform Scan**: Infrastructure code

## Viewing Results

### GitHub Security Tab
1. Go to: Repository → **Security** tab
2. View:
   - Code scanning alerts
   - Dependency alerts
   - Container scanning results

### Workflow Artifacts
- Dependency check reports
- Scan results
- Available for 30 days

### Workflow Logs
- Trivy scan results in table format
- Linting errors and warnings
- Security findings

## Severity Levels

### CRITICAL
- Immediate action required
- May block deployment (configurable)

### HIGH
- Should be addressed soon
- May block deployment (configurable)

### MEDIUM/LOW
- Informational
- Not blocking by default

## Configuration

### Trivy Configuration
- **Exit Code**: `0` (non-blocking) for warnings
- **Severity**: CRITICAL, HIGH
- **Format**: Table (logs) + SARIF (GitHub Security)

### Dependency Check
- **Tool**: OWASP Dependency Check
- **Report**: HTML format
- **Location**: `build/reports/dependency-check-report.html`

### Linting
- **YAML**: yamllint with custom rules
- **Terraform**: TFLint + Checkov
- **Java**: Gradle check tasks

## Best Practices

### Before Deployment
1. Review all security scan results
2. Fix CRITICAL vulnerabilities
3. Address HIGH vulnerabilities
4. Review dependency reports

### Regular Maintenance
1. Weekly automated scans (scheduled)
2. Update dependencies regularly
3. Review and update base images
4. Monitor GitHub Security tab

### Remediation
1. **Container Images**: Update base images or dependencies
2. **Dependencies**: Update Gradle dependencies
3. **Code**: Fix linting issues
4. **Infrastructure**: Update Terraform configurations

## Suppressing False Positives

If you need to suppress false positives:

### Trivy
- Add `.trivyignore` file
- Or use `--ignore-unfixed` flag

### Dependency Check
- Configure in `dependency-check.gradle`
- Suppress specific CVEs if needed

## Integration with GitHub Security

All scan results are automatically:
- Uploaded to GitHub Security tab
- Available in Code Scanning alerts
- Tracked over time
- Included in security overview

## Summary

- **Code Linting**: Gradle checks + Spotless  
- **Dependency Scanning**: OWASP Dependency Check  
- **Container Scanning**: Trivy on all images  
- **Infrastructure Scanning**: TFLint + Checkov  
- **YAML Linting**: yamllint  
- **GitHub Integration**: Results in Security tab  

All scans run automatically on every push and PR!

