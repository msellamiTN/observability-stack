# eBanking Metrics Exporter

A Prometheus metrics exporter for eBanking applications, written in Python.

## Features

This exporter provides the following metrics:

### Counters
- `ebanking_transactions_processed_total` - Total transactions by type and status
- `ebanking_login_attempts_total` - Login attempts by status
- `ebanking_api_errors_total` - API errors by type

### Gauges
- `ebanking_active_sessions` - Current active user sessions
- `ebanking_account_balance_total` - Total account balance by currency
- `ebanking_database_connections` - Current database connections

### Histograms
- `ebanking_request_duration_seconds` - Request duration by endpoint
- `ebanking_transfer_amount` - Transfer amounts distribution

## Metrics Endpoint

- **Port:** 9200
- **Path:** `/metrics`
- **URL:** `http://localhost:9200/metrics`

## Running Locally

### Using Docker

```bash
# Build the image
docker build -t ebanking-exporter .

# Run the container
docker run -p 9200:9200 ebanking-exporter
```

### Using Python

```bash
# Install dependencies
pip install -r requirements.txt

# Run the exporter
python main.py
```

## Running with Docker Compose

The exporter is included in the observability stack:

```bash
# Start all services
docker-compose up -d

# Start only the exporter
docker-compose up -d ebanking_metrics_exporter

# View logs
docker-compose logs -f ebanking_metrics_exporter
```

## Prometheus Configuration

Add this scrape config to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'ebanking-exporter'
    static_configs:
      - targets: ['ebanking_metrics_exporter:9200']
    scrape_interval: 10s
```

## Sample Metrics Output

```
# HELP ebanking_transactions_processed_total Total number of processed transactions
# TYPE ebanking_transactions_processed_total counter
ebanking_transactions_processed_total{status="success",transaction_type="transfer"} 1234.0

# HELP ebanking_active_sessions Current number of active sessions
# TYPE ebanking_active_sessions gauge
ebanking_active_sessions 127.0

# HELP ebanking_request_duration_seconds Time taken to process requests
# TYPE ebanking_request_duration_seconds histogram
ebanking_request_duration_seconds_bucket{endpoint="/api/transfer",le="0.1"} 45.0
```

## Environment Variables

Currently no environment variables are required. The exporter runs with default settings.

## Health Check

The metrics endpoint also serves as a health check:

```bash
curl http://localhost:9200/metrics
```

If the exporter is healthy, it will return Prometheus-formatted metrics.

## Development

### Adding New Metrics

Edit `main.py` and add your metric definition:

```python
from prometheus_client import Counter

my_metric = Counter(
    'ebanking_my_metric_total',
    'Description of my metric',
    ['label1', 'label2']
)

# Use it
my_metric.labels(label1='value1', label2='value2').inc()
```

### Testing

```bash
# Run the exporter
python main.py

# In another terminal, query metrics
curl http://localhost:9200/metrics | grep ebanking
```

## Troubleshooting

### Port already in use

```bash
# Check what's using port 9200
netstat -ano | findstr :9200  # Windows
lsof -i :9200                 # Linux/Mac

# Change port in main.py if needed
port = 9201  # Instead of 9200
```

### Container keeps restarting

```bash
# Check logs
docker-compose logs ebanking_metrics_exporter

# Rebuild the image
docker-compose build --no-cache ebanking_metrics_exporter
docker-compose up -d ebanking_metrics_exporter
```

## License

MIT
