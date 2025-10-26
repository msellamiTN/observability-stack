# Quick Start Guide: ODDO BHF Observability Stack

## Prerequisites
- Docker and Docker Compose
- kubectl (for Kubernetes deployment)
- A running Kubernetes cluster (minikube, Docker Desktop, or cloud provider)

## Getting Started

### 1. Clone and Setup
```bash
# Create project directory
mkdir -p ~/observability-stack
cd ~/observability-stack

# Copy the configuration files
cp .env.example .env
```

### 2. Configure Environment
Edit the `.env` file with your actual credentials:
```bash
nano .env  # or use your preferred editor
```

### 3. Deployment Options

#### Option A: Docker Compose (Development)
```bash
docker-compose up -d
```
# 1. Créer l'environnement
```bash
mkdir -p ~/grafana-training/
clone https://github.com/msellamiTN/Grafana-Stack.git
cd ~/grafana-training/Grafana-Stack/observability-stack/
```
# 2. Lancer Grafana
```bash
sudo chmod +x deploy.sh
sudo ./deploy.sh
```
# 3. Vérifier le démarrage
```bash
docker logs grafana-oddo | tail -5
```
# Attendu: "Server is running" ou "HTTP Server Listen"

#### Option B: Kubernetes (Production)
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Wait for all pods to be ready
kubectl get pods -n ebanking-observability --watch
```

## Accessing Services

| Service | URL | Port | Credentials |
|---------|-----|------|-------------|
| Grafana | http://localhost:3000 | 3000 | From .env |
| Prometheus | http://localhost:9090 | 9090 | - |
| Loki | http://localhost:3100 | 3100 | - |
| MinIO | http://localhost:9001 | 9001 | From .env |

## Verifying the Installation

Check all services are running:
```bash
docker-compose ps
# or for Kubernetes
kubectl get pods -n ebanking-observability
```

## Next Steps
- Configure alerts in Alertmanager
- Set up additional data sources in Grafana
- Configure backup for persistent data

## Troubleshooting
- If ports are in use, check and update the `.env` file
- Check logs with `docker-compose logs` or `kubectl logs`
- Ensure all environment variables in `.env` are properly set
