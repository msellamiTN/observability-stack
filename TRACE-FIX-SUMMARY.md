# Tempo Trace Not Found - Root Cause & Fix

## Issue
Trace ID `a80d5e77e06a3cd4adedbf1f9611ebe1` exists in application logs but returns "Not Found" when queried in Tempo.

## Root Cause Analysis

### 1. **ActivitySource Name Mismatch** ⚠️ CRITICAL
- **Controller**: `ActivitySource` was named `"PaymentApi"`
- **Program.cs**: Registered source as `"payment-api-instrumented"`
- **Result**: Custom spans from the controller were **never exported** because the ActivitySource name didn't match the registered source

### 2. **GET /metrics Endpoint Has No Custom Tracing**
- The log entry showing trace ID was from a `GET /metrics` request
- This endpoint only has ASP.NET Core auto-instrumentation
- These traces are very short-lived and may not be exported or retained

### 3. **Lack of Debug Visibility**
- No console exporter to verify traces are being created
- No debug logging for OTLP exporter to see export attempts/failures

## Fixes Applied

### 1. Fixed ActivitySource Name
**File**: `Controllers/PaymentsController.cs`
```csharp
// BEFORE
private static readonly ActivitySource ActivitySource = new("PaymentApi");

// AFTER
private static readonly ActivitySource ActivitySource = new("payment-api-instrumented");
```

### 2. Added Console Exporter for Debugging
**File**: `Program.cs`
```csharp
.AddSource(serviceName)
.AddConsoleExporter() // Debug: verify traces are being created
.AddOtlpExporter(options =>
{
    options.Endpoint = new Uri(builder.Configuration["OpenTelemetry:OtlpEndpoint"] ?? "http://tempo:4317");
    options.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
})
```

### 3. Enabled Debug Logging
**File**: `appsettings.json`
```json
"Logging": {
  "LogLevel": {
    "Default": "Information",
    "OpenTelemetry": "Debug",
    "OpenTelemetry.Exporter.OpenTelemetryProtocol": "Debug"
  }
}
```

## Next Steps

### 1. Rebuild and Restart the Application
```bash
cd observability-stack
docker-compose build payment-api_instrumented
docker-compose up -d payment-api_instrumented
```

### 2. Test Trace Generation
```bash
# Send a payment request
curl -X POST http://localhost:8888/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.50,
    "currency": "EUR",
    "paymentMethod": "card",
    "cardBrand": "VISA",
    "userId": "U12345",
    "region": "EU_WEST"
  }'
```

### 3. Verify Trace Export
Check application logs for:
- Console exporter output (traces being created)
- OTLP exporter debug logs (traces being sent to Tempo)
- Trace ID in response

```bash
docker logs payment-api_instrumented --tail 50
```

### 4. Query Tempo
```bash
# Replace TRACE_ID with the one from the response
curl "http://localhost:3200/api/traces/TRACE_ID"
```

## Expected Behavior After Fix

1. **Custom spans** from `ProcessPayment` endpoint will be exported
2. **Console logs** will show trace data being created
3. **OTLP exporter** will successfully send traces to Tempo
4. **Tempo** will return trace data when queried

## Verification Checklist

- [ ] Application rebuilt and restarted
- [ ] Console exporter shows trace output in logs
- [ ] OTLP exporter logs show successful exports
- [ ] POST /api/payments returns trace ID
- [ ] Tempo query returns trace data (not 404)
- [ ] Grafana Explore shows traces

## Additional Notes

### Why GET /metrics Traces Might Not Appear
- Very short duration (< 2ms)
- No custom spans, only auto-instrumentation
- May be filtered by sampling or retention policies
- Tempo retention is 1 hour (`block_retention: 1h`)

### Recommended Test Endpoint
Use **POST /api/payments** instead of GET /metrics for testing because:
- Creates custom spans with rich metadata
- Longer processing time (50-200ms+)
- Better for demonstrating distributed tracing
- Includes business context (payment amount, method, etc.)
