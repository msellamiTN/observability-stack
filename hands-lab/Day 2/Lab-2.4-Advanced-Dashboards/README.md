# 📊 Lab 2.4 : Création et Gestion de Dashboards Avancés

**Durée estimée** : 3 heures  
**Niveau** : Intermédiaire à Avancé  
**Prérequis** : Lab 1.4 (Prometheus), Lab 1.5 (PromQL)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Maîtriser les concepts fondamentaux (panels, rows, time range, refresh)
- ✅ Utiliser tous les types de visualisations appropriés
- ✅ Construire des requêtes avec Query Builder et mode éditeur
- ✅ Créer des dashboards SLA/SLO
- ✅ Monitorer les performances système
- ✅ Implémenter l'observabilité applicative
- ✅ Utiliser les labels pour segmenter les données

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que les services sont démarrés
docker ps | grep -E "grafana|prometheus|ebanking|node|payment"
```

### Métriques Disponibles

Votre stack expose les métriques suivantes :

| Source | Métriques | Description |
|--------|-----------|-------------|
| **eBanking Exporter** | `ebanking_*` | Métriques métier (transactions, sessions, comptes) |
| **Payment API** | `payment_*`, `http_*` | Métriques applicatives |
| **Node Exporter** | `node_*` | Métriques système (CPU, RAM, Disk, Network) |
| **Prometheus** | `prometheus_*` | Métriques Prometheus |
| **Grafana** | `grafana_*` | Métriques Grafana |

---

## 📚 Partie 1 : Concepts Fondamentaux (30 min)

### 1.1 Structure d'un Dashboard

```
Dashboard
├── Settings (nom, tags, variables)
├── Time Range (période affichée)
├── Refresh Interval (auto-refresh)
└── Rows
    └── Panels
        ├── Visualization Type
        ├── Query
        ├── Transform
        └── Options
```

### 1.2 Composants Essentiels

#### Panels

Un **panel** est l'unité de base d'un dashboard.

**Types principaux** :
- **Time series** : Graphiques temporels
- **Stat** : Valeur unique avec tendance
- **Gauge** : Jauge circulaire ou linéaire
- **Bar gauge** : Barres horizontales/verticales
- **Table** : Données tabulaires
- **Heatmap** : Carte de chaleur
- **Pie chart** : Camembert
- **State timeline** : États dans le temps

#### Rows

Les **rows** organisent les panels horizontalement.

**Bonnes pratiques** :
- Grouper les panels par thématique
- Utiliser des rows collapsibles pour les détails
- Ordre logique : Vue d'ensemble → Détails

#### Time Range

Contrôle la période de données affichée.

**Options** :
- Relative : Last 5m, Last 1h, Last 24h
- Absolute : Date/heure précises
- Quick ranges : Today, Yesterday, This week

#### Refresh

Actualisation automatique des données.

**Intervalles courants** :
- Production : 30s - 1m
- Développement : 5s - 10s
- Dashboards temps réel : 5s
- Dashboards historiques : Off

---

## 🎨 Partie 2 : Types de Visualisations (45 min)

### 2.1 Time Series (Graphiques Temporels)

**Usage** : Évolution de métriques dans le temps

**Exemple** : Transactions par seconde

```promql
rate(ebanking_transactions_processed_total[5m])
```

**Configuration** :
- **Draw style** : Lines, Bars, Points
- **Line interpolation** : Linear, Smooth, Step
- **Fill opacity** : 0-100%
- **Point size** : 1-10
- **Stack** : None, Normal, 100%

**Cas d'usage** :
- Trafic HTTP
- Latence
- Taux d'erreurs
- Utilisation CPU/RAM

### 2.2 Stat (Valeur Unique)

**Usage** : Afficher une valeur actuelle avec tendance

**Exemple** : Sessions actives

```promql
ebanking_active_sessions
```

**Configuration** :
- **Calculation** : Last, Mean, Min, Max, Sum
- **Orientation** : Auto, Horizontal, Vertical
- **Color mode** : Value, Background
- **Graph mode** : None, Area, Line
- **Text mode** : Auto, Value, Value and name, Name

**Cas d'usage** :
- KPIs (uptime, taux de succès)
- Compteurs (utilisateurs actifs)
- Valeurs instantanées

### 2.3 Gauge (Jauge)

**Usage** : Visualiser une valeur par rapport à des seuils

**Exemple** : Utilisation CPU

```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Configuration** :
- **Min** : 0
- **Max** : 100
- **Thresholds** :
  - 0-70 : Green
  - 70-85 : Yellow
  - 85-100 : Red
- **Show threshold labels** : Yes
- **Show threshold markers** : Yes

**Cas d'usage** :
- Utilisation ressources (%)
- Scores de satisfaction
- Taux de disponibilité

### 2.4 Table (Tableau)

**Usage** : Afficher des données structurées

**Exemple** : Top 5 endpoints par latence

```promql
topk(5, 
  histogram_quantile(0.95, 
    rate(ebanking_request_duration_seconds_bucket[5m])
  )
)
```

**Configuration** :
- **Column filters** : Hide/show columns
- **Column width** : Auto, Fixed
- **Cell display mode** : Auto, Color text, Color background
- **Sortable** : Yes/No

**Cas d'usage** :
- Top N (erreurs, latence, trafic)
- Listes d'alertes
- Inventaires

### 2.5 Heatmap (Carte de Chaleur)

**Usage** : Distribution de valeurs dans le temps

**Exemple** : Distribution de latence

```promql
sum(rate(ebanking_request_duration_seconds_bucket[5m])) by (le)
```

**Configuration** :
- **Calculate from data** : Yes
- **Y Axis** : Buckets
- **Color scheme** : Spectral, Blues, Greens
- **Color space** : RGB, HSL

**Cas d'usage** :
- Distribution de latence (histogrammes)
- Patterns temporels
- Anomalies visuelles

### 2.6 Pie Chart (Camembert)

**Usage** : Répartition en pourcentages

**Exemple** : Répartition par type de transaction

```promql
sum by (transaction_type) (
  increase(ebanking_transactions_processed_total{status="success"}[1h])
)
```

**Configuration** :
- **Pie chart type** : Pie, Donut
- **Legend** : Values, Percent, Both
- **Legend placement** : Bottom, Right, Top

**Cas d'usage** :
- Répartition par catégorie
- Parts de marché
- Distribution de ressources

---

## 🔧 Partie 3 : Construction de Requêtes (60 min)

### 3.1 Query Builder vs Mode Éditeur

#### Query Builder (Mode Visuel)

**Avantages** :
- Interface graphique intuitive
- Découverte des métriques
- Moins d'erreurs de syntaxe

**Exemple** :
```
Metric: ebanking_transactions_processed_total
Label filters: status = success
Operations: Rate (5m)
```

#### Mode Éditeur (PromQL Direct)

**Avantages** :
- Contrôle total
- Requêtes complexes
- Copier/coller facilement

**Exemple** :
```promql
sum(rate(ebanking_transactions_processed_total{status="success"}[5m])) by (transaction_type)
```

### 3.2 Requêtes PromQL Essentielles

#### Taux de Requêtes (Rate)

```promql
# Requêtes par seconde
rate(ebanking_api_requests_total[5m])

# Par endpoint
sum(rate(ebanking_api_requests_total[5m])) by (endpoint)

# Taux de succès
sum(rate(ebanking_api_requests_total{status_code="200"}[5m])) 
/ 
sum(rate(ebanking_api_requests_total[5m])) * 100
```

#### Latence (Percentiles)

```promql
# P50 (médiane)
histogram_quantile(0.50, 
  rate(ebanking_request_duration_seconds_bucket[5m])
)

# P95
histogram_quantile(0.95, 
  rate(ebanking_request_duration_seconds_bucket[5m])
)

# P99
histogram_quantile(0.99, 
  rate(ebanking_request_duration_seconds_bucket[5m])
)
```

#### Taux d'Erreurs

```promql
# Taux d'erreurs global
sum(rate(ebanking_api_requests_total{status_code=~"5.."}[5m])) 
/ 
sum(rate(ebanking_api_requests_total[5m])) * 100

# Erreurs par endpoint
sum(rate(ebanking_api_requests_total{status_code=~"5.."}[5m])) by (endpoint)
```

#### Agrégations

```promql
# Somme
sum(ebanking_active_sessions)

# Moyenne
avg(ebanking_active_sessions)

# Min/Max
min(ebanking_active_sessions)
max(ebanking_active_sessions)

# Count
count(up == 1)

# Top K
topk(5, rate(ebanking_api_requests_total[5m]))

# Bottom K
bottomk(5, rate(ebanking_api_requests_total[5m]))
```

---

## 🎯 Exercice Pratique 1 : Dashboard SLA/SLO (45 min)

### Objectif

Créer un dashboard de suivi SLA/SLO pour l'application eBanking.

### SLI/SLO Définis

| Indicateur | SLI | SLO | Calcul |
|------------|-----|-----|--------|
| **Availability** | Uptime | 99.9% | `up == 1` |
| **Success Rate** | HTTP 2xx/5xx | 99.5% | `status_code !~ "5.."` |
| **Latency P95** | Request duration | < 500ms | `histogram_quantile(0.95, ...)` |
| **Error Budget** | Remaining errors | > 0% | `(1 - error_rate) - SLO` |

### Structure du Dashboard

#### Row 1 : SLO Overview (4 panels)

**Panel 1.1 : Availability (Gauge)**

**Query** :
```promql
avg(up{job="ebanking-exporter"}) * 100
```

**Configuration** :
- Type : Gauge
- Min : 0, Max : 100
- Unit : Percent (0-100)
- Thresholds :
  - 0-99 : Red
  - 99-99.9 : Yellow
  - 99.9-100 : Green
- Title : "Availability SLO (Target: 99.9%)"

**Panel 1.2 : Success Rate (Gauge)**

**Query** :
```promql
sum(rate(ebanking_api_requests_total{status_code!~"5.."}[5m])) 
/ 
sum(rate(ebanking_api_requests_total[5m])) * 100
```

**Configuration** :
- Type : Gauge
- Thresholds :
  - 0-99 : Red
  - 99-99.5 : Yellow
  - 99.5-100 : Green
- Title : "Success Rate SLO (Target: 99.5%)"

**Panel 1.3 : Latency P95 (Stat)**

**Query** :
```promql
histogram_quantile(0.95, 
  rate(ebanking_request_duration_seconds_bucket[5m])
) * 1000
```

**Configuration** :
- Type : Stat
- Unit : milliseconds (ms)
- Thresholds :
  - 0-500 : Green
  - 500-1000 : Yellow
  - 1000+ : Red
- Title : "Latency P95 SLO (Target: < 500ms)"

**Panel 1.4 : Error Budget (Stat)**

**Query** :
```promql
(1 - (
  sum(rate(ebanking_api_requests_total{status_code=~"5.."}[30d])) 
  / 
  sum(rate(ebanking_api_requests_total[30d]))
) - 0.995) * 100
```

**Configuration** :
- Type : Stat
- Unit : Percent (0-100)
- Color mode : Value
- Thresholds :
  - 0-10 : Red (budget épuisé)
  - 10-50 : Yellow
  - 50-100 : Green
- Title : "Error Budget Remaining (30d)"

#### Row 2 : HTTP Status Codes (2 panels)

**Panel 2.1 : HTTP Status Distribution (Time series)**

**Queries** :
```promql
# 2xx Success
sum(rate(ebanking_api_requests_total{status_code=~"2.."}[5m]))

# 4xx Client Errors
sum(rate(ebanking_api_requests_total{status_code=~"4.."}[5m]))

# 5xx Server Errors
sum(rate(ebanking_api_requests_total{status_code=~"5.."}[5m]))
```

**Configuration** :
- Type : Time series
- Legend : {{status_code}}
- Stack : Normal
- Fill opacity : 30%

**Panel 2.2 : Error Rate by Endpoint (Table)**

**Query** :
```promql
sum(rate(ebanking_api_requests_total{status_code=~"5.."}[5m])) by (endpoint) 
/ 
sum(rate(ebanking_api_requests_total[5m])) by (endpoint) * 100
```

**Configuration** :
- Type : Table
- Sort : Descending
- Cell display : Color background
- Thresholds : 0 (green), 1 (yellow), 5 (red)

### ✅ Critères de Réussite

- [ ] Dashboard créé avec 2 rows
- [ ] 6 panels configurés
- [ ] Toutes les requêtes fonctionnent
- [ ] Thresholds appropriés
- [ ] Dashboard sauvegardé

---

## 💻 Exercice Pratique 2 : Dashboard Performance Système (45 min)

### Objectif

Créer un dashboard de monitoring système complet (méthode USE).

### Méthode USE

**U**tilization - **S**aturation - **E**rrors

| Ressource | Utilization | Saturation | Errors |
|-----------|-------------|------------|--------|
| **CPU** | % usage | Load average | Context switches |
| **Memory** | % used | Swap usage | OOM kills |
| **Disk** | % used | IO wait | Read/write errors |
| **Network** | Bandwidth | Queue length | Packet drops |

### Structure du Dashboard

#### Row 1 : CPU (3 panels)

**Panel 1.1 : CPU Usage (Time series)**

**Query** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Panel 1.2 : CPU by Mode (Time series stacked)**

**Queries** :
```promql
avg(rate(node_cpu_seconds_total{mode="user"}[5m])) * 100
avg(rate(node_cpu_seconds_total{mode="system"}[5m])) * 100
avg(rate(node_cpu_seconds_total{mode="iowait"}[5m])) * 100
avg(rate(node_cpu_seconds_total{mode="steal"}[5m])) * 100
```

**Panel 1.3 : Load Average (Gauge)**

**Query** :
```promql
node_load1
```

#### Row 2 : Memory (3 panels)

**Panel 2.1 : Memory Usage (Gauge)**

**Query** :
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Panel 2.2 : Memory Details (Time series)**

**Queries** :
```promql
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
node_memory_Buffers_bytes
node_memory_Cached_bytes
```

**Panel 2.3 : Swap Usage (Stat)**

**Query** :
```promql
(node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes * 100
```

#### Row 3 : Disk (3 panels)

**Panel 3.1 : Disk Usage (Bar gauge)**

**Query** :
```promql
(node_filesystem_size_bytes{fstype!~"tmpfs|fuse.*"} - node_filesystem_avail_bytes) 
/ 
node_filesystem_size_bytes * 100
```

**Panel 3.2 : Disk I/O (Time series)**

**Queries** :
```promql
# Read
rate(node_disk_read_bytes_total[5m])

# Write
rate(node_disk_written_bytes_total[5m])
```

**Panel 3.3 : Disk IOPS (Time series)**

**Queries** :
```promql
rate(node_disk_reads_completed_total[5m])
rate(node_disk_writes_completed_total[5m])
```

#### Row 4 : Network (2 panels)

**Panel 4.1 : Network Traffic (Time series)**

**Queries** :
```promql
# Receive
rate(node_network_receive_bytes_total{device!~"lo|veth.*"}[5m])

# Transmit
rate(node_network_transmit_bytes_total{device!~"lo|veth.*"}[5m])
```

**Panel 4.2 : Network Errors (Time series)**

**Queries** :
```promql
rate(node_network_receive_errs_total[5m])
rate(node_network_transmit_errs_total[5m])
```

---

## 📖 Ressources

### Documentation Officielle

- [Grafana Panels](https://grafana.com/docs/grafana/latest/panels/)
- [Visualization Types](https://grafana.com/docs/grafana/latest/panels/visualizations/)
- [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### Dashboards Communautaires

- [Node Exporter Full](https://grafana.com/grafana/dashboards/1860)
- [Prometheus 2.0 Stats](https://grafana.com/grafana/dashboards/3662)

---

## ✅ Checklist de Validation

- [ ] Comprendre panels, rows, time range, refresh
- [ ] Maîtriser 6+ types de visualisations
- [ ] Utiliser Query Builder et mode éditeur
- [ ] Dashboard SLA/SLO créé et fonctionnel
- [ ] Dashboard système USE créé
- [ ] Requêtes PromQL optimisées
- [ ] Thresholds appropriés configurés

---

## 🔙 Navigation

- [⬅️ Retour au Jour 2](../README.md)
- [➡️ Lab suivant : Lab 2.5 - EBanking Monitoring](../Lab-2.5-EBanking-Monitoring/)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

**🎉 Félicitations !** Vous maîtrisez maintenant la création de dashboards avancés !
