# Lab 1: Environment Setup

## Objective
Set up the complete observability stack and verify all components are working correctly.

## Tasks

### 1. Clone the Repository

```bash
mkdir -p ~/grafana-training/
git clone https://github.com/msellamiTN/Grafana-Stack.git
cd ~/grafana-training/Grafana-Stack/observability-stack/
```

### 2. Start the Services

```bash
docker-compose up -d
```

### 3. Verify Services

Check if all containers are running:

```bash
docker-compose ps
```

Expected output should show all services as "Up".

### 4. Access the Services

1. **Grafana**
   - URL: http://localhost:3000
   - Username: `admin`
   - Password: `GrafanaSecure123!Change@Me`

2. **Prometheus**
   - URL: http://localhost:9090

3. **InfluxDB**
   - URL: http://localhost:8086
   - Username: `admin`
   - Password: `InfluxSecure123!Change@Me`

4. **Payment API**
   - Swagger UI: http://localhost:8080/docs

## Verification

1. In Grafana, go to Configuration > Data Sources
2. Verify that Prometheus and InfluxDB data sources are configured
3. Check that you can access the Prometheus and InfluxDB UIs

## Troubleshooting

If any service fails to start:

1. Check logs for the specific service:
   ```bash
   docker-compose logs -f <service_name>
   ```

2. Common issues:
   - Port conflicts: Ensure ports 3000, 9090, 8086 are not in use
   - Permission issues: Run with `sudo` if needed
   - Insufficient resources: Check Docker resource allocation

## Cleanup (Optional)

To stop all services:

```bash
docker-compose down
```

## Next Steps

Proceed to [Lab 2: Basic Monitoring](../lab2-basic-monitoring/README.md)
