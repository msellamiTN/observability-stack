# Payment API - E-Banking Service

## Overview
A production-ready C# ASP.NET Core payment processing API instrumented with OpenTelemetry for complete observability.

## Features
- ✅ **OpenTelemetry Integration**: Metrics, Traces, and Logs
- ✅ **Prometheus Metrics Export**: Compatible with Grafana dashboards
- ✅ **Distributed Tracing**: OTLP export to Tempo
- ✅ **Structured Logging**: JSON logs with trace context
- ✅ **Health Checks**: Kubernetes-ready health endpoints
- ✅ **Realistic Simulation**: Payment processing with failure scenarios

## Metrics Exported

### Counters
- `payment_count_total` - Total payment transactions
  - Labels: `status`, `payment_method`, `currency`, `region`, `card_brand`
  
- `payment_amount_total` - Total payment amount in EUR
  - Labels: `status`, `payment_method`, `currency`, `region`, `card_brand`
  
- `http_requests_total` - Total HTTP requests
  - Labels: `job`, `status`, `method`, `endpoint`

### Histograms
- `payment_processing_time_seconds` - Payment processing duration
  - Labels: `status`, `payment_method`, `currency`, `region`, `card_brand`
  - Buckets: .005, .01, .025, .05, .075, .1, .25, .5, .75, 1, 2.5, 5, 7.5, 10

## API Endpoints

### POST /api/payments
Process a payment transaction

**Request Body:**
```json
{
  "amount": 100.50,
  "currency": "EUR",
  "paymentMethod": "card",
  "cardBrand": "VISA",
  "userId": "U12345",
  "region": "EU_WEST"
}
```

**Response:**
```json
{
  "transactionId": "abc123def456",
  "status": "success",
  "amount": 100.50,
  "currency": "EUR",
  "paymentMethod": "card",
  "cardBrand": "VISA",
  "processingTimeMs": 156,
  "traceId": "7bfa12d7a4b9e1c2",
  "spanId": "5c2ad01cbd8a9dfe"
}
```

### POST /api/payments/simulate?count=100
Simulate multiple payment transactions for testing

### GET /api/payments/{transactionId}
Retrieve payment by transaction ID

### GET /health
Health check endpoint

### GET /metrics
Prometheus metrics endpoint

## Running Locally

### Prerequisites
- .NET 8.0 SDK
- Docker (for containerized deployment)

### Development Mode
```bash
cd payment-api
dotnet restore
dotnet run
```

API will be available at: http://localhost:8080

### Docker Build
```bash
docker build -t payment-api:latest .
docker run -p 8080:8080 payment-api:latest
```

### Docker Compose (Full Stack)
```bash
cd docker-stack
docker-compose up -d
```

## Testing

### Single Payment
```bash
curl -X POST http://localhost:8080/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 250.00,
    "currency": "EUR",
    "paymentMethod": "card",
    "cardBrand": "VISA",
    "userId": "U12345",
    "region": "EU_WEST"
  }'
```

### Simulate Load
```bash
curl -X POST "http://localhost:8080/api/payments/simulate?count=100"
```

### Load Testing with Apache Bench
```bash
# Install Apache Bench
# Windows: Download from Apache website
# Linux: sudo apt-get install apache2-utils

# Run load test
ab -n 1000 -c 50 -p payment.json -T application/json http://localhost:8080/api/payments
```

**payment.json:**
```json
{
  "amount": 150.00,
  "currency": "EUR",
  "paymentMethod": "card",
  "cardBrand": "MASTERCARD",
  "userId": "U99999",
  "region": "EU_WEST"
}
```

## Observability Stack Integration

### Prometheus
Metrics are automatically scraped from `/metrics` endpoint.

**Configuration** (prometheus.yml):
```yaml
scrape_configs:
  - job_name: 'payment-api'
    static_configs:
      - targets: ['payment-api:8080']
```

### Grafana Dashboards
Import the provided dashboard: `prometheus_dashboard_json.json`

**Key Panels:**
- Total Revenue (24h)
- Success Rate (%)
- Average Latency (ms)
- Failed Amount (€)
- Transaction Volume Trend
- Revenue by Currency
- Card Brand Performance
- Performance by Region

### Tempo (Distributed Tracing)
Traces are exported via OTLP to Tempo at `http://tempo:4317`

**Trace Attributes:**
- `payment.amount`
- `payment.currency`
- `payment.method`
- `payment.card_brand`
- `payment.region`
- `payment.transaction_id`
- `payment.status`

### Loki (Logs)
Structured JSON logs with trace context:
```json
{
  "timestamp": "2025-10-23T22:30:15Z",
  "level": "INFO",
  "service": "payment-api",
  "message": "Payment processed",
  "traceId": "7bfa12d7a4b9e1c2",
  "spanId": "5c2ad01cbd8a9dfe",
  "transactionId": "abc123",
  "status": "success",
  "amount": 100.50
}
```

## Payment Methods Supported
- `card` - Credit/Debit Card (requires cardBrand)
- `bank_transfer` - Bank Transfer
- `paypal` - PayPal
- `apple_pay` - Apple Pay
- `google_pay` - Google Pay

## Card Brands Supported
- `VISA`
- `MASTERCARD`
- `AMEX`
- `DISCOVER`

## Regions
- `EU_WEST` - Western Europe
- `EU_CENTRAL` - Central Europe
- `US_EAST` - US East Coast
- `ASIA_PACIFIC` - Asia Pacific

## Currencies
- `EUR` - Euro
- `USD` - US Dollar
- `GBP` - British Pound
- `CHF` - Swiss Franc
- `JPY` - Japanese Yen

## Failure Scenarios
The API simulates realistic failure scenarios:
- **2%** - Fraud detection
- **2%** - Insufficient funds
- **1%** - Network timeout
- **~5%** - Total failure rate (realistic for production)

## SLA Targets
- ✅ Success Rate: ≥98%
- ✅ P95 Latency: <300ms
- ✅ P99 Latency: <500ms
- ✅ Availability: 99.9%
- ✅ Error Rate: <2%

## Alerts Configured
- PaymentAPIDown
- HighPaymentErrorRate
- PaymentSuccessRateSLAViolation
- HighPaymentLatency
- CriticalPaymentLatency
- HighHTTP5xxRate
- LowPaymentVolume
- HighValuePaymentFailures
- CardBrandPerformanceDegradation
- RegionalPerformanceIssue

## Architecture
```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│     Payment API (ASP.NET)       │
│  ┌──────────────────────────┐   │
│  │  OpenTelemetry SDK       │   │
│  │  - Metrics               │   │
│  │  - Traces                │   │
│  │  - Logs                  │   │
│  └──────────────────────────┘   │
└────┬────────┬────────┬──────────┘
     │        │        │
     ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐
│Prom  │ │Tempo │ │Loki  │
│etheus│ │      │ │      │
└───┬──┘ └──────┘ └──────┘
    │
    ▼
┌──────────┐
│ Grafana  │
└──────────┘
```

## License
MIT

## Support
For issues or questions, contact the payments team.
