# Grafana Observability Stack - Deployment Guide

## 🚀 Quick Deployment

Use the `deploy.sh` script to automatically build and deploy the entire stack.

### Prerequisites

- Docker and Docker Compose installed
- `.env` file configured (will be created from `.env.example` if missing)
- Sufficient system resources (8GB RAM recommended)

### Deployment Steps

```bash
# 1. Navigate to the stack directory
cd observability-stack

# 2. Make the deploy script executable
chmod +x deploy.sh

# 3. Run the deployment
./deploy.sh
```

That's it! The script will handle everything automatically.

## 📋 What the Deploy Script Does

The `deploy.sh` script performs the following actions:

### 1. Pre-Deployment Checks ✓
- Checks if Docker is running
- Verifies Docker Compose is available
- Loads environment variables from `.env`
- Creates `.env` from `.env.example` if needed

### 2. Directory Setup 📁
- Creates required directories:
  - `prometheus/rules`
  - `alertmanager`
  - `influxdb/{config,data,logs,backup,keys}`
- Sets proper permissions

### 3. Volume Configuration 🗄️
- Creates Docker volumes for Grafana:
  - `grafana_data`
  - `grafana_config`
  - `grafana_provisioning`

### 4. Configuration Files 📝
- Creates Grafana configuration (`grafana.ini`)
- Sets up data source provisioning:
  - Prometheus
  - Loki
  - InfluxDB
- Configures proper permissions (user 472:472)

### 5. Container Deployment 🐳
- Stops any existing containers
- Builds all images (including custom ones):
  - eBanking exporter (Python)
  - Payment API (Python)
- Starts all services:
  - Grafana
  - Prometheus
  - Loki
  - InfluxDB
  - Alertmanager
  - Payment API
  - eBanking Exporter
  - Node Exporter
  - Promtail
  - PostgreSQL
  - MySQL
  - MinIO

### 6. Service Initialization ⏳
- Waits 30 seconds for services to start
- Verifies critical services are running
- Configures InfluxDB CLI
- Resets Grafana admin password

### 7. Post-Deployment ✅
- Displays access URLs
- Shows credentials
- Provides helpful commands

## 🔧 Configuration

### Environment Variables (.env)

The script uses these key variables:

```env
# InfluxDB
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=InfluxSecure123!Change@Me
INFLUXDB_ORG=bhf-oddo
INFLUXDB_BUCKET=payments
INFLUXDB_TOKEN=my-super-secret-auth-token
INFLUXDB_RETENTION=1w

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=GrafanaSecure123!Change@Me
GF_SECURITY_SECRET_KEY=GrafanaSecret123!Change@Me

# MySQL
MYSQL_ROOT_PASSWORD=MySQLRoot123!Change@Me
MYSQL_DATABASE=observability
MYSQL_USER=appuser
MYSQL_PASSWORD=MySQLApp123!Change@Me

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=MinioSecure123!Change@Me
```

**⚠️ Important:** Change all default passwords before production deployment!

## 📊 Access URLs

After successful deployment:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Prometheus** | http://localhost:9090 | No auth |
| **Loki** | http://localhost:3100 | No auth |
| **InfluxDB** | http://localhost:8086 | admin / InfluxSecure123!Change@Me |
| **Alertmanager** | http://localhost:9093 | No auth |
| **Payment API** | http://localhost:8080 | No auth |
| **eBanking Exporter** | http://localhost:9201 | No auth |
| **MinIO** | http://localhost:9000 | minioadmin / MinioSecure123!Change@Me |
| **MySQL** | localhost:3306 | appuser / MySQLApp123!Change@Me |
| **PostgreSQL** | localhost:5432 | grafana / grafana |

## 🔍 Verification

### Check All Services

```bash
# View running containers
docker-compose ps

# All services should show "Up" or "Up (healthy)"
```

### Test Individual Services

```bash
# Grafana
curl http://localhost:3000/api/health

# Prometheus
curl http://localhost:9090/-/healthy

# Loki
curl http://localhost:3100/ready

# InfluxDB
curl http://localhost:8086/health

# Payment API
curl http://localhost:8080/health

# eBanking Exporter
curl http://localhost:9201/metrics
```

### View Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs grafana
docker-compose logs prometheus
docker-compose logs payment-api

# Follow logs in real-time
docker-compose logs -f
```

## 🐛 Troubleshooting

### Script Fails to Start

**Check Docker is running:**
```bash
docker info
```

**Check Docker Compose:**
```bash
docker-compose --version
# or
docker compose version
```

### Services Not Starting

**View logs:**
```bash
docker-compose logs [service-name]
```

**Common issues:**
1. **Port conflicts** - Check if ports are already in use
2. **Insufficient resources** - Ensure enough RAM/CPU
3. **Permission errors** - Run with appropriate permissions

### Re-run Deployment

```bash
# Clean up and redeploy
docker-compose down -v
./deploy.sh
```

## 🔄 Updates and Maintenance

### Update Services

```bash
# Pull latest images
docker-compose pull

# Rebuild custom images
docker-compose build

# Restart with updates
docker-compose up -d
```

### Backup Data

```bash
# Backup volumes
docker run --rm -v observability-stack_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz /data

docker run --rm -v observability-stack_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data

docker run --rm -v observability-stack_influxdb_data:/data -v $(pwd):/backup alpine tar czf /backup/influxdb-backup.tar.gz /data
```

### Stop Services

```bash
# Stop all services
docker-compose stop

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

## 🌐 Remote Server Deployment

### For Remote Server (51.79.24.138)

```bash
# 1. SSH to server
ssh user@51.79.24.138

# 2. Navigate to stack directory
cd /path/to/observability-stack

# 3. Update .env with server-specific settings
nano .env

# 4. Run deployment
./deploy.sh

# 5. Verify services
docker-compose ps
```

### Remote Access URLs

Replace `localhost` with your server IP:
- Grafana: http://51.79.24.138:3000
- Prometheus: http://51.79.24.138:9090
- InfluxDB: http://51.79.24.138:8086

## 📝 Post-Deployment Tasks

### 1. Change Default Passwords

```bash
# Grafana (via UI or CLI)
docker-compose exec grafana grafana-cli admin reset-admin-password NewPassword123

# InfluxDB (via UI)
# Login to http://localhost:8086 and change password

# MySQL
docker-compose exec mysql mysql -u root -p -e "ALTER USER 'root'@'%' IDENTIFIED BY 'NewPassword123';"
```

### 2. Configure Firewall (Remote Server)

```bash
# Allow required ports
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 8086/tcp  # InfluxDB
```

### 3. Set Up SSL/TLS (Production)

Use a reverse proxy like Nginx or Traefik for HTTPS.

### 4. Configure Backups

Set up automated backups for:
- Grafana dashboards
- Prometheus data
- InfluxDB data

## ✅ Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] `.env` file configured with secure passwords
- [ ] Sufficient system resources available
- [ ] Ports are not in use by other services
- [ ] `deploy.sh` script is executable
- [ ] Script runs without errors
- [ ] All services show "Up" status
- [ ] Can access Grafana UI
- [ ] Can access Prometheus UI
- [ ] Data sources configured in Grafana
- [ ] Metrics are being collected
- [ ] Logs are being aggregated
- [ ] Health checks passing
- [ ] Default passwords changed
- [ ] Firewall configured (if remote)
- [ ] Backup strategy in place

## 🎯 Summary

**Single Command Deployment:**
```bash
./deploy.sh
```

**What You Get:**
- ✅ Complete observability stack
- ✅ Pre-configured data sources
- ✅ Automated setup
- ✅ Health checks enabled
- ✅ Time synchronization fixed
- ✅ All services ready to use

**Next Steps:**
1. Access Grafana: http://localhost:3000
2. Explore pre-configured dashboards
3. Start monitoring your applications
4. Set up custom alerts

---

**Last Updated:** October 21, 2025  
**Script:** deploy.sh  
**Status:** Production Ready ✅
