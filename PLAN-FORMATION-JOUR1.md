# 📚 Plan de Formation Grafana - Jour 1

## 🎯 Objectifs de la journée
- Comprendre l'architecture et l'écosystème Grafana
- Déployer et configurer Grafana OSS
- Maîtriser la connexion aux sources de données (InfluxDB, Prometheus, MS SQL)
- Créer des requêtes de base pour chaque datasource

---

# 🎓 Atelier 1 : Introduction à Grafana et ses Fonctionnalités
**⏱️ Durée : 1h30 | 📍 Théorie + Démo**

## 📖 Objectifs
✅ Comprendre la philosophie et l'architecture de Grafana  
✅ Identifier les différences entre les versions (OSS, Enterprise, Cloud)  
✅ Découvrir les fonctionnalités clés  

## 🏗️ Architecture de Grafana

```
┌─────────────────────────────────────────────────────────────┐
│                    GRAFANA ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│  📊 VISUALIZATION LAYER                                      │
│  ├─ Dashboards (Panels, Variables, Annotations)             │
│  ├─ Alerting (Rules, Notifications, Silences)               │
│  └─ Plugins (Panels, Datasources, Apps)                     │
│                                                               │
│  🔌 DATA SOURCES                                             │
│  ├─ Prometheus (Metrics)                                     │
│  ├─ InfluxDB (Time Series)                                   │
│  ├─ MS SQL (Business Data)                                   │
│  ├─ Loki (Logs)                                              │
│  └─ Tempo (Traces)                                           │
│                                                               │
│  💾 STORAGE BACKEND                                          │
│  └─ SQLite / MySQL / PostgreSQL                             │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Concepts Clés

### 1. **Philosophie Grafana**
- 🎯 **Observabilité unifiée** : Une interface pour toutes vos métriques
- 🔄 **Agnostique** : Compatible avec de nombreuses sources de données
- 🎨 **Visualisation** : Transforme les données en insights visuels
- 🤝 **Open Source** : Communauté active et extensible

### 2. **Fonctionnalités Principales**

| Fonctionnalité | Description | Use Case |
|----------------|-------------|----------|
| **📊 Dashboards** | Tableaux de bord interactifs | Monitoring infrastructure |
| **🔔 Alerting** | Système d'alertes avancé | Détection d'incidents |
| **🔌 Data Sources** | Connexion multi-sources | Centralisation des données |
| **🔍 Explore** | Exploration ad-hoc | Investigation et debug |
| **📝 Annotations** | Marqueurs d'événements | Corrélation déploiements |
| **👥 Teams** | Gestion des équipes | Collaboration |

## 📊 Comparaison des Versions

| Fonctionnalité | OSS (Gratuit) | Enterprise | Cloud |
|----------------|---------------|------------|-------|
| **Dashboards** | ✅ Illimités | ✅ Illimités | ✅ Illimités |
| **Data Sources** | ✅ Tous | ✅ Tous + Enterprise | ✅ Managed |
| **Alerting** | ✅ Basique | ✅ Avancé | ✅ Avancé |
| **RBAC** | ⚠️ Basique | ✅ Avancé | ✅ Avancé |
| **Support** | ❌ Communauté | ✅ 24/7 | ✅ 24/7 |
| **Reporting** | ❌ | ✅ PDF/Email | ✅ PDF/Email |
| **Prix** | 🆓 Gratuit | 💰 Sur devis | 💰 /utilisateur |

## 💡 Tips & Astuces

### ✅ Bonnes Pratiques
1. **Organisation** : Utilisez des dossiers pour organiser vos dashboards
2. **Naming** : Nommez clairement vos dashboards et panels
3. **Variables** : Rendez vos dashboards réutilisables
4. **Tags** : Facilitez la recherche avec des tags cohérents
5. **Permissions** : Définissez des permissions par dossier

### ⚡ Raccourcis Clavier
- `Ctrl + S` : Sauvegarder le dashboard
- `Ctrl + H` : Afficher/masquer l'aide
- `d + k` : Menu de navigation
- `Esc` : Fermer le panel en édition

### 🎯 Use Cases Typiques
1. **Infrastructure** : CPU, RAM, Disk, Network
2. **Application** : Response time, Error rate, Throughput
3. **Business** : Transactions, Revenue, User activity
4. **IoT** : Temperature, Humidity, Energy
5. **Finance** : Trading volumes, Fraud detection

## 🐛 Troubleshooting Commun

| Problème | Cause | Solution |
|----------|-------|----------|
| **Dashboard lent** | Trop de panels | Limiter à 20-30 panels |
| **Requêtes timeout** | Requête trop large | Réduire la plage temporelle |
| **Données manquantes** | Datasource down | Vérifier la connexion |
| **Alertes spam** | Seuils mal configurés | Ajuster les thresholds |

---

# 🚀 Atelier 2 : Installation et Configuration de Grafana OSS
**⏱️ Durée : 2h | 🛠️ Pratique**

## 📖 Objectifs
✅ Déployer Grafana OSS avec Docker Compose  
✅ Configurer le service et les paramètres de base  
✅ Se connecter à l'interface web  
✅ Explorer l'interface utilisateur  

## 🛠️ Prérequis

```bash
# Vérifier Docker
docker --version
# Attendu : Docker version 20.10+

# Vérifier Docker Compose
docker compose version
# Attendu : v2.0+

# Vérifier les ressources
docker system info | grep -E "CPUs|Total Memory"
# Recommandé : 4 CPUs, 8GB RAM
```

## 📦 Architecture de Déploiement

```
┌─────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE STACK                      │
├─────────────────────────────────────────────────────────────┤
│  GRAFANA (Port 3000)                                         │
│  ├─ Dashboards & Visualization                               │
│  ├─ User Management                                          │
│  └─ Alerting Engine                                          │
│                                                               │
│  DATA SOURCES                                                │
│  ├─ Prometheus (Port 9090)                                   │
│  ├─ InfluxDB (Port 8086)                                     │
│  ├─ MS SQL (Port 1433)                                       │
│  └─ Loki (Port 3100)                                         │
│                                                               │
│  NETWORK: observability (bridge)                             │
│  VOLUMES: grafana_data, prometheus_data, influxdb_data       │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Travaux Pratiques

### Étape 1 : Préparation

```bash
# Naviguer vers le répertoire
cd "d:\Data2AI Academy\Grafana\observability-stack"

# Créer le fichier .env
cp .env.example .env

# Éditer avec vos paramètres
notepad .env
```

### Étape 2 : Configuration .env

```env
# GRAFANA
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=GrafanaSecure123!Change@Me
GF_SECURITY_SECRET_KEY=GrafanaSecret123!Change@Me

# INFLUXDB
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=InfluxSecure123!Change@Me
INFLUXDB_ORG=myorg
INFLUXDB_BUCKET=payments
INFLUXDB_TOKEN=my-super-secret-auth-token

# MS SQL
MSSQL_SA_PASSWORD=EBanking@Secure123!

# MYSQL
MYSQL_ROOT_PASSWORD=MySQLRoot123!Change@Me
```

### Étape 3 : Déploiement

```bash
# Démarrer la stack
docker compose up -d

# Vérifier les conteneurs
docker compose ps

# Vérifier les logs
docker compose logs grafana

# Attendre 30 secondes
timeout /t 30

# Ouvrir Grafana
start http://localhost:3000
```

### Étape 4 : Première Connexion

**URL** : http://localhost:3000  
**Username** : admin  
**Password** : GrafanaSecure123!Change@Me  

## 💡 Tips de Configuration

### ✅ Sécurité
- ⚠️ **Changez immédiatement le mot de passe admin**
- 🔐 Utilisez des mots de passe forts (16+ caractères)
- 🚫 Désactivez l'inscription anonyme
- 🔑 Activez 2FA en production

### ⚡ Performance
- 💾 Utilisez PostgreSQL/MySQL en prod (pas SQLite)
- 🗄️ Configurez des volumes persistants
- 📊 Limitez à 20-30 panels par dashboard

### 📁 Organisation
- Créez une structure de dossiers logique
- Utilisez des tags cohérents
- Documentez vos dashboards

## 🐛 Troubleshooting

### Problème 1 : Grafana ne démarre pas

```bash
# Vérifier les logs
docker compose logs grafana

# Vérifier les permissions (Linux)
sudo chown -R 472:472 grafana/

# Redémarrer
docker compose restart grafana
```

### Problème 2 : Connexion impossible

```bash
# Vérifier le conteneur
docker compose ps grafana

# Vérifier le port
netstat -an | findstr 3000

# Tester l'API
curl http://localhost:3000/api/health
```

### Problème 3 : Mot de passe oublié

```bash
# Réinitialiser le mot de passe
docker compose exec grafana grafana-cli admin reset-admin-password NewPassword123
```

## ✅ Checklist

- [ ] Docker et Docker Compose fonctionnels
- [ ] Fichier .env configuré
- [ ] Tous les conteneurs démarrés
- [ ] Grafana accessible sur port 3000
- [ ] Connexion réussie
- [ ] Interface s'affiche correctement
- [ ] Mot de passe admin changé

---

# 🗄️ Atelier 3 : Datasources - InfluxDB
**⏱️ Durée : 1h30 | 🛠️ Pratique**

## 📖 Objectifs
✅ Comprendre InfluxDB et son modèle de données  
✅ Configurer la connexion Grafana ↔ InfluxDB  
✅ Créer des requêtes Flux basiques  
✅ Visualiser des données de séries temporelles  

## 📊 Introduction à InfluxDB

### Qu'est-ce qu'InfluxDB ?
- **Time Series Database** (TSDB) optimisée pour les métriques
- Haute performance en écriture/lecture
- Langage : **Flux** (v2.x) ou **InfluxQL** (v1.x)

### Modèle de Données

```
┌─────────────────────────────────────────────────────────────┐
│  ORGANIZATION: myorg                                         │
│  └─ BUCKET: payments (Retention: 7 days)                    │
│     └─ MEASUREMENT: payment_transactions                    │
│        ├─ TAGS (indexed): type, status, region              │
│        ├─ FIELDS (values): amount, fee, duration            │
│        └─ TIMESTAMP: 2024-01-01T10:00:00Z                   │
└─────────────────────────────────────────────────────────────┘
```

### Concepts Clés

| Concept | Description | Exemple |
|---------|-------------|---------|
| **Organization** | Espace de travail | `myorg`, `bhf-oddo` |
| **Bucket** | Conteneur de données | `payments`, `metrics` |
| **Measurement** | Table de données | `payment_transactions` |
| **Tags** | Métadonnées indexées | `region=eu`, `env=prod` |
| **Fields** | Valeurs métriques | `amount=100`, `fee=1.5` |
| **Timestamp** | Horodatage précis | Nanoseconde |

## 🔧 Configuration dans Grafana

### Étape 1 : Vérifier InfluxDB

```bash
# Vérifier le statut
docker compose ps influxdb

# Tester l'API
curl http://localhost:8086/health
# Attendu : {"status":"pass"}

# Récupérer le token
cat .env | findstr INFLUXDB_TOKEN
```

### Étape 2 : Ajouter la Datasource

1. **Grafana** → **Configuration** → **Data Sources**
2. **Add data source** → **InfluxDB**
3. **Configuration** :

```yaml
Name: InfluxDB-Payments
Query Language: Flux
URL: http://influxdb:8086
Organization: myorg
Token: my-super-secret-auth-token
Default Bucket: payments
```

4. **Save & Test** → ✅ "Data source is working"

### Étape 3 : Créer des Données de Test

```bash
# Accéder au conteneur InfluxDB
docker compose exec influxdb bash

# Écrire des données de test
influx write \
  --bucket payments \
  --org myorg \
  --token my-super-secret-auth-token \
  --precision s \
  "payment_transactions,type=card,status=success amount=100,fee=2.5 $(date +%s)"

influx write \
  --bucket payments \
  --org myorg \
  --token my-super-secret-auth-token \
  --precision s \
  "payment_transactions,type=transfer,status=success amount=500,fee=5.0 $(date +%s)"
```

## 📝 Requêtes Flux

### Requête 1 : Lire toutes les données

```flux
from(bucket: "payments")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
```

### Requête 2 : Filtrer par tag

```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r.type == "card")
  |> filter(fn: (r) => r._field == "amount")
```

### Requête 3 : Agrégation

```flux
from(bucket: "payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1h, fn: sum)
```

### Requête 4 : Grouper par tag

```flux
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["type"])
  |> sum()
```

## 💡 Tips & Astuces

### ✅ Bonnes Pratiques
1. **Tags** : Utilisez pour les dimensions (max 10-15 tags)
2. **Fields** : Utilisez pour les valeurs numériques
3. **Cardinality** : Évitez les tags à haute cardinalité
4. **Retention** : Définissez une politique de rétention adaptée
5. **Downsampling** : Agrégez les anciennes données

### ⚡ Optimisations
- Utilisez `range()` pour limiter la période
- Filtrez tôt dans le pipeline
- Utilisez `aggregateWindow()` pour réduire les points
- Limitez le nombre de séries avec `limit()`

## 🐛 Troubleshooting

| Problème | Cause | Solution |
|----------|-------|----------|
| **Connection refused** | InfluxDB down | `docker compose restart influxdb` |
| **Unauthorized** | Token invalide | Vérifier le token dans .env |
| **Bucket not found** | Bucket inexistant | Créer le bucket dans InfluxDB UI |
| **No data** | Pas de données | Écrire des données de test |

---

# 📈 Atelier 4 : Datasources - Prometheus
**⏱️ Durée : 1h30 | 🛠️ Pratique**

## 📖 Objectifs
✅ Comprendre Prometheus et son modèle de données  
✅ Configurer la connexion Grafana ↔ Prometheus  
✅ Maîtriser le langage PromQL  
✅ Créer des visualisations de métriques  

## 📊 Introduction à Prometheus

### Qu'est-ce que Prometheus ?
- **Système de monitoring** open-source
- **Pull-based** : scrape les métriques via HTTP
- **Time Series Database** intégrée
- Langage de requête : **PromQL**

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  PROMETHEUS                                                  │
│  ├─ Scraper (pull metrics every 15s)                         │
│  ├─ TSDB (local storage)                                     │
│  ├─ Query Engine (PromQL)                                    │
│  └─ Alertmanager (optional)                                  │
│                                                               │
│  TARGETS (scraped)                                           │
│  ├─ Node Exporter (system metrics)                           │
│  ├─ Payment API (app metrics)                                │
│  ├─ eBanking Exporter (business metrics)                     │
│  └─ Custom Exporters                                         │
└─────────────────────────────────────────────────────────────┘
```

### Modèle de Données

```
Metric Name: http_requests_total
Labels: {method="GET", status="200", endpoint="/api/payments"}
Value: 1547
Timestamp: 1704110400
```

## 🔧 Configuration dans Grafana

### Étape 1 : Vérifier Prometheus

```bash
# Vérifier le statut
docker compose ps prometheus

# Tester l'API
curl http://localhost:9090/-/healthy
# Attendu : Prometheus is Healthy

# Voir les targets
start http://localhost:9090/targets
```

### Étape 2 : Ajouter la Datasource

1. **Grafana** → **Configuration** → **Data Sources**
2. **Add data source** → **Prometheus**
3. **Configuration** :

```yaml
Name: Prometheus
URL: http://prometheus:9090
Access: Server (default)
Scrape interval: 15s
```

4. **Save & Test** → ✅ "Data source is working"

## 📝 Requêtes PromQL

### Requête 1 : Métrique simple

```promql
# Nombre total de requêtes HTTP
http_requests_total
```

### Requête 2 : Filtrer par label

```promql
# Requêtes GET uniquement
http_requests_total{method="GET"}

# Requêtes avec erreur
http_requests_total{status=~"5.."}
```

### Requête 3 : Rate (taux par seconde)

```promql
# Requêtes par seconde (sur 5 minutes)
rate(http_requests_total[5m])

# Taux d'erreurs
rate(http_requests_total{status=~"5.."}[5m])
```

### Requête 4 : Agrégation

```promql
# Total par méthode HTTP
sum by (method) (rate(http_requests_total[5m]))

# Moyenne par endpoint
avg by (endpoint) (http_request_duration_seconds)
```

### Requête 5 : Calculs

```promql
# Taux d'erreur en pourcentage
(
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
) * 100

# Latence P95
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
)
```

## 💡 Tips & Astuces

### ✅ Bonnes Pratiques PromQL
1. **Utilisez `rate()` pour les counters**
2. **Utilisez `irate()` pour les pics courts**
3. **Agrégez avec `sum()`, `avg()`, `max()`, `min()`**
4. **Filtrez avec `by` ou `without`**
5. **Utilisez des ranges appropriés : `[1m]`, `[5m]`, `[1h]`**

### ⚡ Fonctions Utiles

| Fonction | Usage | Exemple |
|----------|-------|---------|
| `rate()` | Taux par seconde | `rate(requests[5m])` |
| `increase()` | Augmentation totale | `increase(requests[1h])` |
| `sum()` | Somme | `sum(cpu_usage)` |
| `avg()` | Moyenne | `avg(memory_usage)` |
| `topk()` | Top K valeurs | `topk(5, cpu_usage)` |
| `histogram_quantile()` | Percentile | `histogram_quantile(0.95, ...)` |

## 🐛 Troubleshooting

```bash
# Vérifier les targets Prometheus
curl http://localhost:9090/api/v1/targets | jq

# Vérifier une métrique spécifique
curl 'http://localhost:9090/api/v1/query?query=up'

# Voir les métriques disponibles
curl http://localhost:9090/api/v1/label/__name__/values
```

---

# 💾 Atelier 5 : Datasources - MS SQL Server
**⏱️ Durée : 1h30 | 🛠️ Pratique**

## 📖 Objectifs
✅ Comprendre l'intégration SQL dans Grafana  
✅ Configurer la connexion Grafana ↔ MS SQL  
✅ Créer des requêtes SQL pour dashboards  
✅ Visualiser des données métier  

## 🔧 Configuration dans Grafana

### Étape 1 : Vérifier MS SQL

```bash
# Vérifier le statut
docker compose ps mssql

# Tester la connexion
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "EBanking@Secure123!" -C \
  -Q "SELECT @@VERSION"
```

### Étape 2 : Ajouter la Datasource

1. **Grafana** → **Configuration** → **Data Sources**
2. **Add data source** → **Microsoft SQL Server**
3. **Configuration** :

```yaml
Name: MS-SQL-EBanking
Host: mssql:1433
Database: EBankingDB
User: sa
Password: EBanking@Secure123!
Encrypt: disable
```

4. **Save & Test** → ✅ "Database Connection OK"

### Étape 3 : Créer des Données de Test

```sql
-- Créer une table de transactions
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    TransactionType VARCHAR(50),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20)
);

-- Insérer des données
INSERT INTO Transactions (AccountID, Amount, TransactionType, Status)
VALUES 
    (1001, 150.00, 'PAYMENT', 'SUCCESS'),
    (1002, 500.00, 'TRANSFER', 'SUCCESS'),
    (1003, 75.50, 'PAYMENT', 'FAILED'),
    (1001, 200.00, 'WITHDRAWAL', 'SUCCESS');
```

## 📝 Requêtes SQL pour Grafana

### Requête 1 : Time Series

```sql
SELECT 
    TransactionDate AS time,
    SUM(Amount) AS value,
    TransactionType AS metric
FROM Transactions
WHERE TransactionDate >= DATEADD(hour, -24, GETDATE())
GROUP BY TransactionDate, TransactionType
ORDER BY time
```

### Requête 2 : Agrégation

```sql
SELECT 
    TransactionType,
    COUNT(*) AS count,
    SUM(Amount) AS total_amount,
    AVG(Amount) AS avg_amount
FROM Transactions
WHERE TransactionDate >= DATEADD(day, -7, GETDATE())
GROUP BY TransactionType
```

### Requête 3 : Avec Variables Grafana

```sql
SELECT 
    TransactionDate AS time,
    Amount AS value
FROM Transactions
WHERE 
    TransactionDate BETWEEN '$__timeFrom()' AND '$__timeTo()'
    AND TransactionType = '$transaction_type'
ORDER BY time
```

### Requête 4 : Table

```sql
SELECT 
    TransactionID,
    AccountID,
    Amount,
    TransactionType,
    Status,
    TransactionDate
FROM Transactions
WHERE TransactionDate >= DATEADD(hour, -1, GETDATE())
ORDER BY TransactionDate DESC
```

## 💡 Tips & Astuces

### ✅ Macros Grafana

| Macro | Description | Exemple |
|-------|-------------|---------|
| `$__timeFrom()` | Début de la plage | `WHERE date >= $__timeFrom()` |
| `$__timeTo()` | Fin de la plage | `WHERE date <= $__timeTo()` |
| `$__timeFilter(column)` | Filtre temporel | `WHERE $__timeFilter(date)` |
| `$__interval` | Intervalle auto | `GROUP BY time($__interval)` |

### ⚡ Optimisations
1. **Index** : Créez des index sur les colonnes de date
2. **Limit** : Limitez le nombre de résultats
3. **Cache** : Utilisez le cache de Grafana
4. **Agrégation** : Pré-agrégez les données anciennes

## 🐛 Troubleshooting

```bash
# Vérifier la connexion
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "EBanking@Secure123!" -C \
  -Q "SELECT 1"

# Lister les bases de données
docker compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "EBanking@Secure123!" -C \
  -Q "SELECT name FROM sys.databases"
```

---

# 🎯 Atelier 6 : Création de Requêtes et Premier Dashboard
**⏱️ Durée : 1h30 | 🛠️ Pratique**

## 📖 Objectifs
✅ Créer des requêtes pour chaque datasource  
✅ Construire un dashboard multi-sources  
✅ Appliquer les bonnes pratiques  

## 📊 Dashboard Multi-Sources

### Panel 1 : InfluxDB - Transactions par Type

```flux
from(bucket: "payments")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["type"])
  |> aggregateWindow(every: 5m, fn: sum)
```

**Visualization** : Time Series  
**Legend** : {{type}}  

### Panel 2 : Prometheus - Taux de Requêtes

```promql
sum by (status) (rate(http_requests_total[5m]))
```

**Visualization** : Graph  
**Unit** : requests/sec  

### Panel 3 : MS SQL - Top Comptes

```sql
SELECT TOP 10
    AccountID,
    COUNT(*) AS transactions,
    SUM(Amount) AS total
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY AccountID
ORDER BY total DESC
```

**Visualization** : Table  

## ✅ Checklist Finale

- [ ] InfluxDB configuré et testé
- [ ] Prometheus configuré et testé
- [ ] MS SQL configuré et testé
- [ ] Requêtes créées pour chaque source
- [ ] Dashboard multi-sources créé
- [ ] Variables de dashboard configurées
- [ ] Panels sauvegardés

## 📚 Ressources

- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Flux Language](https://docs.influxdata.com/flux/)
- [SQL Server Docs](https://learn.microsoft.com/sql/)

---

**🎉 Félicitations ! Vous avez terminé le Jour 1 de la formation Grafana !**
