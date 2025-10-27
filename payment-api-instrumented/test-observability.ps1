# Payment API Observability Test Script
# Tests Loki (Logs), Tempo (Traces), and Prometheus (Metrics)

$API_URL = "http://localhost:8888"
$LOKI_URL = "http://localhost:3100"
$TEMPO_URL = "http://localhost:3200"
$PROMETHEUS_URL = "http://localhost:9090"
$GRAFANA_URL = "http://localhost:3000"

Write-Host "=== Payment API Observability Test ===" -ForegroundColor Cyan
Write-Host ""

# STEP 1: Verify Services
Write-Host "[STEP 1] Verifying Services..." -ForegroundColor Yellow
Write-Host ""

Write-Host "  Checking Payment API..." -ForegroundColor White
try {
    $health = Invoke-RestMethod -Uri "$API_URL/health" -Method Get -TimeoutSec 5
    Write-Host "    ✓ Payment API: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Payment API not accessible" -ForegroundColor Red
    exit 1
}

Write-Host "  Checking Loki..." -ForegroundColor White
try {
    Invoke-RestMethod -Uri "$LOKI_URL/ready" -Method Get -TimeoutSec 5 | Out-Null
    Write-Host "    ✓ Loki: Ready" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Loki not accessible" -ForegroundColor Red
}

Write-Host "  Checking Tempo..." -ForegroundColor White
try {
    Invoke-RestMethod -Uri "$TEMPO_URL/status" -Method Get -TimeoutSec 5 | Out-Null
    Write-Host "    ✓ Tempo: Ready" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Tempo not accessible" -ForegroundColor Red
}

Write-Host "  Checking Prometheus..." -ForegroundColor White
try {
    Invoke-RestMethod -Uri "$PROMETHEUS_URL/-/healthy" -Method Get -TimeoutSec 5 | Out-Null
    Write-Host "    ✓ Prometheus: Healthy" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Prometheus not accessible" -ForegroundColor Red
}

Write-Host ""

# STEP 2: Generate Test Traffic
Write-Host "[STEP 2] Generating Test Traffic..." -ForegroundColor Yellow
Write-Host ""

$traceIds = @()
$paymentTypes = @("card", "paypal", "bank_transfer")
$cardBrands = @("VISA", "MASTERCARD", "AMEX")

for ($i = 1; $i -le 10; $i++) {
    $payment = @{
        amount = [math]::Round((Get-Random -Minimum 50 -Maximum 500), 2)
        currency = "EUR"
        paymentMethod = $paymentTypes | Get-Random
        cardBrand = $cardBrands | Get-Random
        userId = "U$(Get-Random -Minimum 10000 -Maximum 99999)"
        region = "EU_WEST"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$API_URL/api/payments" -Method Post -Body $payment -ContentType "application/json"
        Write-Host "  [$i/10] ✓ Payment: $($response.amount) EUR - TraceID: $($response.traceId)" -ForegroundColor Green
        $traceIds += $response.traceId
        Start-Sleep -Milliseconds 300
    } catch {
        Write-Host "  [$i/10] ✗ Failed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Generated $($traceIds.Count) transactions" -ForegroundColor Cyan
Write-Host "  Waiting 10s for ingestion..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host ""

# STEP 3: Verify Logs in Loki
Write-Host "[STEP 3] Verifying Logs in Loki..." -ForegroundColor Yellow
Write-Host ""

$lokiQuery = '{container="payment-api_instrumented"}'
$lokiUrl = "$LOKI_URL/loki/api/v1/query_range?query=$([System.Uri]::EscapeDataString($lokiQuery))&limit=50"

try {
    $lokiResponse = Invoke-RestMethod -Uri $lokiUrl -Method Get
    $logCount = 0
    
    if ($lokiResponse.data.result) {
        foreach ($stream in $lokiResponse.data.result) {
            $logCount += $stream.values.Count
        }
    }
    
    Write-Host "  ✓ Found $logCount log entries in Loki" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to query Loki" -ForegroundColor Red
}

Write-Host ""

# STEP 4: Verify Traces in Tempo
Write-Host "[STEP 4] Verifying Traces in Tempo..." -ForegroundColor Yellow
Write-Host ""

$tracesFound = 0
$samplesToCheck = [Math]::Min(3, $traceIds.Count)

for ($i = 0; $i -lt $samplesToCheck; $i++) {
    $traceId = $traceIds[$i]
    
    try {
        $trace = Invoke-RestMethod -Uri "$TEMPO_URL/api/traces/$traceId" -Method Get -TimeoutSec 5
        
        if ($trace) {
            $tracesFound++
            Write-Host "  ✓ Trace found: $traceId" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⚠ Trace not found: $traceId (may still be processing)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "  Found $tracesFound/$samplesToCheck traces" -ForegroundColor Cyan
Write-Host ""

# STEP 5: Verify Metrics
Write-Host "[STEP 5] Verifying Metrics in Prometheus..." -ForegroundColor Yellow
Write-Host ""

$metrics = @("payment_count_total", "payment_amount_total", "http_server_request_duration_seconds")

foreach ($metric in $metrics) {
    $promUrl = "$PROMETHEUS_URL/api/v1/query?query=$([System.Uri]::EscapeDataString($metric))"
    
    try {
        $promResponse = Invoke-RestMethod -Uri $promUrl -Method Get
        
        if ($promResponse.data.result.Count -gt 0) {
            $value = $promResponse.data.result[0].value[1]
            Write-Host "  ✓ $metric : $value" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $metric : No data" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ $metric : Query failed" -ForegroundColor Red
    }
}

Write-Host ""

# Summary
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open Grafana: $GRAFANA_URL" -ForegroundColor Gray
Write-Host "     Credentials: admin / GrafanaSecure123!Change@Me" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Explore Logs (Loki):" -ForegroundColor Gray
Write-Host "     Query: {container=`"payment-api_instrumented`"}" -ForegroundColor White
Write-Host ""
Write-Host "  3. Explore Traces (Tempo):" -ForegroundColor Gray
Write-Host "     Service: payment-api-instrumented" -ForegroundColor White
Write-Host "     Sample Trace: $($traceIds[0])" -ForegroundColor White
Write-Host ""
Write-Host "  4. View Metrics (Prometheus):" -ForegroundColor Gray
Write-Host "     Query: rate(payment_count_total[5m])" -ForegroundColor White
Write-Host ""
