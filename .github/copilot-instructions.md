# Instructions pour les Agents AI - Stack d'Observabilité ODDO BHF

## 🏗️ Architecture Globale

Ce projet est une stack d'observabilité complète pour le monitoring d'une application e-banking, composée de :

- **Couche Visualisation** : Grafana (port 3000)
  - Tableaux de bord, alertes, gestion utilisateurs
  - RBAC et authentification intégrés
  
- **Sources de Données** :
  - Prometheus (9090) - Métriques
  - InfluxDB (8086) - Séries temporelles 
  - Loki (3100) - Logs
  - Tempo (4317) - Traces distribuées
  - MS SQL Server (1433) - Données métier e-banking
  
- **Composants Métier** :
  - Payment API (instrumenté OpenTelemetry)
  - E-Banking Metrics Exporter
  - Mock Payment API

## 🔑 Conventions Clés

### Télémétrie
- **Nommage des métriques** : snake_case, préfixé par le service
- **Labels obligatoires** : `environment`, `service_name`, `deployment_region`
- **Cardinality control** : Limitez les dimensions à haute cardinalité
- **Format des logs** : JSON structuré pour lisibilité machine
- **Sampling des traces** : Configurable par service

### Patterns de Monitoring
1. **RED Method** (Request, Error, Duration)
2. **USE Method** (Utilisation, Saturation, Erreurs)
3. **Four Golden Signals** (Latence, Trafic, Erreurs, Saturation)
4. **SLI/SLO Framework**

## 🛠️ Workflow Développeur

### Installation
```bash
# 1. Créer les dossiers requis
mkdir -p prometheus/rules alertmanager influxdb/{config,data,logs}

# 2. Copier et configurer l'environnement
cp .env.example .env

# 3. Démarrer la stack
docker-compose up -d
```

### Points de Monitoring
- **Health** : `http://localhost:8888/health`
- **Metrics** : `http://localhost:8888/metrics`
- **Traces** : OpenTelemetry OTLP via gRPC (4317)

### Variables d'Environnement Essentielles
```
SERVICE_NAME=<service>
SERVICE_VERSION=<version>
DEPLOYMENT_ENVIRONMENT=<env>
DEPLOYMENT_REGION=<region>
```

## 🔌 Points d'Intégration 

### API E-Banking
- **Authentification** : Basic Auth / Bearer Token
- **Base URL** : `http://localhost:8080/api/v1`
- **Rate Limits** : 1000 req/s par client
- **Timeouts** : 30s par défaut

### OpenTelemetry
- SDK .NET avec auto-instrumentation
- Détecteurs de ressources : Container, Host, Process
- Instrumentations : ASP.NET, HTTP, SQL, gRPC, EF

## 📊 Organisation des Dashboards

Structure recommandée en 4 sections :
1. KPIs métier (transactions/s, taux de succès)
2. Performance système (RED metrics)
3. Infrastructure (USE metrics)
4. Traces et logs corrélés

## 🚨 Conventions d'Alerting

- **Niveaux** : critical, warning, info
- **Labels** : team, severity, service
- **Annotations** : description, runbook_url
- **Fenêtres multiples** pour les SLO
- **Routage** basé sur les labels d'équipe

## 📚 Fichiers Clés

- `docker-compose.yml` - Configuration des services
- `prometheus/rules/` - Règles d'alerte
- `grafana/provisioning/` - Configuration auto Grafana
- `otel-config.yaml` - Configuration OpenTelemetry
- `.env` - Variables d'environnement

Pour plus de détails, consultez `DEPLOYMENT-GUIDE.md` et `EBANKING_SETUP_GUIDE.md`.