# ============================================
# Payment API - Load Test Script
# ============================================
# Generates load to test observability
# ============================================

param(
    [string]$BaseUrl,
    [int]$Requests = 100,
    [int]$Concurrent = 5,
    [int]$DelayMs = 100
)

$ErrorActionPreference = "Continue"

function Write-Header { Write-Host "`n=== $args ===" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Yellow }

# Get route URL if not provided
if ([string]::IsNullOrEmpty($BaseUrl)) {
    Write-Info "Getting route URL from OpenShift..."
    $routeHost = oc get route payment-api -o jsonpath='{.spec.host}' 2>$null
    if ([string]::IsNullOrEmpty($routeHost)) {
        Write-Error "Could not get route URL. Please provide -BaseUrl parameter"
        exit 1
    }
    $BaseUrl = "https://$routeHost"
}

Write-Header "Payment API Load Test"
Write-Info "Base URL: $BaseUrl"
Write-Info "Requests: $Requests"
Write-Info "Concurrent: $Concurrent"
Write-Info "Delay: ${DelayMs}ms"

# Test connectivity
Write-Info "Testing connectivity..."
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method Get -SkipCertificateCheck
    Write-Success "API is healthy: $($health.status)"
} catch {
    Write-Error "API is not accessible: $_"
    exit 1
}

# Statistics
$stats = @{
    Total = 0
    Success = 0
    Failed = 0
    TotalDuration = 0
    MinDuration = [double]::MaxValue
    MaxDuration = 0
}

Write-Header "Generating Load"

$startTime = Get-Date

# Create payment requests
$jobs = @()
for ($i = 1; $i -le $Requests; $i++) {
    # Limit concurrent jobs
    while ((Get-Job -State Running).Count -ge $Concurrent) {
        Start-Sleep -Milliseconds 50
    }
    
    $job = Start-Job -ScriptBlock {
        param($url, $index)
        
        $payment = @{
            amount = [math]::Round((Get-Random -Minimum 10 -Maximum 1000) + (Get-Random) / 100, 2)
            currency = @("USD", "EUR", "GBP")[(Get-Random -Maximum 3)]
            description = "Load test payment #$index"
        } | ConvertTo-Json
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$url/api/payments" -Method Post -Body $payment -ContentType "application/json" -SkipCertificateCheck
            $sw.Stop()
            
            return @{
                Success = $true
                Duration = $sw.ElapsedMilliseconds
                PaymentId = $response.id
            }
        } catch {
            $sw.Stop()
            return @{
                Success = $false
                Duration = $sw.ElapsedMilliseconds
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $BaseUrl, $i
    
    $jobs += $job
    
    # Progress
    if ($i % 10 -eq 0) {
        Write-Host "." -NoNewline
    }
    
    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Info "Waiting for all requests to complete..."

# Wait for all jobs
$jobs | Wait-Job | Out-Null

# Collect results
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $stats.Total++
    
    if ($result.Success) {
        $stats.Success++
        $stats.TotalDuration += $result.Duration
        $stats.MinDuration = [math]::Min($stats.MinDuration, $result.Duration)
        $stats.MaxDuration = [math]::Max($stats.MaxDuration, $result.Duration)
    } else {
        $stats.Failed++
    }
    
    Remove-Job -Job $job
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

# Calculate statistics
$avgDuration = if ($stats.Success -gt 0) { $stats.TotalDuration / $stats.Success } else { 0 }
$successRate = if ($stats.Total -gt 0) { ($stats.Success / $stats.Total) * 100 } else { 0 }
$throughput = if ($totalTime -gt 0) { $stats.Total / $totalTime } else { 0 }

# Display results
Write-Header "Load Test Results"

Write-Host @"

📊 Request Statistics:
   Total Requests:    $($stats.Total)
   Successful:        $($stats.Success) ($([math]::Round($successRate, 2))%)
   Failed:            $($stats.Failed)
   
⏱️  Latency Statistics:
   Average:           $([math]::Round($avgDuration, 2)) ms
   Minimum:           $([math]::Round($stats.MinDuration, 2)) ms
   Maximum:           $([math]::Round($stats.MaxDuration, 2)) ms
   
🚀 Performance:
   Total Duration:    $([math]::Round($totalTime, 2)) seconds
   Throughput:        $([math]::Round($throughput, 2)) req/s

"@ -ForegroundColor Cyan

if ($stats.Failed -gt 0) {
    Write-Error "Some requests failed. Check application logs for details."
} else {
    Write-Success "All requests completed successfully! 🎉"
}

# Grafana queries
Write-Header "Grafana Queries"

Write-Host @"

📊 View in Grafana:

Prometheus (Metrics):
  # Request rate
  rate(http_server_request_count_total{job="payment-api"}[5m])
  
  # P95 latency
  histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket{job="payment-api"}[5m]))
  
  # Error rate
  rate(http_server_request_count_total{job="payment-api",http_status_code=~"5.."}[5m])

Loki (Logs):
  # All payment API logs
  {app="payment-api-instrumented"}
  
  # Only errors
  {app="payment-api-instrumented"} |= "Error"
  
  # Payment creation logs
  {app="payment-api-instrumented"} | json | message =~ "Payment.*created"

Tempo (Traces):
  # Find traces for payment API
  { service.name = "payment-api-instrumented" }
  
  # Find slow traces
  { service.name = "payment-api-instrumented" && duration > 100ms }
  
  # Find error traces
  { service.name = "payment-api-instrumented" && status = error }

"@ -ForegroundColor Yellow

Write-Success "Load test completed! Check Grafana for observability data. 📊📝🔍"
