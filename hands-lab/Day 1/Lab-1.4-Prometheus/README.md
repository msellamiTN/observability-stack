# 📈 Lab 1.4 : Datasource Prometheus

**⏱️ Durée** : 1h30 | **👤 Niveau** : Débutant | **💻 Type** : Pratique

---

## 🎯 Objectifs

À la fin de ce lab, vous serez capable de :

✅ Comprendre l'architecture Prometheus (Pull-based monitoring)  
✅ Configurer Prometheus comme datasource dans Grafana  
✅ Explorer les targets et métriques disponibles  
✅ Écrire des requêtes PromQL basiques  
✅ Comprendre les types de métriques (Counter, Gauge, Histogram, Summary)  
✅ Visualiser des métriques système avec Node Exporter  
✅ Créer des dashboards avec des métriques Prometheus  

---

## 🛠️ Prérequis

- ✅ Lab 1.2 complété (Stack démarrée)
- ✅ Prometheus en cours d'exécution
- ✅ Grafana accessible

---

## 📚 Introduction à Prometheus

### Qu'est-ce que Prometheus ?

**Prometheus** est un système de monitoring et d'alerting open-source conçu pour la fiabilité et la scalabilité.

**Caractéristiques** :
- 🔄 **Pull-based** : Prometheus scrape les métriques (vs Push)
- 📊 **Time Series** : Stockage optimisé pour séries temporelles
- 🔍 **PromQL** : Langage de requête puissant
- 🎯 **Service Discovery** : Découverte automatique des targets
- 🔔 **Alerting** : Règles d'alertes intégrées

### Architecture Prometheus

```
┌─────────────────────────────────────────────────────────────┐
│                  PROMETHEUS ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  🎯 TARGETS (Applications à monitorer)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Node     │  │ Grafana  │  │ Payment  │                  │
│  │ Exporter │  │ :3000    │  │ API      │                  │
│  │ :9100    │  │ /metrics │  │ :8080    │                  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                  │
│       │             │             │                          │
│       └─────────────┼─────────────┘                          │
│                     ↓ SCRAPE (Pull every 15s)                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PROMETHEUS SERVER (Port 9090)                       │   │
│  │  ├─ Retrieval (Scraper)                              │   │
│  │  ├─ TSDB (Time Series Database)                      │   │
│  │  ├─ PromQL Engine                                    │   │
│  │  └─ HTTP API                                         │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ALERTMANAGER (Port 9093)                            │   │
│  │  ├─ Routing                                          │   │
│  │  ├─ Grouping                                         │   │
│  │  └─ Notifications (Email, Slack, etc.)               │   │
│  └──────────────────────────────────────────────────────┘   │
│                     ↓                                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  GRAFANA (Visualization)                             │   │
│  │  Query via PromQL                                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Types de Métriques

| Type | Description | Exemple | Opérations |
|------|-------------|---------|------------|
| **Counter** | Valeur qui ne fait qu'augmenter | Requêtes HTTP, erreurs | `rate()`, `increase()` |
| **Gauge** | Valeur qui monte et descend | CPU, RAM, température | Toutes |
| **Histogram** | Distribution de valeurs | Latence, taille requête | `histogram_quantile()` |
| **Summary** | Similaire à Histogram | Latence p95, p99 | `quantile` |

---

## 🔍 Étape 1 : Vérification de Prometheus

### Windows (PowerShell)

```powershell
# Vérifier le statut
docker compose ps prometheus

# Vérifier la santé
Invoke-WebRequest -Uri http://localhost:9090/-/healthy -UseBasicParsing

# Vérifier les targets
Invoke-WebRequest -Uri http://localhost:9090/api/v1/targets -UseBasicParsing | ConvertFrom-Json
```

### Linux

```bash
# Vérifier le statut
docker compose ps prometheus

# Vérifier la santé
curl http://localhost:9090/-/healthy

# Vérifier les targets
curl http://localhost:9090/api/v1/targets | jq
```

---

## 🌐 Étape 2 : Interface Web Prometheus

### 2.1 Accéder à Prometheus UI

**URL** : http://localhost:9090

### 2.2 Navigation

**Menu Principal** :
- **🔍 Graph** : Exécuter des requêtes PromQL
- **🎯 Targets** : Voir les endpoints scrapés
- **🔔 Alerts** : Règles d'alertes actives
- **⚙️ Status** : Configuration et runtime info

### 2.3 Explorer les Targets

1. Aller dans **Status** → **Targets**
2. Vous devriez voir :

```
Endpoint                        State    Labels
prometheus (1/1 up)            UP       job="prometheus"
grafana (1/1 up)               UP       job="grafana"
node-exporter (1/1 up)         UP       job="node-exporter"
ebanking-exporter (1/1 up)     UP       job="ebanking-exporter"
payment-api (1/1 up)           UP       job="payment-api"
```

### 💡 Tips

> **✅ Bonne Pratique** : Vérifiez que tous les targets sont "UP" avant de continuer.

> **⚠️ Attention** : Si un target est "DOWN", vérifiez que le service expose bien `/metrics`.

---

## ⚙️ Étape 3 : Configuration dans Grafana

### 3.1 Ajouter la Datasource

1. Grafana → **Connections** → **Data sources**
2. Cliquer **Add data source**
3. Sélectionner **Prometheus**

### 3.2 Configuration

```yaml
Name: Prometheus
URL: http://prometheus:9090
Access: Server (proxy)
Scrape interval: 15s
Query timeout: 60s
HTTP Method: POST
```

4. Cliquer **Save & Test**
5. Message attendu : ✅ "Data source is working"

### 💡 Tips

> **🌐 URL** : Utilisez `http://prometheus:9090` (nom du service Docker), pas `localhost`

> **📊 HTTP Method** : POST permet d'envoyer des requêtes plus longues

---

## 📝 Étape 4 : Langage PromQL - Bases

### 4.1 Structure d'une Requête

```promql
metric_name{label="value"}[time_range]
```

### 4.2 Sélecteurs de Base

```promql
# Sélectionner une métrique
up

# Filtrer par label
up{job="grafana"}

# Plusieurs labels
up{job="grafana", instance="grafana:3000"}

# Regex
up{job=~"grafana|prometheus"}

# Négation
up{job!="grafana"}
```

### 4.3 Fonctions Essentielles

#### Rate - Taux par seconde

```promql
# Requêtes HTTP par seconde
rate(http_requests_total[5m])

# Erreurs par seconde
rate(http_requests_total{status="500"}[5m])
```

#### Increase - Augmentation totale

```promql
# Nombre total de requêtes sur 1h
increase(http_requests_total[1h])
```

#### Sum - Somme

```promql
# Total CPU usage
sum(rate(node_cpu_seconds_total[5m]))

# Par job
sum by (job) (rate(http_requests_total[5m]))
```

#### Avg - Moyenne

```promql
# Latence moyenne
avg(http_request_duration_seconds)
```

### 4.4 Opérateurs

```promql
# Arithmétique
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Pourcentage
(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Comparaison
up == 1  # Services UP
up == 0  # Services DOWN
```

---

## 🧪 Étape 5 : Requêtes Pratiques

### 5.1 Métriques Système (Node Exporter)

#### CPU Usage

```promql
# CPU usage par core
100 - (avg by (cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU usage total
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### Memory Usage

```promql
# RAM utilisée (bytes)
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# RAM utilisée (%)
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes) * 100
```

#### Disk Usage

```promql
# Espace disque utilisé (%)
(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100
```

### 5.2 Métriques Application

#### HTTP Requests

```promql
# Requêtes par seconde
rate(http_requests_total[5m])

# Par status code
sum by (status) (rate(http_requests_total[5m]))
```

#### Latency (Histogram)

```promql
# Latence p95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Latence p99
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# Latence moyenne
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

#### Error Rate

```promql
# Taux d'erreur (%)
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

---

## 📊 Étape 6 : Première Visualisation

### 6.1 Créer un Dashboard

1. Grafana → **Dashboards** → **New** → **New Dashboard**
2. **Add visualization**
3. Sélectionner **Prometheus**

### 6.2 Panel 1 : CPU Usage

**Query** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Configuration** :
- Title : "CPU Usage"
- Unit : Percent (0-100)
- Visualization : Time series
- Thresholds : 70 (yellow), 90 (red)

### 6.3 Panel 2 : Memory Usage

**Query** :
```promql
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes) * 100
```

**Configuration** :
- Title : "Memory Usage"
- Unit : Percent (0-100)
- Visualization : Gauge

### 6.4 Panel 3 : HTTP Requests Rate

**Query** :
```promql
sum(rate(http_requests_total[5m])) by (job)
```

**Configuration** :
- Title : "HTTP Requests/sec by Service"
- Unit : reqps (requests per second)
- Visualization : Time series
- Legend : {{job}}

---

## 🎯 Exercices Pratiques

### Exercice 1 : Services UP/DOWN

Créez une requête qui compte le nombre de services UP et DOWN.

<details>
<summary>💡 Solution</summary>

```promql
# Services UP
count(up == 1)

# Services DOWN
count(up == 0)

# Ratio
count(up == 1) / count(up)
```
</details>

### Exercice 2 : Top 5 Endpoints par Requêtes

Trouvez les 5 endpoints les plus sollicités.

<details>
<summary>💡 Solution</summary>

```promql
topk(5, sum by (endpoint) (rate(http_requests_total[5m])))
```
</details>

### Exercice 3 : Latence par Percentile

Affichez la latence p50, p95 et p99 sur le même graphique.

<details>
<summary>💡 Solution</summary>

```promql
# Query A (p50)
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# Query B (p95)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Query C (p99)
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```
</details>

---

## 🐛 Troubleshooting

### Problème 1 : No data in Grafana

**Symptômes** : La requête ne retourne aucune donnée

**Solutions** :

```promql
# 1. Vérifier que la métrique existe
up

# 2. Lister toutes les métriques
{__name__=~".+"}

# 3. Vérifier les labels
up{job="prometheus"}
```

### Problème 2 : Target DOWN

**Symptômes** : Un target apparaît comme DOWN dans Prometheus

**Solutions** :

```powershell
# Vérifier que le service est démarré
docker compose ps [service-name]

# Vérifier que /metrics est accessible
curl http://localhost:[port]/metrics

# Vérifier la configuration Prometheus
docker compose exec prometheus cat /etc/prometheus/prometheus.yml
```

### Problème 3 : Query timeout

**Symptômes** : La requête prend trop de temps

**Solutions** :

```promql
# Réduire la période
rate(metric[5m])  # Au lieu de [1h]

# Agréger avant
sum by (job) (rate(metric[5m]))

# Utiliser recording rules (avancé)
```

---

## 📚 Ressources

### Documentation
- [Prometheus Docs](https://prometheus.io/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Prometheus](https://grafana.com/docs/grafana/latest/datasources/prometheus/)

### Cheat Sheet PromQL

```promql
# SÉLECTEURS
metric_name                          # Métrique simple
metric_name{label="value"}           # Avec label
metric_name{label=~"regex"}          # Regex
metric_name{label!="value"}          # Négation

# FONCTIONS TEMPORELLES
rate(metric[5m])                     # Taux par seconde
increase(metric[1h])                 # Augmentation totale
irate(metric[5m])                    # Taux instantané
delta(metric[5m])                    # Différence

# AGRÉGATIONS
sum(metric)                          # Somme
avg(metric)                          # Moyenne
min(metric)                          # Minimum
max(metric)                          # Maximum
count(metric)                        # Comptage
sum by (label) (metric)              # Somme par label
sum without (label) (metric)         # Somme sans label

# FONCTIONS
abs(metric)                          # Valeur absolue
ceil(metric)                         # Arrondi supérieur
floor(metric)                        # Arrondi inférieur
round(metric)                        # Arrondi
sort(metric)                         # Tri ascendant
sort_desc(metric)                    # Tri descendant
topk(5, metric)                      # Top 5
bottomk(5, metric)                   # Bottom 5

# HISTOGRAMMES
histogram_quantile(0.95, metric)     # Percentile 95
```

---

## ✅ Validation

- [ ] Prometheus accessible sur http://localhost:9090
- [ ] Tous les targets sont UP
- [ ] Datasource configurée dans Grafana
- [ ] Requêtes PromQL exécutées avec succès
- [ ] Dashboard avec métriques système créé
- [ ] Exercices complétés
- [ ] Compréhension des types de métriques

---

## 🎯 Prochaines Étapes

➡️ **Lab 1.5** : [Datasource MS SQL Server](../Lab-1.5-MSSQL/)

Dans le prochain lab :
- Connexion à MS SQL Server
- Requêtes SQL dans Grafana
- Macros Grafana pour SQL
- Visualisation de données métier E-Banking

---

**🎓 Félicitations !** Vous maîtrisez maintenant Prometheus et PromQL !
