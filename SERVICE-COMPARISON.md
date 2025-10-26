# Service Comparison: payment-api vs payment-api-instrumented

## Overview
This document clarifies the distinction between the two payment API services in the observability stack.

## Service Comparison Table

| Attribute | payment-api (Business KPI) | payment-api-instrumented (Observability Demo) |
|-----------|---------------------------|---------------------------------------------|
| **Service Name** | `payment-api` | `payment-api-instrumented` |
| **Service Namespace** | `ebanking` | `ebanking.observability` |
| **Container Name** | `payment-api` | `payment-api_instrumented` |
| **Port** | `8080` | `8888` |
| **Purpose** | Production business KPI tracking | Observability testing & demonstration |
| **Technology** | Python/Flask | .NET 8 / ASP.NET Core |
| **Metrics Backend** | InfluxDB | Prometheus |
| **Tracing** | None | Tempo (OTLP) |
| **Logging** | Standard output | Structured JSON (Serilog) |
| **OpenTelemetry** | No | Yes (Full instrumentation) |

## payment-api (Business KPI Service)

### Purpose
- **Primary Function**: Simulate real payment transactions for business KPI tracking
- **Data Storage**: InfluxDB for time-series business metrics
- **Use Case**: Business analytics, financial reporting, transaction monitoring

### Key Characteristics
```yaml
Service Identification:
  - service.name: payment-api
  - service.namespace: ebanking
  - Port: 8080
  - Technology: Python

Business Metrics:
  - Transaction volumes
  - Success/failure rates
  - Payment amounts
  - Processing times
  - Custom business KPIs
```

### Endpoints
- `http://localhost:8080/health` - Health check
- `http://localhost:8080/api/payment` - Payment processing
- `http://localhost:8080/metrics` - Business metrics

### Dependencies
- InfluxDB (for business metrics storage)
- Prometheus (for infrastructure metrics)

## payment-api-instrumented (Observability Demo Service)

### Purpose
- **Primary Function**: Demonstrate OpenTelemetry instrumentation patterns
- **Observability**: Full traces, metrics, and structured logs
- **Use Case**: Observability testing, distributed tracing demos, monitoring patterns

### Key Characteristics
```yaml
Service Identification:
  - service.name: payment-api-instrumented
  - service.namespace: ebanking.observability
  - Port: 8888
  - Technology: .NET 8 / C#

Observability Features:
  - Distributed tracing (Tempo)
  - Prometheus metrics with exemplars
  - Structured logging (Serilog)
  - Service graphs
  - Span metrics
  - Runtime instrumentation
```

### Resource Attributes
```yaml
Deployment:
  - deployment.environment: production
  - deployment.environment.type: docker
  - deployment.region: on-premise

Application:
  - app.team: platform-engineering
  - app.owner: observability-team
  - app.tier: backend
  - app.type: instrumented-demo
  - app.purpose: observability-testing

Container:
  - container.runtime: docker
  - orchestrator: docker-compose
  - cluster.name: observability-stack
```

### Endpoints
- `http://localhost:8888/health` - Health check
- `http://localhost:8888/metrics` - Prometheus metrics
- `http://localhost:8888/swagger` - API documentation (dev only)

### Instrumentation
- **ASP.NET Core**: Automatic HTTP request/response tracking
- **HTTP Client**: Outbound HTTP call tracking
- **SQL Client**: Database query tracking with statements
- **Runtime**: GC, memory, thread pool metrics
- **Process**: CPU and memory usage
- **Custom**: Business-specific spans and metrics

### Dependencies
- Tempo (for distributed tracing)
- Prometheus (for metrics)
- Loki (for logs via Promtail)

## Query Examples

### Find traces from instrumented service
```promql
{service.name="payment-api-instrumented"}
```

### Find traces from business KPI service
```promql
{service.name="payment-api"}
```

### Filter by namespace
```promql
# Observability demo services
{service.namespace="ebanking.observability"}

# Business services
{service.namespace="ebanking"}
```

### Grafana Loki queries
```logql
# Instrumented service logs
{ServiceName="payment-api-instrumented"}

# Business service logs
{container_name="payment-api"}
```

### Prometheus queries
```promql
# Instrumented service metrics
http_server_duration_seconds{service_name="payment-api-instrumented"}

# Business service metrics (from InfluxDB exporter)
payment_transactions_total{service="payment-api"}
```

## Use Cases

### When to use payment-api (Business KPI)
1. Analyzing business transaction patterns
2. Financial reporting and auditing
3. Real-time payment monitoring
4. Business intelligence dashboards
5. SLA tracking for payment processing

### When to use payment-api-instrumented (Observability Demo)
1. Testing distributed tracing setup
2. Demonstrating OpenTelemetry instrumentation
3. Validating observability pipelines
4. Training on observability best practices
5. Debugging trace collection issues
6. Testing service graph generation
7. Validating metrics-to-traces correlation

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Observability Stack                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────────┐     │
│  │  payment-api     │         │ payment-api-         │     │
│  │  (Business KPI)  │         │ instrumented         │     │
│  │                  │         │ (Observability)      │     │
│  │  Port: 8080      │         │ Port: 8888           │     │
│  │  Namespace:      │         │ Namespace:           │     │
│  │  ebanking        │         │ ebanking.observ...   │     │
│  └────────┬─────────┘         └──────────┬───────────┘     │
│           │                              │                  │
│           │ Business Metrics             │ Traces           │
│           ▼                              ▼                  │
│  ┌──────────────────┐         ┌──────────────────────┐     │
│  │    InfluxDB      │         │      Tempo           │     │
│  │  (Time Series)   │         │  (Distributed        │     │
│  │                  │         │   Tracing)           │     │
│  └──────────────────┘         └──────────────────────┘     │
│                                                              │
│           │ Infrastructure                │ Metrics          │
│           │ Metrics                       │ + Exemplars      │
│           ▼                               ▼                  │
│  ┌────────────────────────────────────────────────┐         │
│  │              Prometheus                         │         │
│  │          (Metrics Collection)                   │         │
│  └────────────────────────────────────────────────┘         │
│                           │                                  │
│                           │ Logs                             │
│                           ▼                                  │
│  ┌────────────────────────────────────────────────┐         │
│  │              Loki (Log Aggregation)             │         │
│  └────────────────────────────────────────────────┘         │
│                           │                                  │
│                           │ Visualization                    │
│                           ▼                                  │
│  ┌────────────────────────────────────────────────┐         │
│  │                  Grafana                        │         │
│  │        (Unified Observability UI)               │         │
│  └────────────────────────────────────────────────┘         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices

### Naming Conventions
- Use distinct service names to avoid confusion
- Use namespaces to group related services
- Add descriptive attributes (app.purpose, app.type)

### Separation of Concerns
- **Business KPI service**: Focus on business metrics and transaction data
- **Instrumented service**: Focus on observability patterns and technical metrics

### Correlation
- Both services can be correlated by:
  - Timestamp
  - Environment (production)
  - Cluster (observability-stack)
  - Common infrastructure metrics

### Monitoring Strategy
- Monitor **payment-api** for business health
- Monitor **payment-api-instrumented** for observability pipeline health
- Use different alert thresholds for each service type

## Summary

The two services serve complementary but distinct purposes:

- **payment-api**: Production-grade business KPI tracking with InfluxDB
- **payment-api-instrumented**: OpenTelemetry demonstration with full observability stack

This separation ensures:
1. Clear distinction in monitoring dashboards
2. Appropriate alerting strategies
3. Accurate service dependency mapping
4. Proper resource attribution
5. Simplified troubleshooting
