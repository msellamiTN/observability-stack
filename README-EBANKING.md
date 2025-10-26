# ODDO BHF Observability Stack - Complete Setup

## 🚀 What's Included

✅ **Complete eBanking Metrics Exporter** (Go-based)
✅ **Grafana Dashboard** with 3 key metrics panels
✅ **Prometheus Configuration** to scrape eBanking metrics
✅ **Docker Compose Setup** with all services

## 📊 Metrics Available

- **Transactions Rate**: Transactions processed per minute
- **Active Sessions**: Current number of active user sessions
- **Request Duration**: 95th and 99th percentile response times

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install Go (for building the exporter)
# Ubuntu/Debian:
sudo apt update && sudo apt install -y golang-go

# macOS:
brew install go
```

### 2. Configure Environment
```bash
# Copy and edit environment file
cp .env.example .env
nano .env  # Edit with your credentials
```

### 3. Build and Run
```bash
# Build the Go exporter
cd ebanking-exporter
go mod tidy
go build -o ebanking-exporter

# Start the entire stack
cd ..
docker compose up -d
```

### 4. Access the Services

| Service | URL | Port |
|---------|-----|------|
| **Grafana** (with eBanking Dashboard) | http://localhost:3000 | 3000 |
| **Prometheus** | http://localhost:9090 | 9090 |
| **eBanking Exporter** | http://localhost:9201 | 9201 |
| **Loki** | http://localhost:3100 | 3100 |
| **MinIO Console** | http://localhost:9001 | 9001 |

## 📈 Using the Dashboard

1. **Access Grafana**: http://localhost:3000
2. **Login**: Use credentials from your `.env` file
3. **View Dashboard**:
   - Navigate to **Dashboards** → **Browse**
   - Look for **"eBanking"** folder
   - Open **"eBanking Metrics"** dashboard

### Dashboard Panels:
- **Transactions Rate**: Shows transactions per minute over time
- **Active Sessions**: Displays current active user sessions
- **Request Duration**: Shows 95th and 99th percentile response times

## 🔧 Customizing the Exporter

### Adding New Metrics

Edit `ebanking-exporter/main.go`:

```go
// Add a new counter
var newMetric = prometheus.NewCounter(
    prometheus.CounterOpts{
        Name: "my_new_metric_total",
        Help: "Description of my metric",
    },
)

// Increment it in the simulation loop
newMetric.Inc()
```

### Configuration

The exporter simulates metrics for demonstration. In production, you would:

1. Connect to your eBanking database
2. Query real transaction data
3. Calculate actual session counts
4. Measure real API response times

## 🛠️ Troubleshooting

### Check if services are running:
```bash
docker compose ps
```

### View logs:
```bash
docker compose logs ebanking_metrics_exporter
docker compose logs prometheus
```

### Check metrics endpoint:
```bash
curl http://localhost:9201/metrics
```

### Verify Prometheus is scraping:
- Go to http://localhost:9090/targets
- Look for "ebanking-exporter" target

## 🔒 Security Notes

- All credentials are stored in `.env` file (don't commit to git!)
- Services run with `no-new-privileges` security option
- Dashboard is automatically provisioned on startup

## 📚 Next Steps

1. **Add Alerts**: Configure Alertmanager rules for key metrics
2. **Add More Dashboards**: Create dashboards for other services
3. **Production Setup**: Move to Kubernetes deployment
4. **Real Data Integration**: Connect to actual eBanking systems

## 🆘 Support

The stack includes:
- ✅ Complete observability setup
- ✅ Pre-configured Grafana dashboard
- ✅ Working metrics exporter
- ✅ All configuration files

Everything should work out of the box! 🎉
