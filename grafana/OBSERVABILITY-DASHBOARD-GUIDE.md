# 🏦 eBanking Observability Dashboard - Complete Guide
## Data2AI Academy - Banking Observability Best Practices

This guide provides comprehensive implementation of 4 key observability methodologies for critical banking systems.

---

## 📋 Table of Contents
1. [RED Method - Service-Centric](#red-method)
2. [USE Method - Resource-Centric](#use-method)
3. [Four Golden Signals - Google SRE](#four-golden-signals)
4. [SLI/SLO Framework - Reliability](#slislo-framework)
5. [Alert Rules](#alert-rules)
6. [Implementation](#implementation)

---

## 🔴 RED Method - Service-Centric
**Focus**: User experience and customer-visible metrics

### Metrics Overview
| Metric | Target | Description |
|--------|--------|-------------|
| **Rate** | 500 req/s (production) | Requests per second |
| **Errors** | < 0.1% | Percentage of failed requests |
| **Duration** | P95 < 300ms | 95th percentile latency |

### Panel 1: Rate (Requests/sec)
**Type**: Gauge  
**Query**:
```promql
sum(rate(ebanking_api_requests_total{environment="$environment"}[5m]))
```
**Thresholds**:
- Green: < 400 req/s
- Yellow: 400-600 req/s
- Red: > 600 req/s

### Panel 2: Errors (% Failed Requests)
**Type**: Gauge  
**Query**:
```promql
100 * sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[5m])) 
/ sum(rate(ebanking_api_requests_total{environment="$environment"}[5m]))
```
**Thresholds**:
- Green: < 0.1%
- Yellow: 0.1-1%
- Red: > 1%

### Panel 3: Duration (P95 Latency)
**Type**: Gauge  
**Query**:
```promql
histogram_quantile(0.95, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment="$environment"}[5m])) by (le)
)
```
**Thresholds**:
- Green: < 300ms
- Yellow: 300-500ms
- Red: > 500ms

### Panel 4: Request Rate by Endpoint
**Type**: Time Series  
**Query**:
```promql
sum(rate(ebanking_api_requests_total{environment="$environment"}[5m])) by (endpoint)
```

### Panel 5: Latency Distribution (P95/P99)
**Type**: Time Series  
**Queries**:
```promql
# P95
histogram_quantile(0.95, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment="$environment"}[5m])) by (le, endpoint)
)

# P99
histogram_quantile(0.99, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment="$environment"}[5m])) by (le, endpoint)
)
```

### Panel 6: Transaction Success Rate
**Type**: Pie Chart  
**Query**:
```promql
sum(increase(ebanking_transactions_processed_total{environment="$environment"}[1h])) by (status)
```

### Panel 7: Transaction Rate by Type
**Type**: Time Series (Stacked)  
**Query**:
```promql
sum(rate(ebanking_transactions_processed_total{environment="$environment",status="success"}[5m])) 
by (transaction_type)
```

---

## 📊 USE Method - Resource-Centric
**Focus**: Infrastructure health and resource utilization

### Metrics Overview
| Metric | Target | Description |
|--------|--------|-------------|
| **Utilization** | < 70% | Resource usage percentage |
| **Saturation** | < 5 queued | Queue depth/waiting requests |
| **Errors** | 0 critical | System-level errors |

### Panel 1: Utilization (DB Connections)
**Type**: Gauge  
**Query**:
```promql
sum(ebanking_database_connections{environment="$environment"})
```
**Thresholds**:
- Green: < 35 connections
- Yellow: 35-45 connections
- Red: > 45 connections (out of 50 max)

### Panel 2: Saturation (Active Sessions)
**Type**: Gauge  
**Query**:
```promql
ebanking_active_sessions{environment="$environment"}
```
**Thresholds**:
- Green: < 400 sessions
- Yellow: 400-600 sessions
- Red: > 600 sessions

### Panel 3: Errors by Severity
**Type**: Pie Chart  
**Query**:
```promql
sum(increase(ebanking_api_errors_total{environment="$environment"}[1h])) by (severity)
```

### Panel 4: Database Connection Pools
**Type**: Time Series (Stacked)  
**Query**:
```promql
ebanking_database_connections{environment="$environment"}
```

### Panel 5: Database Query Performance
**Type**: Time Series  
**Query**:
```promql
histogram_quantile(0.95, 
  sum(rate(ebanking_database_query_duration_seconds_bucket{environment="$environment"}[5m])) 
  by (le, query_type)
)
```
**Threshold**: 100ms (red line)

---

## ⭐ Four Golden Signals - Google SRE
**Focus**: Comprehensive service health (combines RED + USE)

### Metrics Overview
| Signal | Target | Description |
|--------|--------|-------------|
| **Latency** | 150ms avg | Time to process requests |
| **Traffic** | 200 req/s | Volume of requests |
| **Errors** | < 0.05% | Failure rate |
| **Saturation** | 65% | Resource capacity usage |

### Panel 1: Latency (P50)
**Type**: Gauge  
**Query**:
```promql
histogram_quantile(0.50, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment="$environment"}[5m])) by (le)
)
```
**Thresholds**:
- Green: < 150ms
- Yellow: 150-300ms
- Red: > 300ms

### Panel 2: Traffic
**Type**: Gauge  
**Query**:
```promql
sum(rate(ebanking_api_requests_total{environment="$environment"}[5m]))
```
**Thresholds**:
- Green: < 150 req/s
- Yellow: 150-300 req/s
- Red: > 300 req/s

### Panel 3: Errors
**Type**: Gauge  
**Query**:
```promql
100 * sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[5m])) 
/ sum(rate(ebanking_api_requests_total{environment="$environment"}[5m]))
```
**Thresholds**:
- Green: < 0.05%
- Yellow: 0.05-0.5%
- Red: > 0.5%

### Panel 4: Saturation
**Type**: Gauge  
**Query**:
```promql
100 * sum(ebanking_database_connections{environment="$environment"}) / 150
```
**Thresholds**:
- Green: < 65%
- Yellow: 65-85%
- Red: > 85%

### Panel 5: Latency Heatmap
**Type**: Heatmap  
**Query**:
```promql
sum(increase(ebanking_request_duration_seconds_bucket{environment="$environment"}[1m])) by (le)
```

### Panel 6: Traffic by Channel
**Type**: Time Series  
**Query**:
```promql
sum(rate(ebanking_transactions_processed_total{environment="$environment"}[5m])) by (channel)
```

---

## 🎯 SLI/SLO Framework - Reliability
**Focus**: Service Level Objectives and Error Budgets

### SLO Definitions
| Service | SLO | SLI | Error Budget |
|---------|-----|-----|--------------|
| **Payment API** | 99.95% | Availability | 0.05% (21.6 min/month) |
| **Transfer API** | 99.9% | Availability | 0.1% (43.2 min/month) |
| **Auth Service** | 99.99% | Availability | 0.01% (4.3 min/month) |
| **Latency** | P95 < 500ms | Response time | - |

### Panel 1: SLO Compliance - Availability
**Type**: Stat Panel  
**Query**:
```promql
# 30-day availability
100 * (
  sum(rate(ebanking_api_requests_total{environment="$environment"}[30d])) 
  - sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[30d]))
) / sum(rate(ebanking_api_requests_total{environment="$environment"}[30d]))
```
**Display**: Show as percentage with 4 decimal places  
**Thresholds**:
- Green: ≥ 99.95%
- Yellow: 99.9-99.95%
- Red: < 99.9%

### Panel 2: Error Budget Remaining
**Type**: Bar Gauge  
**Query**:
```promql
# Error budget consumption (%)
100 * (
  1 - (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[30d])) 
    / (sum(rate(ebanking_api_requests_total{environment="$environment"}[30d])) * 0.0005)
  )
)
```
**Thresholds**:
- Green: > 50% remaining
- Yellow: 20-50% remaining
- Red: < 20% remaining

### Panel 3: Multi-Burn Rate Alerts
**Type**: Time Series  
**Queries**:
```promql
# 1-hour burn rate (fast)
sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[1h])) 
/ sum(rate(ebanking_api_requests_total{environment="$environment"}[1h]))
> 0.0005 * 14.4

# 6-hour burn rate (medium)
sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[6h])) 
/ sum(rate(ebanking_api_requests_total{environment="$environment"}[6h]))
> 0.0005 * 6

# 3-day burn rate (slow)
sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[3d])) 
/ sum(rate(ebanking_api_requests_total{environment="$environment"}[3d]))
> 0.0005 * 1
```

### Panel 4: SLI - Latency Compliance
**Type**: Stat Panel  
**Query**:
```promql
# % of requests under 500ms
100 * (
  sum(rate(ebanking_request_duration_seconds_bucket{le="0.5",environment="$environment"}[30d])) 
  / sum(rate(ebanking_request_duration_seconds_count{environment="$environment"}[30d]))
)
```
**Target**: > 95%

### Panel 5: SLO Dashboard - Payment Service
**Type**: Time Series  
**Queries**:
```promql
# Success rate
sum(rate(ebanking_transactions_processed_total{transaction_type="payment",status="success",environment="$environment"}[5m])) 
/ sum(rate(ebanking_transactions_processed_total{transaction_type="payment",environment="$environment"}[5m]))

# SLO target line
0.9995
```

### Panel 6: Error Budget Burn Down
**Type**: Time Series  
**Query**:
```promql
# Cumulative error budget consumption over 30 days
sum(increase(ebanking_api_requests_total{status_code=~"5..",environment="$environment"}[30d])) 
/ (sum(increase(ebanking_api_requests_total{environment="$environment"}[30d])) * 0.0005)
```

### Panel 7: Authentication SLO
**Type**: Stat Panel  
**Query**:
```promql
# Login success rate
100 * sum(rate(ebanking_login_attempts_total{status="success",environment="$environment"}[30d])) 
/ sum(rate(ebanking_login_attempts_total{environment="$environment"}[30d]))
```
**Target**: 99.99%

### Panel 8: Fraud Detection Latency
**Type**: Gauge  
**Query**:
```promql
# P99 fraud check latency
histogram_quantile(0.99, 
  sum(rate(ebanking_request_duration_seconds_bucket{endpoint="/api/v1/fraud-check",environment="$environment"}[5m])) 
  by (le)
)
```
**Target**: < 100ms

---

## 🚨 Alert Rules

### Critical Alerts (Page immediately)

#### 1. SLO Violation - Fast Burn
```yaml
alert: SLOFastBurn
expr: |
  (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="production"}[1h])) 
    / sum(rate(ebanking_api_requests_total{environment="production"}[1h]))
  ) > (0.0005 * 14.4)
  and
  (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="production"}[5m])) 
    / sum(rate(ebanking_api_requests_total{environment="production"}[5m]))
  ) > (0.0005 * 14.4)
for: 2m
labels:
  severity: critical
  environment: production
annotations:
  summary: "Fast SLO burn rate detected"
  description: "Error rate is {{ $value | humanizePercentage }} (14.4x SLO budget). Error budget will be exhausted in 2 days."
```

#### 2. High Error Rate
```yaml
alert: HighErrorRate
expr: |
  100 * (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="production"}[5m])) 
    / sum(rate(ebanking_api_requests_total{environment="production"}[5m]))
  ) > 1
for: 5m
labels:
  severity: critical
  environment: production
annotations:
  summary: "High error rate detected"
  description: "Error rate is {{ $value }}% (threshold: 1%)"
```

#### 3. High Latency
```yaml
alert: HighLatency
expr: |
  histogram_quantile(0.95, 
    sum(rate(ebanking_request_duration_seconds_bucket{environment="production"}[5m])) by (le, endpoint)
  ) > 0.5
for: 5m
labels:
  severity: critical
  environment: production
annotations:
  summary: "High latency on {{ $labels.endpoint }}"
  description: "P95 latency is {{ $value }}s (threshold: 500ms)"
```

### Warning Alerts (Investigate)

#### 4. SLO Violation - Slow Burn
```yaml
alert: SLOSlowBurn
expr: |
  (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="production"}[3d])) 
    / sum(rate(ebanking_api_requests_total{environment="production"}[3d]))
  ) > 0.0005
  and
  (
    sum(rate(ebanking_api_requests_total{status_code=~"5..",environment="production"}[1h])) 
    / sum(rate(ebanking_api_requests_total{environment="production"}[1h]))
  ) > 0.0005
for: 1h
labels:
  severity: warning
  environment: production
annotations:
  summary: "Slow SLO burn rate detected"
  description: "Error rate is {{ $value | humanizePercentage }}. Error budget will be exhausted in 30 days."
```

#### 5. Database Connection Pool High
```yaml
alert: DatabaseConnectionPoolHigh
expr: |
  sum(ebanking_database_connections{environment="production"}) > 40
for: 10m
labels:
  severity: warning
  environment: production
annotations:
  summary: "Database connection pool utilization high"
  description: "Connection pool at {{ $value }}/50 (threshold: 40)"
```

#### 6. High Session Count
```yaml
alert: HighSessionCount
expr: |
  ebanking_active_sessions{environment="production"} > 500
for: 15m
labels:
  severity: warning
  environment: production
annotations:
  summary: "High active session count"
  description: "Active sessions: {{ $value }} (threshold: 500)"
```

#### 7. Fraud Alert Spike
```yaml
alert: FraudAlertSpike
expr: |
  sum(rate(ebanking_fraud_alerts_total{severity="critical",environment="production"}[5m])) > 0.1
for: 5m
labels:
  severity: warning
  environment: production
annotations:
  summary: "Spike in critical fraud alerts"
  description: "Critical fraud alerts: {{ $value }}/sec"
```

---

## 📊 Implementation Steps

### Step 1: Create Dashboard in Grafana UI

1. **Login to Grafana** (http://localhost:3000)
2. **Create New Dashboard**: Click "+" → "Dashboard"
3. **Add Environment Variable**:
   - Settings → Variables → Add variable
   - Name: `environment`
   - Type: Custom
   - Values: `production,staging,development,training`

### Step 2: Add Panels by Section

Follow the panel definitions above for each methodology:
1. Start with RED Method (7 panels)
2. Add USE Method (5 panels)
3. Add Four Golden Signals (6 panels)
4. Add SLI/SLO Framework (8 panels)

### Step 3: Configure Alerts

1. **Navigate to**: Alerting → Alert rules
2. **Create alert group**: `ebanking-slo-alerts`
3. **Add each alert rule** from the Alert Rules section above

### Step 4: Export Dashboard

1. **Dashboard Settings** → JSON Model
2. **Copy JSON** and save to:
   ```
   observability-stack/grafana/provisioning/dashboards/ebanking-observability-complete.json
   ```

### Step 5: Verify Metrics

Run this query to verify all metrics are available:
```promql
{__name__=~"ebanking_.*"}
```

---

## 🎓 Best Practices Summary

### RED Method
- ✅ Focus on customer-facing metrics
- ✅ Monitor all API endpoints
- ✅ Set realistic SLOs based on business requirements
- ✅ Use P95/P99 for latency (not average)

### USE Method
- ✅ Monitor resource utilization before saturation occurs
- ✅ Set alerts at 70% utilization (not 90%)
- ✅ Track queue depths and wait times
- ✅ Separate infrastructure errors from application errors

### Four Golden Signals
- ✅ Combine service and resource metrics
- ✅ Use for holistic service health view
- ✅ Correlate signals during incidents
- ✅ Implement for all critical services

### SLI/SLO Framework
- ✅ Define SLOs based on user expectations
- ✅ Use multi-window, multi-burn-rate alerts
- ✅ Track error budget consumption
- ✅ Review and adjust SLOs quarterly
- ✅ Implement different SLOs per environment

---

## 📚 References

- **Google SRE Book**: https://sre.google/sre-book/monitoring-distributed-systems/
- **RED Method**: https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/
- **USE Method**: http://www.brendangregg.com/usemethod.html
- **SLO Implementation**: https://sre.google/workbook/implementing-slos/

---

**Created by**: Data2AI Academy  
**Version**: 1.0  
**Last Updated**: 2025-01-21
