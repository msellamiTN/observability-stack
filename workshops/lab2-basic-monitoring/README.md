# Lab 2: Basic Monitoring with Prometheus and Grafana

## Objective
Learn how to monitor system and application metrics using Prometheus and visualize them in Grafana.

## Prerequisites
- Completed Lab 1 (Environment Setup)
- All services should be running

## Tasks

### 1. Explore Prometheus UI

1. Open Prometheus at http://localhost:9090
2. In the "Graph" tab, try these queries:
   - `up` - Shows which targets are up
   - `rate(http_requests_total[1m])` - Request rate
   - `process_cpu_seconds_total` - CPU usage
   - `process_resident_memory_bytes` - Memory usage

### 2. Create Your First Grafana Dashboard

1. Log in to Grafana (http://localhost:3000)
2. Click "+" > "Create" > "Dashboard"
3. Add a new panel with this query:
   ```
   rate(http_requests_total{job="payment-api"}[1m])
   ```
4. Set panel title: "Payment API Request Rate"
5. Save the dashboard as "Payment API Monitoring"

### 3. Add System Metrics

1. Add a new row to your dashboard
2. Create a panel with query:
   ```
   rate(process_cpu_seconds_total{job=~"payment-api|node_exporter"}[1m]) * 100
   ```
3. Set panel title: "CPU Usage %"
4. Set Y-axis unit: "percent (0-100)"

### 4. Create a Stat Panel

1. Add a new panel
2. Change visualization to "Stat"
3. Use query:
   ```
   sum(rate(http_requests_total{job="payment-api"}[5m]))
   ```
4. Set panel title: "Total Requests (5m rate)"

## Exercises

1. Create a panel showing memory usage of all containers
2. Add a panel showing the 95th percentile of request duration
3. Create a heatmap of request rates by endpoint

## Verification

1. Your dashboard should have at least 4 panels
2. All panels should be showing data
3. The dashboard should be properly labeled and organized

## Troubleshooting

- If you see "No data" in panels:
  - Check if the Prometheus data source is correctly configured
  - Verify that the payment-api service is running
  - Check Prometheus targets at http://localhost:9090/targets

## Cleanup

Keep the dashboard as we'll use it in the next lab.

## Next Steps

Proceed to [Lab 3: Log Management](../lab3-log-management/README.md)
