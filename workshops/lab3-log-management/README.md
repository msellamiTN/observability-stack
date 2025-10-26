# Lab 3: Log Management with Loki

## Objective
Learn how to collect, query, and visualize logs using Loki and Grafana.

## Prerequisites
- Completed Lab 1 & 2
- All services should be running

## Tasks

### 1. Explore Loki Data Source

1. In Grafana, go to Configuration > Data Sources
2. Click on "Loki" (or add it if not present)
3. Set URL to `http://loki:3100`
4. Click "Save & Test"

### 2. Basic Log Queries

1. In Grafana, go to Explore
2. Select "Loki" as data source
3. Try these log queries:
   - `{container="payment-api"}` - All logs from payment-api
   - `{container="payment-api"} |~ "error"` - Error logs
   - `{container="payment-api"} | json` - Parse JSON logs

### 3. Create a Logs Panel

1. Open your "Payment API Monitoring" dashboard
2. Add a new panel
3. Set visualization to "Logs"
4. Use query: `{container="payment-api"}`
5. Set panel title: "Payment API Logs"
6. Enable "Show time" and "Show labels"

### 4. Log Analysis

1. In Explore, try these advanced queries:
   ```
   # Count logs by level
   count_over_time({container="payment-api"} | json | level!="" [5m])
   
   # Error rate
   sum(rate({container="payment-api"} |~ "error" [5m]))
   ```

## Exercises

1. Create a panel showing error rate over time
2. Add a log panel filtered to show only errors
3. Create a pie chart of log levels

## Verification

1. Can you see logs from the payment-api?
2. Can you filter logs by error level?
3. Are your log panels updating in real-time?

## Troubleshooting

- If no logs appear:
  - Check if Loki is running: `docker-compose ps | grep loki`
  - Check Promtail logs: `docker-compose logs -f promtail`
  - Verify log files exist in the container

## Cleanup

Keep your dashboard for the next lab.

## Next Steps

Proceed to [Lab 4: Alerting](../lab4-alerting/README.md)
