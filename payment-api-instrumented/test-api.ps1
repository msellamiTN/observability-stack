# Payment API Test Script
# PowerShell script to test the payment API

$baseUrl = "http://localhost:8080"

Write-Host "=== Payment API Test Suite ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "[TEST 1] Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✓ Health Status: $($health.status)" -ForegroundColor Green
    Write-Host "  Service: $($health.service)" -ForegroundColor Gray
    Write-Host "  Version: $($health.version)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Health check failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Single Successful Payment
Write-Host "[TEST 2] Process Single Payment (VISA)..." -ForegroundColor Yellow
$payment1 = @{
    amount = 250.50
    currency = "EUR"
    paymentMethod = "card"
    cardBrand = "VISA"
    userId = "U12345"
    region = "EU_WEST"
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri "$baseUrl/api/payments" -Method Post -Body $payment1 -ContentType "application/json"
    Write-Host "✓ Transaction ID: $($response1.transactionId)" -ForegroundColor Green
    Write-Host "  Status: $($response1.status)" -ForegroundColor Gray
    Write-Host "  Amount: $($response1.amount) $($response1.currency)" -ForegroundColor Gray
    Write-Host "  Processing Time: $($response1.processingTimeMs)ms" -ForegroundColor Gray
    Write-Host "  Trace ID: $($response1.traceId)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Payment failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Different Payment Methods
Write-Host "[TEST 3] Testing Different Payment Methods..." -ForegroundColor Yellow
$paymentMethods = @(
    @{ method = "card"; brand = "MASTERCARD"; amount = 150.00 },
    @{ method = "paypal"; brand = $null; amount = 75.50 },
    @{ method = "bank_transfer"; brand = $null; amount = 500.00 },
    @{ method = "apple_pay"; brand = $null; amount = 99.99 },
    @{ method = "google_pay"; brand = $null; amount = 125.00 }
)

foreach ($pm in $paymentMethods) {
    $payment = @{
        amount = $pm.amount
        currency = "EUR"
        paymentMethod = $pm.method
        cardBrand = $pm.brand
        userId = "U$(Get-Random -Minimum 10000 -Maximum 99999)"
        region = "EU_WEST"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/payments" -Method Post -Body $payment -ContentType "application/json"
        Write-Host "  ✓ $($pm.method): $($response.status) - $($response.processingTimeMs)ms" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $($pm.method): Failed" -ForegroundColor Red
    }
}
Write-Host ""

# Test 4: Simulate Multiple Payments
Write-Host "[TEST 4] Simulate 50 Payments..." -ForegroundColor Yellow
try {
    $simulate = Invoke-RestMethod -Uri "$baseUrl/api/payments/simulate?count=50" -Method Post
    Write-Host "✓ Simulated: $($simulate.totalSimulated) payments" -ForegroundColor Green
    Write-Host "  Successful: $($simulate.successful)" -ForegroundColor Gray
    Write-Host "  Failed: $($simulate.failed)" -ForegroundColor Gray
    Write-Host "  Success Rate: $([math]::Round($simulate.successRate, 2))%" -ForegroundColor Gray
} catch {
    Write-Host "✗ Simulation failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Invalid Payment (should fail)
Write-Host "[TEST 5] Test Invalid Payment (negative amount)..." -ForegroundColor Yellow
$invalidPayment = @{
    amount = -50.00
    currency = "EUR"
    paymentMethod = "card"
    cardBrand = "VISA"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/api/payments" -Method Post -Body $invalidPayment -ContentType "application/json"
    Write-Host "✗ Should have failed but succeeded" -ForegroundColor Red
} catch {
    Write-Host "✓ Correctly rejected invalid payment" -ForegroundColor Green
}
Write-Host ""

# Test 6: Check Prometheus Metrics
Write-Host "[TEST 6] Check Prometheus Metrics Endpoint..." -ForegroundColor Yellow
try {
    $metrics = Invoke-WebRequest -Uri "$baseUrl/metrics" -Method Get
    $metricsText = $metrics.Content
    
    if ($metricsText -match "payment_count_total") {
        Write-Host "✓ payment_count_total metric found" -ForegroundColor Green
    }
    if ($metricsText -match "payment_amount_total") {
        Write-Host "✓ payment_amount_total metric found" -ForegroundColor Green
    }
    if ($metricsText -match "payment_processing_time_seconds") {
        Write-Host "✓ payment_processing_time_seconds metric found" -ForegroundColor Green
    }
    if ($metricsText -match "http_requests_total") {
        Write-Host "✓ http_requests_total metric found" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Metrics endpoint failed: $_" -ForegroundColor Red
}
Write-Host ""

# Test 7: Load Test Summary
Write-Host "[TEST 7] Generate Load for Dashboard Testing..." -ForegroundColor Yellow
Write-Host "Generating 200 transactions..." -ForegroundColor Gray
try {
    $loadTest = Invoke-RestMethod -Uri "$baseUrl/api/payments/simulate?count=200" -Method Post
    Write-Host "✓ Load test completed" -ForegroundColor Green
    Write-Host "  Total: $($loadTest.totalSimulated)" -ForegroundColor Gray
    Write-Host "  Success Rate: $([math]::Round($loadTest.successRate, 2))%" -ForegroundColor Gray
} catch {
    Write-Host "✗ Load test failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Test Suite Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open Prometheus: http://localhost:9090" -ForegroundColor Gray
Write-Host "2. Open Grafana: http://localhost:3000 (admin/GrafanaSecure123!Change@Me)" -ForegroundColor Gray
Write-Host "3. Query metrics: payment_count_total, payment_amount_total" -ForegroundColor Gray
Write-Host "4. Import dashboard: prometheus_dashboard_json.json" -ForegroundColor Gray
Write-Host ""
