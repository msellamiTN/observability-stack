# 🚀 Lab 1.2 : Installation et Configuration de Grafana OSS

**⏱️ Durée** : 2 heures | **👤 Niveau** : Débutant | **💻 Type** : Pratique

---

## 📋 Table des Matières

1. [Objectifs](#-objectifs)
2. [Prérequis](#-prérequis)
3. [Architecture](#-architecture)
4. [Étape 1 : Vérification de l'Environnement](#-étape-1--vérification-de-lenvironnement)
5. [Étape 2 : Configuration du Fichier .env](#-étape-2--configuration-du-fichier-env)
6. [Étape 3 : Déploiement de la Stack](#-étape-3--déploiement-de-la-stack)
7. [Étape 4 : Première Connexion](#-étape-4--première-connexion)
8. [Étape 5 : Configuration Initiale](#-étape-5--configuration-initiale)
9. [Validation](#-validation)
10. [Troubleshooting](#-troubleshooting)

---

## 🎯 Objectifs

À la fin de ce lab, vous serez capable de :

✅ Vérifier les prérequis système (Docker, Docker Compose)  
✅ Configurer les variables d'environnement de la stack  
✅ Déployer l'ensemble de la stack d'observabilité  
✅ Accéder à l'interface Grafana  
✅ Effectuer la configuration initiale de sécurité  
✅ Naviguer dans l'interface utilisateur  
✅ Résoudre les problèmes courants de démarrage  

---

## 🛠️ Prérequis

### Logiciels Requis

| Logiciel | Version Minimum | Vérification |
|----------|-----------------|--------------|
| **Docker Desktop** | 20.10+ | `docker --version` |
| **Docker Compose** | v2.0+ | `docker compose version` |
| **Git** | 2.0+ | `git --version` |
| **Navigateur** | Chrome/Firefox/Edge | - |

### Ressources Système

| Ressource | Minimum | Recommandé |
|-----------|---------|------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 4 GB | 8 GB |
| **Disk** | 10 GB libre | 20 GB libre |
| **Réseau** | Internet | Stable |

### Connaissances

- 🔹 Ligne de commande de base (bash/PowerShell)
- 🔹 Concepts Docker (conteneurs, images, volumes)
- 🔹 Notions réseau (ports, localhost)

---

## 🏗️ Architecture

Voici ce que vous allez déployer :

```
┌─────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY STACK                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  📊 VISUALIZATION                                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Grafana (Port 3000)                                  │   │
│  │  - Dashboards                                         │   │
│  │  - Alerting                                           │   │
│  │  - User Management                                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ↓                                     │
│  📈 DATA SOURCES                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Prometheus  │  │   InfluxDB   │  │   MS SQL     │      │
│  │  Port 9090   │  │  Port 8086   │  │  Port 1433   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     Loki     │  │    Tempo     │  │    MySQL     │      │
│  │  Port 3100   │  │  Port 3200   │  │  Port 3306   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  🔔 ALERTING                                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Alertmanager (Port 9093)                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  🌐 NETWORK: observability (bridge)                         │
│  💾 VOLUMES: Persistent storage for all services            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Fichiers de Configuration de la Stack

Avant de démarrer, il est important de comprendre les fichiers de configuration utilisés par chaque composant.

### 📂 Structure des Fichiers

```
observability-stack/
├── docker-compose.yml          # Orchestration de tous les services
├── .env                        # Variables d'environnement (secrets)
├── grafana/
│   ├── grafana.ini            # Configuration principale Grafana
│   └── provisioning/          # Configuration automatique
│       ├── datasources/       # Sources de données pré-configurées
│       │   └── datasources.yaml
│       ├── dashboards/        # Dashboards pré-configurés
│       ├── alerting/          # Règles d'alertes
│       └── plugins/           # Plugins Grafana
├── prometheus/
│   ├── prometheus.yml         # Configuration Prometheus
│   └── rules/                 # Règles d'alertes Prometheus
│       ├── alert_rules.yml
│       └── ebanking-slo-alerts.yml
├── tempo/
│   └── tempo.yaml             # Configuration Tempo (tracing)
├── alertmanager/
│   └── alertmanager.yml       # Configuration Alertmanager
└── promtail/
    └── promtail-config.yaml   # Configuration collecteur de logs
```

---

### 🔧 1. Grafana - grafana.ini

**Emplacement** : `grafana/grafana.ini`

Ce fichier contient la configuration principale de Grafana.

#### Sections Principales

```ini
# ============================================
# 🌐 SERVER - Configuration du serveur web
# ============================================
[server]
protocol = http                    # Protocole (http/https)
http_port = 3000                   # Port d'écoute
domain = localhost                 # Domaine
root_url = http://localhost:3000   # URL racine

# ============================================
# 🔐 SECURITY - Sécurité et authentification
# ============================================
[security]
admin_user = admin                 # Nom d'utilisateur admin
admin_password = GrafanaSecure123! # Mot de passe (à changer!)
secret_key = GrafanaSecret123!     # Clé secrète pour cookies
disable_gravatar = true            # Désactiver Gravatar
allow_embedding = true             # Permettre iframe
cookie_secure = false              # true en HTTPS
cookie_samesite = lax              # Protection CSRF

# ============================================
# 👥 USERS - Gestion des utilisateurs
# ============================================
[users]
allow_sign_up = false              # Désactiver l'inscription publique

# ============================================
# 🔓 AUTH - Authentification anonyme
# ============================================
[auth.anonymous]
enabled = false                    # Désactiver accès anonyme

# ============================================
# 💾 DATABASE - Base de données Grafana
# ============================================
[database]
type = sqlite3                     # sqlite3, mysql, ou postgres
# Pour production, utilisez PostgreSQL:
# type = postgres
# host = postgres:5432
# name = grafana
# user = grafana
# password = grafana

# ============================================
# 📂 PATHS - Chemins des fichiers
# ============================================
[paths]
provisioning = /etc/grafana/provisioning  # Config auto
data = /var/lib/grafana                   # Données
logs = /var/log/grafana                   # Logs

# ============================================
# 📧 SMTP - Configuration email
# ============================================
[smtp]
enabled = true
host = smtp.gmail.com:587
user = YOUR_GMAIL_ADDRESS@gmail.com
password = YOUR_GMAIL_APP_PASSWORD  # App Password Gmail
from_address = YOUR_GMAIL_ADDRESS@gmail.com
from_name = Grafana Observability Stack

# ============================================
# 🔔 UNIFIED ALERTING - Alertes (Grafana 10+)
# ============================================
[unified_alerting]
enabled = true                     # Activer les alertes
execute_alerts = true              # Exécuter les alertes
max_attempts = 3                   # Tentatives max
min_interval = 10s                 # Intervalle minimum
evaluation_timeout = 30s           # Timeout évaluation

# ============================================
# 📝 LOGGING - Configuration des logs
# ============================================
[log]
mode = console                     # console ou file
level = info                       # debug, info, warn, error
```

#### 💡 Tips - grafana.ini

> **🔐 Sécurité** : Ne mettez JAMAIS de mots de passe en dur dans ce fichier en production. Utilisez les variables d'environnement via `docker-compose.yml`.

> **✅ Bonne Pratique** : En production, utilisez PostgreSQL au lieu de SQLite3 pour de meilleures performances et la haute disponibilité.

> **⚠️ Attention** : Si vous modifiez `grafana.ini`, vous devez redémarrer Grafana : `docker compose restart grafana`

---

### 🔧 2. Grafana Provisioning - datasources.yaml

**Emplacement** : `grafana/provisioning/datasources/datasources.yaml`

Ce fichier configure automatiquement les sources de données au démarrage de Grafana.

```yaml
# =============================================
# Configuration des Data Sources
# =============================================
apiVersion: 1

# Supprimer les datasources existantes (éviter conflits)
deleteDatasources:
  - name: Prometheus
    orgId: 1

datasources:
  # ============================================
  # 📈 PROMETHEUS - Métriques
  # ============================================
  - name: Prometheus
    type: prometheus              # Type de datasource
    access: proxy                 # proxy ou direct
    url: http://prometheus:9090   # URL interne Docker
    isDefault: true               # Datasource par défaut
    editable: true                # Modifiable via UI
    uid: prometheus               # ID unique
    version: 1
    jsonData:
      httpMethod: POST            # POST pour grandes requêtes
      timeInterval: 15s           # Intervalle de scrape
      queryTimeout: 60s           # Timeout requêtes
      incrementalQuerying: true   # Requêtes incrémentales
      incrementalQueryOverlapWindow: 10m

  # ============================================
  # 💾 MS SQL SERVER - Base de données E-Banking
  # ============================================
  - name: MS SQL Server - E-Banking
    type: mssql
    access: proxy
    url: mssql:1433               # Hôte:Port
    database: EBankingDB          # Nom de la base
    user: sa                      # Utilisateur
    isDefault: false
    editable: true
    uid: mssql_ebanking
    version: 1
    secureJsonData:
      password: 'EBanking@Secure123!'  # Mot de passe (chiffré)
    jsonData:
      maxOpenConns: 100           # Connexions max
      maxIdleConns: 100           # Connexions idle
      connMaxLifetime: 14400      # Durée de vie (secondes)
      encrypt: 'false'            # Chiffrement TLS
      sslmode: 'disable'
      authenticator: 'SQL Server Authentication'

  # ============================================
  # 🗄️ INFLUXDB - Séries temporelles
  # ============================================
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    isDefault: false
    editable: true
    uid: influxdb
    jsonData:
      version: Flux              # Utiliser Flux (InfluxDB 2.x)
      organization: myorg        # Organisation InfluxDB
      defaultBucket: payments    # Bucket par défaut
      tlsSkipVerify: true
    secureJsonData:
      token: 'my-super-secret-auth-token'  # Token API

  # ============================================
  # 📝 LOKI - Logs
  # ============================================
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    editable: true
    uid: loki
    jsonData:
      maxLines: 1000             # Lignes max par requête
      derivedFields:             # Corrélation logs → traces
        - datasourceUid: tempo
          matcherRegex: "trace_id=(\\w+)"
          name: TraceID
          url: '$${__value.raw}'

  # ============================================
  # 🔍 TEMPO - Traces distribuées
  # ============================================
  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
    isDefault: false
    editable: true
    uid: tempo
    jsonData:
      tracesToLogs:              # Corrélation traces → logs
        datasourceUid: loki
        tags: ['job', 'instance', 'pod', 'namespace']
        mappedTags: [{ key: 'service.name', value: 'service' }]
        mapTagNamesEnabled: true
        spanStartTimeShift: '-1h'
        spanEndTimeShift: '1h'
      tracesToMetrics:           # Corrélation traces → métriques
        datasourceUid: prometheus
        tags: [{ key: 'service.name', value: 'service' }]
        queries:
          - name: 'Sample query'
            query: 'sum(rate(tempo_spanmetrics_latency_bucket{$__tags}[5m]))'
      serviceMap:
        datasourceUid: prometheus
      nodeGraph:
        enabled: true
```

#### 💡 Tips - datasources.yaml

> **✅ Bonne Pratique** : Utilisez le provisioning pour configurer automatiquement les datasources. Cela garantit la reproductibilité.

> **🔐 Sécurité** : Les mots de passe dans `secureJsonData` sont chiffrés par Grafana au démarrage.

> **🔗 Corrélation** : Configurez `derivedFields` et `tracesToLogs` pour naviguer entre logs, métriques et traces.

---

### 🔧 3. Prometheus - prometheus.yml

**Emplacement** : `prometheus/prometheus.yml`

Configuration de Prometheus pour la collecte de métriques.

```yaml
# =============================================
# Configuration Globale
# =============================================
global:
  scrape_interval: 15s           # Fréquence de collecte
  evaluation_interval: 15s       # Fréquence évaluation règles
  scrape_timeout: 10s            # Timeout scrape
  external_labels:               # Labels ajoutés à toutes les métriques
    cluster: 'ebanking-prod'
    env: 'production'

# =============================================
# 🔔 Alertmanager
# =============================================
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

# =============================================
# 📋 Règles d'Alertes
# =============================================
rule_files:
  - "/etc/prometheus/rules/*.yml"

# =============================================
# 🎯 Scrape Configs - Targets à monitorer
# =============================================
scrape_configs:
  # Prometheus lui-même
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Grafana
  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']

  # Node Exporter (métriques système)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Application E-Banking
  - job_name: 'ebanking-exporter'
    static_configs:
      - targets: ['ebanking_metrics_exporter:9200']
    scrape_interval: 10s         # Override global

  # Payment API avec OpenTelemetry
  - job_name: 'payment-api-instrumented'
    metrics_path: '/metrics'
    scrape_interval: 10s
    scrape_timeout: 5s
    static_configs:
      - targets: ['payment-api_instrumented:8888']
        labels:                  # Labels personnalisés
          service: 'payment-api-instrumented'
          namespace: 'ebanking.observability'
          environment: 'production'

  # Tempo (métriques de tracing)
  - job_name: 'tempo'
    metrics_path: '/metrics'
    scrape_interval: 15s
    static_configs:
      - targets: ['tempo:3200']
        labels:
          service: 'tempo'
          component: 'tracing-backend'
```

#### 💡 Tips - prometheus.yml

> **⏱️ Scrape Interval** : 15s est un bon compromis. Réduisez à 5-10s pour des métriques critiques, augmentez à 30-60s pour économiser des ressources.

> **🏷️ Labels** : Utilisez des labels cohérents (`service`, `environment`, `namespace`) pour faciliter les requêtes PromQL.

> **🔄 Reload** : Rechargez la config sans redémarrer : `curl -X POST http://localhost:9090/-/reload`

---

### 🔧 4. Tempo - tempo.yaml

**Emplacement** : `tempo/tempo.yaml`

Configuration de Tempo pour le distributed tracing.

```yaml
# =============================================
# 🌐 Server
# =============================================
server:
  http_listen_port: 3200

# =============================================
# 📥 Distributor - Réception des traces
# =============================================
distributor:
  receivers:
    # Jaeger
    jaeger:
      protocols:
        thrift_http:
          endpoint: 0.0.0.0:14268
        grpc:
          endpoint: 0.0.0.0:14250
    # Zipkin
    zipkin:
      endpoint: 0.0.0.0:9411
    # OpenTelemetry (OTLP)
    otlp:
      protocols:
        http:
          endpoint: 0.0.0.0:4318  # OTLP HTTP
        grpc:
          endpoint: 0.0.0.0:4317  # OTLP gRPC

# =============================================
# 📊 Metrics Generator - Génération de métriques
# =============================================
metrics_generator:
  registry:
    external_labels:
      source: tempo
      cluster: observability-stack
      environment: production
  storage:
    path: /var/tempo/generator/wal
    remote_write:
      - url: http://prometheus:9090/api/v1/write
        send_exemplars: true     # Envoyer les exemplars (trace IDs)

# =============================================
# 💾 Storage - Stockage des traces
# =============================================
storage:
  trace:
    backend: local               # local, s3, gcs, azure
    wal:
      path: /var/tempo/wal
    local:
      path: /var/tempo/blocks

# =============================================
# ⚙️ Overrides - Configuration avancée
# =============================================
overrides:
  defaults:
    metrics_generator:
      processors: 
        - service-graphs        # Graphe de services
        - span-metrics          # Métriques de spans
        - local-blocks
      processor:
        service_graphs:
          dimensions:            # Dimensions pour service graph
            - deployment.environment
            - service.namespace
          histogram_buckets: [0.1, 0.2, 0.4, 0.8, 1.6, 3.2, 6.4, 12.8]
        span_metrics:
          dimensions:            # Dimensions pour span metrics
            - http.method
            - http.status_code
          histogram_buckets: [0.002, 0.004, 0.008, 0.016, 0.032, 0.064, 0.128, 0.256, 0.512, 1.024, 2.048, 4.096, 8.192]
```

#### 💡 Tips - tempo.yaml

> **🔌 Protocoles** : Tempo supporte OTLP (recommandé), Jaeger et Zipkin. Utilisez OTLP pour les nouvelles applications.

> **📊 Metrics Generator** : Active la génération automatique de métriques RED (Rate, Errors, Duration) depuis les traces.

> **🔗 Exemplars** : `send_exemplars: true` permet de lier métriques → traces dans Grafana.

---

### 🔧 5. Docker Compose - docker-compose.yml

**Emplacement** : `docker-compose.yml`

Orchestre tous les services de la stack.

#### Structure d'un Service

```yaml
services:
  grafana:
    image: grafana/grafana-oss:latest  # Image Docker
    container_name: grafana            # Nom du conteneur
    restart: unless-stopped            # Politique de redémarrage
    ports:
      - "3000:3000"                    # Port hôte:conteneur
    environment:                       # Variables d'environnement
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
    volumes:                           # Montage de volumes
      - grafana_data:/var/lib/grafana  # Volume nommé (persistant)
      - ./grafana/grafana.ini:/etc/grafana/grafana.ini  # Bind mount
      - ./grafana/provisioning:/etc/grafana/provisioning
    user: "472:472"                    # UID:GID Grafana
    security_opt:
      - no-new-privileges:true         # Sécurité
    depends_on:                        # Dépendances
      - prometheus
    networks:                          # Réseau
      - observability
```

#### Variables d'Environnement vs Fichiers

| Méthode | Avantages | Inconvénients | Usage |
|---------|-----------|---------------|-------|
| **Variables ENV** | Facile, dynamique | Visible dans `docker inspect` | Dev/Test |
| **Fichiers montés** | Sécurisé, versionnable | Nécessite rebuild | Production |
| **Secrets Docker** | Très sécurisé | Complexe | Production critique |

#### 💡 Tips - docker-compose.yml

> **🔐 Secrets** : Utilisez `${VARIABLE}` pour référencer le fichier `.env`. Ne committez jamais `.env` !

> **💾 Volumes** : Utilisez des volumes nommés (`grafana_data`) pour la persistance, pas des bind mounts pour les données.

> **🌐 Networks** : Créez un réseau dédié (`observability`) pour isoler la stack.

---

## 📝 Exercice Pratique : Modifier une Configuration

### Objectif
Changer le port de Grafana de 3000 à 3001.

### Méthode 1 : Via docker-compose.yml

```yaml
# Dans docker-compose.yml
grafana:
  ports:
    - "3001:3000"  # Port hôte:conteneur
```

```powershell
# Redémarrer
docker compose down
docker compose up -d
```

### Méthode 2 : Via grafana.ini

```ini
# Dans grafana/grafana.ini
[server]
http_port = 3001
root_url = http://localhost:3001
```

```yaml
# Dans docker-compose.yml
grafana:
  ports:
    - "3001:3001"  # Les deux ports doivent correspondre
```

```powershell
# Redémarrer
docker compose restart grafana
```

---

## 🔍 Étape 1 : Vérification de l'Environnement

### 1.1 Vérifier Docker

#### 🪟 Windows (PowerShell)

```powershell
# Vérifier la version de Docker
docker --version
# Attendu : Docker version 20.10.0 ou supérieur

# Vérifier que Docker est en cours d'exécution
docker info
# Si erreur : Démarrer Docker Desktop

# Tester Docker
docker run hello-world
```

#### 🐧 Ubuntu/Linux

```bash
# Vérifier la version de Docker
docker --version

# Vérifier le statut du service
sudo systemctl status docker

# Si Docker n'est pas démarré
sudo systemctl start docker

# Tester Docker
docker run hello-world
```

### 1.2 Vérifier Docker Compose

#### 🪟 Windows (PowerShell)

```powershell
# Vérifier la version
docker compose version
# Attendu : Docker Compose version v2.0.0 ou supérieur

# Si commande non trouvée, vérifier Docker Desktop
Get-Command docker
```

#### 🐧 Ubuntu/Linux

```bash
# Vérifier la version
docker compose version

# Si non installé
sudo apt update
sudo apt install docker-compose-plugin
```

### 1.3 Vérifier les Ressources

#### 🪟 Windows (PowerShell)

```powershell
# Vérifier la RAM disponible
Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory

# Vérifier l'espace disque
Get-PSDrive C | Select-Object Used,Free

# Vérifier les ports disponibles
netstat -an | findstr "3000 9090 8086 1433"
# Aucun résultat = ports libres ✅
```

#### 🐧 Ubuntu/Linux

```bash
# Vérifier la RAM
free -h

# Vérifier l'espace disque
df -h

# Vérifier les ports
sudo netstat -tuln | grep -E '3000|9090|8086|1433'
# Aucun résultat = ports libres ✅
```

### 💡 Tips - Étape 1

> **✅ Bonne Pratique** : Avant de démarrer, assurez-vous d'avoir au moins 8GB de RAM disponible.

> **⚠️ Attention** : Si un port est déjà utilisé, vous devrez soit arrêter le service qui l'utilise, soit modifier le port dans `docker-compose.yml`.

> **🔧 Astuce** : Sous Windows, Docker Desktop doit être configuré pour utiliser WSL2 pour de meilleures performances.

---

## ⚙️ Étape 2 : Configuration du Fichier .env

### 2.1 Naviguer vers le Répertoire

#### 🪟 Windows (PowerShell)

```powershell
# Naviguer vers le répertoire
cd "d:\Data2AI Academy\Grafana\observability-stack"

# Vérifier le contenu
ls
```

#### 🐧 Ubuntu/Linux

```bash
# Naviguer vers le répertoire
cd ~/Grafana/observability-stack

# Vérifier le contenu
ls -la
```

### 2.2 Créer le Fichier .env

#### 🪟 Windows (PowerShell)

```powershell
# Copier le fichier exemple
Copy-Item .env.example .env

# Éditer avec Notepad
notepad .env

# Ou avec VS Code
code .env
```

#### 🐧 Ubuntu/Linux

```bash
# Copier le fichier exemple
cp .env.example .env

# Éditer avec nano
nano .env

# Ou avec vim
vim .env
```

### 2.3 Configuration des Variables

Voici les variables **ESSENTIELLES** à configurer :

```env
# ============================================
# 🔐 GRAFANA CONFIGURATION
# ============================================
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=GrafanaSecure123!Change@Me
GF_SECURITY_SECRET_KEY=GrafanaSecret123!Change@Me

# ============================================
# 🗄️ INFLUXDB CONFIGURATION
# ============================================
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=InfluxSecure123!Change@Me
INFLUXDB_ORG=myorg
INFLUXDB_BUCKET=payments
INFLUXDB_TOKEN=my-super-secret-auth-token
INFLUXDB_RETENTION=1w

# ============================================
# 💾 MS SQL SERVER CONFIGURATION
# ============================================
MSSQL_SA_PASSWORD=EBanking@Secure123!
MSSQL_PID=Developer

# ============================================
# 🐬 MYSQL CONFIGURATION
# ============================================
MYSQL_ROOT_PASSWORD=MySQLRoot123!Change@Me
MYSQL_DATABASE=observability
MYSQL_USER=appuser
MYSQL_PASSWORD=MySQLApp123!Change@Me

# ============================================
# 🐘 POSTGRESQL CONFIGURATION
# ============================================
POSTGRES_USER=grafana
POSTGRES_PASSWORD=grafana
POSTGRES_DB=grafana

# ============================================
# 📦 MINIO CONFIGURATION
# ============================================
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=MinioSecure123!Change@Me
```

### 💡 Tips - Étape 2

> **🔐 Sécurité** : Changez TOUS les mots de passe par défaut avant de déployer en production !

> **✅ Bonne Pratique** : Utilisez des mots de passe d'au moins 16 caractères avec majuscules, minuscules, chiffres et caractères spéciaux.

> **⚠️ Attention** : Ne committez JAMAIS le fichier `.env` dans Git ! Il est déjà dans `.gitignore`.

> **🔧 Astuce** : Utilisez un gestionnaire de mots de passe pour générer des mots de passe sécurisés.

### 🎯 Exigences de Mots de Passe

| Service | Exigences | Exemple |
|---------|-----------|---------|
| **Grafana** | Min 8 caractères | `GrafanaSecure123!` |
| **InfluxDB** | Min 8 caractères | `InfluxSecure123!` |
| **MS SQL** | Min 8 caractères, 1 majuscule, 1 chiffre, 1 spécial | `EBanking@Secure123!` |
| **MySQL** | Min 8 caractères | `MySQLRoot123!` |

---

## 🚀 Étape 3 : Déploiement de la Stack

### 3.1 Démarrer les Services

#### 🪟 Windows (PowerShell)

```powershell
# S'assurer d'être dans le bon répertoire
cd "d:\Data2AI Academy\Grafana\observability-stack"

# Démarrer tous les services en arrière-plan
docker compose up -d

# Suivre les logs en temps réel (optionnel)
docker compose logs -f
# Appuyer sur Ctrl+C pour arrêter de suivre les logs
```

#### 🐧 Ubuntu/Linux

```bash
# S'assurer d'être dans le bon répertoire
cd ~/Grafana/observability-stack

# Démarrer tous les services
docker compose up -d

# Suivre les logs (optionnel)
docker compose logs -f
```

### 3.2 Vérifier le Démarrage

#### 🪟 Windows (PowerShell)

```powershell
# Vérifier l'état de tous les conteneurs
docker compose ps

# Résultat attendu : Tous les services avec status "Up" ou "Up (healthy)"
```

#### 🐧 Ubuntu/Linux

```bash
# Vérifier l'état
docker compose ps

# Vérifier les logs d'un service spécifique
docker compose logs grafana
```

### 3.3 Attendre l'Initialisation

Les services ont besoin de temps pour démarrer complètement.

#### 🪟 Windows (PowerShell)

```powershell
# Attendre 30 secondes
Start-Sleep -Seconds 30

# Vérifier la santé de Grafana
Invoke-WebRequest -Uri http://localhost:3000/api/health -UseBasicParsing
```

#### 🐧 Ubuntu/Linux

```bash
# Attendre 30 secondes
sleep 30

# Vérifier la santé de Grafana
curl http://localhost:3000/api/health
```

### 💡 Tips - Étape 3

> **⏱️ Patience** : Le premier démarrage peut prendre 2-3 minutes car Docker doit télécharger toutes les images.

> **✅ Bonne Pratique** : Utilisez `docker compose up -d` pour démarrer en arrière-plan, pas `docker-compose up` (sans `-d`).

> **🔧 Astuce** : Si un service ne démarre pas, vérifiez ses logs avec `docker compose logs [service-name]`.

> **⚠️ Attention** : N'arrêtez pas les services pendant l'initialisation, cela peut corrompre les données.

### 🎯 Services et Ports

| Service | Port | Status Attendu | Health Check |
|---------|------|----------------|--------------|
| **Grafana** | 3000 | Up (healthy) | http://localhost:3000/api/health |
| **Prometheus** | 9090 | Up | http://localhost:9090/-/healthy |
| **InfluxDB** | 8086 | Up | http://localhost:8086/health |
| **MS SQL** | 1433 | Up (healthy) | Via sqlcmd |
| **Loki** | 3100 | Up | http://localhost:3100/ready |
| **Tempo** | 3200 | Up | http://localhost:3200/ready |
| **Alertmanager** | 9093 | Up | http://localhost:9093/-/healthy |

---

## 🔑 Étape 4 : Première Connexion

### 4.1 Accéder à Grafana

#### 🪟 Windows (PowerShell)

```powershell
# Ouvrir Grafana dans le navigateur par défaut
Start-Process "http://localhost:3000"
```

#### 🐧 Ubuntu/Linux

```bash
# Ouvrir Grafana dans le navigateur
xdg-open http://localhost:3000

# Ou avec Firefox
firefox http://localhost:3000 &

# Ou avec Chrome
google-chrome http://localhost:3000 &
```

### 4.2 Se Connecter

1. **URL** : http://localhost:3000
2. **Username** : `admin`
3. **Password** : `GrafanaSecure123!Change@Me` (ou celui que vous avez défini dans `.env`)

![Login Screen](assets/grafana-login.png)

### 4.3 Premier Écran

Après connexion, vous verrez :

```
┌─────────────────────────────────────────────────────────────┐
│  Grafana                                    [👤 admin ▼]     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  🏠 Welcome to Grafana                                       │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  🎯 Quick Actions                                   │     │
│  │  ├─ 📊 Create your first dashboard                 │     │
│  │  ├─ 🔌 Add your first data source                  │     │
│  │  ├─ 🔔 Set up alerting                             │     │
│  │  └─ 👥 Invite your team                            │     │
│  └────────────────────────────────────────────────────┘     │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 💡 Tips - Étape 4

> **🔐 Sécurité** : Changez immédiatement le mot de passe admin après la première connexion !

> **✅ Bonne Pratique** : Notez vos credentials dans un gestionnaire de mots de passe sécurisé.

> **⚠️ Attention** : Si vous ne pouvez pas vous connecter, vérifiez que le conteneur Grafana est bien démarré avec `docker compose ps grafana`.

---

## ⚙️ Étape 5 : Configuration Initiale

### 5.1 Changer le Mot de Passe Admin

#### Via l'Interface Web

1. Cliquer sur l'icône **👤 admin** en haut à droite
2. Sélectionner **Profile**
3. Onglet **Change Password**
4. Entrer :
   - **Old password** : `GrafanaSecure123!Change@Me`
   - **New password** : Votre nouveau mot de passe sécurisé
   - **Confirm password** : Répéter le nouveau mot de passe
5. Cliquer sur **Change Password**

#### Via la Ligne de Commande

##### 🪟 Windows (PowerShell)

```powershell
# Réinitialiser le mot de passe admin
docker compose exec grafana grafana-cli admin reset-admin-password "VotreNouveauMotDePasse123!"

# Redémarrer Grafana
docker compose restart grafana
```

##### 🐧 Ubuntu/Linux

```bash
# Réinitialiser le mot de passe
docker compose exec grafana grafana-cli admin reset-admin-password "VotreNouveauMotDePasse123!"

# Redémarrer Grafana
docker compose restart grafana
```

### 5.2 Configurer les Préférences

1. **Thème** : Light / Dark
   - Aller dans **Profile** → **Preferences**
   - Choisir **UI Theme** : Dark (recommandé)

2. **Timezone** : 
   - Sélectionner votre fuseau horaire
   - Exemple : `Europe/Paris`

3. **Home Dashboard** :
   - Définir un dashboard par défaut (plus tard)

### 5.3 Explorer l'Interface

#### Menu Principal (Sidebar)

```
┌──────────────────┐
│  🏠 Home         │  Page d'accueil
│  🔍 Explore      │  Exploration ad-hoc
│  📊 Dashboards   │  Gestion des dashboards
│  🔔 Alerting     │  Configuration des alertes
│  ⚙️  Configuration│  Paramètres
│  🔌 Connections  │  Data sources & plugins
│  👥 Administration│ Gestion utilisateurs
│  📚 Help         │  Documentation
└──────────────────┘
```

### 💡 Tips - Étape 5

> **🎨 Thème** : Le thème Dark est recommandé pour réduire la fatigue oculaire lors de longues sessions.

> **⏰ Timezone** : Configurez le bon fuseau horaire pour que les timestamps soient corrects dans vos dashboards.

> **✅ Bonne Pratique** : Explorez chaque section du menu pour vous familiariser avec l'interface.

> **🔧 Astuce** : Utilisez `Ctrl + K` (ou `Cmd + K` sur Mac) pour ouvrir la recherche rapide.

---

## ✅ Validation

### Checklist de Validation

Cochez chaque élément pour confirmer que tout fonctionne :

- [ ] Docker et Docker Compose installés et fonctionnels
- [ ] Fichier `.env` créé et configuré
- [ ] Tous les services démarrés (`docker compose ps` montre "Up")
- [ ] Grafana accessible sur http://localhost:3000
- [ ] Connexion réussie avec les credentials admin
- [ ] Mot de passe admin changé
- [ ] Interface Grafana s'affiche correctement
- [ ] Préférences utilisateur configurées
- [ ] Aucune erreur dans les logs (`docker compose logs`)

### Tests de Santé

#### 🪟 Windows (PowerShell)

```powershell
# Tester tous les services
Write-Host "Testing Grafana..." -ForegroundColor Yellow
Invoke-WebRequest -Uri http://localhost:3000/api/health -UseBasicParsing

Write-Host "Testing Prometheus..." -ForegroundColor Yellow
Invoke-WebRequest -Uri http://localhost:9090/-/healthy -UseBasicParsing

Write-Host "Testing InfluxDB..." -ForegroundColor Yellow
Invoke-WebRequest -Uri http://localhost:8086/health -UseBasicParsing

Write-Host "Testing Loki..." -ForegroundColor Yellow
Invoke-WebRequest -Uri http://localhost:3100/ready -UseBasicParsing

Write-Host "All services are healthy! ✅" -ForegroundColor Green
```

#### 🐧 Ubuntu/Linux

```bash
# Script de test
echo "Testing Grafana..."
curl -f http://localhost:3000/api/health && echo "✅ Grafana OK"

echo "Testing Prometheus..."
curl -f http://localhost:9090/-/healthy && echo "✅ Prometheus OK"

echo "Testing InfluxDB..."
curl -f http://localhost:8086/health && echo "✅ InfluxDB OK"

echo "Testing Loki..."
curl -f http://localhost:3100/ready && echo "✅ Loki OK"

echo "All services are healthy! ✅"
```

---

## 🐛 Troubleshooting

### Problème 1 : Docker n'est pas démarré

**Symptômes** :
```
error during connect: This error may indicate that the docker daemon is not running
```

**Solutions** :

#### 🪟 Windows
```powershell
# Démarrer Docker Desktop manuellement
# Ou vérifier le service
Get-Service docker
Start-Service docker
```

#### 🐧 Ubuntu/Linux
```bash
# Démarrer Docker
sudo systemctl start docker

# Activer au démarrage
sudo systemctl enable docker
```

---

### Problème 2 : Port déjà utilisé

**Symptômes** :
```
Error: bind: address already in use
```

**Solutions** :

#### 🪟 Windows (PowerShell)
```powershell
# Identifier le processus utilisant le port 3000
netstat -ano | findstr :3000

# Arrêter le processus (remplacer PID par le numéro trouvé)
Stop-Process -Id PID -Force
```

#### 🐧 Ubuntu/Linux
```bash
# Identifier le processus
sudo lsof -i :3000

# Arrêter le processus
sudo kill -9 PID
```

**Alternative** : Modifier le port dans `docker-compose.yml`
```yaml
grafana:
  ports:
    - "3001:3000"  # Utiliser le port 3001 au lieu de 3000
```

---

### Problème 3 : Grafana ne démarre pas

**Symptômes** :
```
docker compose ps
# grafana    Exit 1
```

**Solutions** :

#### 🪟 Windows (PowerShell)
```powershell
# Vérifier les logs
docker compose logs grafana

# Vérifier les permissions des volumes
Get-Acl grafana\

# Recréer le conteneur
docker compose rm -f grafana
docker compose up -d grafana
```

#### 🐧 Ubuntu/Linux
```bash
# Vérifier les logs
docker compose logs grafana

# Vérifier les permissions
ls -la grafana/

# Corriger les permissions (Grafana utilise UID 472)
sudo chown -R 472:472 grafana/

# Redémarrer
docker compose restart grafana
```

---

### Problème 4 : Impossible de se connecter

**Symptômes** :
- Page de connexion ne s'affiche pas
- Erreur "Connection refused"

**Solutions** :

#### 🪟 Windows (PowerShell)
```powershell
# Vérifier que Grafana est démarré
docker compose ps grafana

# Vérifier les logs
docker compose logs grafana | Select-String -Pattern "error" -CaseSensitive

# Tester la connexion
Test-NetConnection -ComputerName localhost -Port 3000

# Redémarrer Grafana
docker compose restart grafana
```

#### 🐧 Ubuntu/Linux
```bash
# Vérifier le statut
docker compose ps grafana

# Vérifier les logs
docker compose logs grafana | grep -i error

# Tester la connexion
curl -v http://localhost:3000

# Redémarrer
docker compose restart grafana
```

---

### Problème 5 : Mot de passe incorrect

**Symptômes** :
```
Invalid username or password
```

**Solutions** :

#### 🪟 Windows (PowerShell)
```powershell
# Vérifier le mot de passe dans .env
Get-Content .env | Select-String "GF_SECURITY_ADMIN_PASSWORD"

# Réinitialiser le mot de passe
docker compose exec grafana grafana-cli admin reset-admin-password "NewPassword123!"

# Redémarrer
docker compose restart grafana
```

#### 🐧 Ubuntu/Linux
```bash
# Vérifier le mot de passe
cat .env | grep GF_SECURITY_ADMIN_PASSWORD

# Réinitialiser
docker compose exec grafana grafana-cli admin reset-admin-password "NewPassword123!"

# Redémarrer
docker compose restart grafana
```

---

### Problème 6 : Services lents ou qui plantent

**Symptômes** :
- Conteneurs qui redémarrent constamment
- Performances dégradées

**Solutions** :

#### 🪟 Windows (PowerShell)
```powershell
# Vérifier l'utilisation des ressources
docker stats

# Augmenter les ressources dans Docker Desktop
# Settings → Resources → Memory (minimum 8GB)

# Nettoyer Docker
docker system prune -a
```

#### 🐧 Ubuntu/Linux
```bash
# Vérifier les ressources
docker stats

# Vérifier la mémoire système
free -h

# Nettoyer Docker
docker system prune -a
```

---

## 📚 Ressources Complémentaires

### Documentation Officielle
- [Grafana Installation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Grafana Configuration](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)

### Commandes Utiles

#### 🪟 Windows (PowerShell)
```powershell
# Voir tous les conteneurs
docker compose ps

# Voir les logs
docker compose logs -f [service-name]

# Redémarrer un service
docker compose restart [service-name]

# Arrêter tout
docker compose down

# Arrêter et supprimer les volumes
docker compose down -v

# Reconstruire les images
docker compose build --no-cache
```

#### 🐧 Ubuntu/Linux
```bash
# Même commandes que Windows
docker compose ps
docker compose logs -f [service-name]
docker compose restart [service-name]
docker compose down
docker compose down -v
docker compose build --no-cache
```

---

## 🎯 Prochaines Étapes

Félicitations ! Vous avez terminé le Lab 1.2. 🎉

Vous êtes maintenant prêt pour :

➡️ **Lab 1.3** : [Configuration de la Datasource InfluxDB](../Lab-1.3-InfluxDB/)

Dans le prochain lab, vous allez :
- Comprendre le modèle de données InfluxDB
- Configurer la connexion Grafana ↔ InfluxDB
- Créer vos premières requêtes Flux
- Visualiser des données de séries temporelles

---

## 💡 Résumé des Bonnes Pratiques

✅ **Toujours** vérifier les prérequis avant de démarrer  
✅ **Toujours** changer les mots de passe par défaut  
✅ **Toujours** utiliser des mots de passe forts (16+ caractères)  
✅ **Toujours** vérifier les logs en cas de problème  
✅ **Toujours** sauvegarder le fichier `.env` (mais pas dans Git !)  
✅ **Toujours** attendre que tous les services soient "Up" avant de continuer  

❌ **Jamais** committer le fichier `.env` dans Git  
❌ **Jamais** utiliser les mots de passe par défaut en production  
❌ **Jamais** arrêter les services pendant l'initialisation  
❌ **Jamais** supprimer les volumes sans backup (`docker compose down -v`)  

---

**🎓 Auteur** : Formation Grafana Observability Stack  
**📅 Dernière mise à jour** : Octobre 2025  
**📧 Support** : Consultez le [README principal](../../README.md)
