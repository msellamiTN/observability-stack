# ============================================
# Payment API v2.0.0 - OpenShift Deployment
# ============================================
# Uses existing manifests from atelier-06
# ============================================

param(
    [string]$Namespace = $env:NAMESPACE,
    [switch]$BuildImage,
    [switch]$CleanFirst
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Header { Write-Host "`n=== $args ===" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Yellow }

Write-Header "Payment API v2.0.0 - OpenShift Deployment"

# Check OpenShift connection
Write-Info "Checking OpenShift connection..."
try {
    $currentProject = oc project -q 2>$null
    Write-Success "Connected to OpenShift. Current project: $currentProject"
    
    if ([string]::IsNullOrEmpty($Namespace)) {
        $Namespace = $currentProject
        Write-Info "Using current namespace: $Namespace"
    }
} catch {
    Write-Error "Not logged in to OpenShift. Please run: oc login"
    exit 1
}

# Set namespace
oc project $Namespace | Out-Null

# Clean up if requested
if ($CleanFirst) {
    Write-Header "Cleaning up existing resources"
    
    Write-Info "Deleting existing payment-api resources..."
    oc delete deployment payment-api --ignore-not-found=true
    oc delete service payment-api --ignore-not-found=true
    oc delete route payment-api --ignore-not-found=true
    oc delete configmap promtail-sidecar-config --ignore-not-found=true
    
    Write-Info "Waiting for cleanup..."
    Start-Sleep -Seconds 5
    
    Write-Success "Cleanup completed"
}

# Build and push image if requested
if ($BuildImage) {
    Write-Header "Building Docker Image"
    
    Write-Info "Building payment-api-instrumented:2.0.0..."
    docker build -t payment-api-instrumented:2.0.0 .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    
    Write-Success "Docker image built successfully"
    
    # Tag and push to OpenShift registry
    Write-Info "Tagging image for OpenShift registry..."
    $registryUrl = "image-registry.openshift-image-registry.svc:5000"
    $imageTag = "${registryUrl}/${Namespace}/payment-api-instrumented:2.0.0"
    
    docker tag payment-api-instrumented:2.0.0 $imageTag
    
    Write-Info "Logging in to OpenShift registry..."
    $token = oc whoami -t
    docker login -u $(oc whoami) -p $token $registryUrl 2>$null
    
    Write-Info "Pushing image to OpenShift registry..."
    docker push $imageTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed"
        exit 1
    }
    
    Write-Success "Image pushed to OpenShift registry"
}

# Apply environment variables to manifests
Write-Header "Preparing Manifests"

$manifestsDir = "..\manifests\payment-api"
$tempDir = ".\temp-manifests"

# Create temp directory
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy and replace variables
Write-Info "Processing manifests..."
Get-ChildItem $manifestsDir -Filter *.yaml | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace '\$\{NAMESPACE\}', $Namespace
    $content = $content -replace '\$\{APP_CPU_REQUEST\}', '100m'
    $content = $content -replace '\$\{APP_MEMORY_REQUEST\}', '256Mi'
    $content = $content -replace '\$\{APP_CPU_LIMIT\}', '500m'
    $content = $content -replace '\$\{APP_MEMORY_LIMIT\}', '512Mi'
    $content = $content -replace '\$\{TLS_TERMINATION\}', 'edge'
    $content = $content -replace '\$\{ENVIRONMENT\}', 'production'
    
    $outputFile = Join-Path $tempDir $_.Name
    $content | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Info "  Processed: $($_.Name)"
}

Write-Success "Manifests prepared"

# Deploy resources
Write-Header "Deploying Resources"

Write-Info "Creating Promtail ConfigMap..."
oc apply -f "$tempDir\configmap-promtail-sidecar.yaml"

Write-Info "Creating Service..."
oc apply -f "$tempDir\service-payment-api.yaml"

Write-Info "Creating Route..."
oc apply -f "$tempDir\route-payment-api.yaml"

Write-Info "Creating Deployment..."
oc apply -f "$tempDir\deployment-payment-api-with-sidecar.yaml"

Write-Success "Resources deployed"

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

# Wait for deployment
Write-Header "Waiting for Deployment"

Write-Info "Waiting for pods to be ready (timeout: 120s)..."
$timeout = 120
$elapsed = 0
$ready = $false

while ($elapsed -lt $timeout) {
    $pods = oc get pods -l app=payment-api -o json 2>$null | ConvertFrom-Json
    
    if ($pods.items.Count -gt 0) {
        $runningPods = $pods.items | Where-Object { $_.status.phase -eq "Running" }
        $readyPods = $runningPods | Where-Object {
            $_.status.containerStatuses.Count -eq 2 -and
            ($_.status.containerStatuses | Where-Object { $_.ready -eq $true }).Count -eq 2
        }
        
        if ($readyPods.Count -eq 2) {
            $ready = $true
            break
        }
    }
    
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
    $elapsed += 5
}

Write-Host ""

if (-not $ready) {
    Write-Error "Deployment did not become ready within timeout"
    Write-Info "Checking pod status..."
    oc get pods -l app=payment-api
    Write-Info "Checking events..."
    oc get events --sort-by='.lastTimestamp' | Select-Object -Last 10
    exit 1
}

Write-Success "Deployment is ready"

# Get deployment info
Write-Header "Deployment Information"

Write-Info "Pods:"
oc get pods -l app=payment-api -o wide

Write-Info "`nServices:"
oc get svc payment-api

Write-Info "`nRoute:"
$routeHost = oc get route payment-api -o jsonpath='{.spec.host}'
$apiUrl = "https://$routeHost"

Write-Success "Payment API URL: $apiUrl"

# Test endpoints
Write-Header "Testing Endpoints"

Write-Info "Testing /health endpoint..."
try {
    $healthResponse = Invoke-RestMethod -Uri "$apiUrl/health" -Method Get -SkipCertificateCheck
    Write-Success "Health check passed: $($healthResponse.status)"
    Write-Host "  Service: $($healthResponse.service)"
    Write-Host "  Version: $($healthResponse.version)"
} catch {
    Write-Error "Health check failed: $_"
}

Write-Info "`nTesting /metrics endpoint..."
try {
    $metricsResponse = Invoke-WebRequest -Uri "$apiUrl/metrics" -Method Get -SkipCertificateCheck
    $metricsLines = ($metricsResponse.Content -split "`n" | Where-Object { $_ -match "^[^#]" -and $_.Trim() -ne "" }).Count
    Write-Success "Metrics endpoint accessible ($metricsLines metrics)"
} catch {
    Write-Error "Metrics endpoint failed: $_"
}

Write-Info "`nCreating test payment..."
try {
    $payment = @{
        amount = 100.50
        currency = "USD"
        description = "Test payment from OpenShift deployment"
    } | ConvertTo-Json

    $paymentResponse = Invoke-RestMethod -Uri "$apiUrl/api/payments" -Method Post -Body $payment -ContentType "application/json" -SkipCertificateCheck
    Write-Success "Payment created: $($paymentResponse.id)"
    Write-Host "  Amount: $($paymentResponse.amount) $($paymentResponse.currency)"
    Write-Host "  Status: $($paymentResponse.status)"
} catch {
    Write-Error "Payment creation failed: $_"
}

# Check logs
Write-Header "Checking Logs"

$podName = oc get pods -l app=payment-api -o jsonpath='{.items[0].metadata.name}'
Write-Info "Pod: $podName"

Write-Info "`nPayment API logs (last 10 lines):"
oc logs $podName -c payment-api --tail=10

Write-Info "`nPromtail logs (last 10 lines):"
oc logs $podName -c promtail --tail=10

# Check log files
Write-Info "`nLog files in shared volume:"
oc exec $podName -c payment-api -- ls -lh /var/log/payment-api/ 2>$null

# Summary
Write-Header "Deployment Summary"

Write-Host @"

[OK] Deployment Status: READY
Replicas: 2/2
API URL: $apiUrl
Metrics: $apiUrl/metrics
Traces: Exported to Tempo (http://tempo:4317)
Logs: 
   - Console to stdout to Promtail
   - File to /var/log/payment-api to Promtail to Loki

Useful Commands:
  # View logs
  oc logs -f deployment/payment-api -c payment-api
  oc logs -f deployment/payment-api -c promtail
  
  # Check log files
  oc exec deployment/payment-api -c payment-api -- ls -lh /var/log/payment-api/
  
  # Port forward
  oc port-forward deployment/payment-api 8888:8888
  
  # Scale
  oc scale deployment/payment-api --replicas=3
  
  # Generate load
  ..\test-api-load.ps1 -BaseUrl $apiUrl -Requests 100

View in Grafana:
  Prometheus: rate(http_server_request_count_total{job="payment-api"}[5m])
  Loki: {app="payment-api-instrumented"}
  Tempo: { service.name = "payment-api-instrumented" }

"@ -ForegroundColor Cyan

Write-Success "Deployment completed successfully!"
