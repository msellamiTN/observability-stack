# 🎯 Templates et Variables Grafana - Guide Complet

## 📋 Objectifs

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les différents types de variables Grafana
- ✅ Créer des variables depuis vos datasources (Query Variables)
- ✅ Chaîner des variables pour créer des filtres hiérarchiques
- ✅ Utiliser les variables dans vos requêtes et titres de panels
- ✅ Créer des dashboards dynamiques et réutilisables

---

## 🎓 Partie 1: Introduction aux Variables (30min)

### Qu'est-ce qu'une Variable ?

Une **variable** dans Grafana est un placeholder dynamique qui peut être utilisé dans :
- Les requêtes de vos panels
- Les titres de panels et de dashboards
- Les annotations
- Les liens

**Avantages** :
- 🔄 Dashboards réutilisables
- 🎯 Filtrage dynamique des données
- 📊 Réduction du nombre de dashboards
- 👥 Expérience utilisateur améliorée

---

### Types de Variables

| Type | Description | Exemple |
|------|-------------|---------|
| **Query** | Valeurs depuis datasource | `label_values(up, instance)` |
| **Custom** | Liste statique | `prod,staging,dev` |
| **Constant** | Valeur fixe cachée | `my-cluster-name` |
| **Interval** | Intervalles temporels | `1m,5m,15m,1h` |
| **Datasource** | Sélection datasource | Liste des Prometheus |
| **Ad hoc** | Filtres dynamiques | Ajout automatique de filtres |
| **Text box** | Saisie libre | Input utilisateur |

---

## 🔧 Partie 2: Query Variables (1h)

### Créer une Variable depuis Prometheus

#### Exercice 1: Variable "Region"

**Étape 1 - Accéder aux Variables** :
```
Dashboard → Settings (⚙️) → Variables → Add variable
```

**Étape 2 - Configuration** :
```yaml
Name: region
Type: Query
Label: Region
Data source: Prometheus

Query: label_values(up, region)

Refresh: On Dashboard Load
Sort: Alphabetical (asc)

Selection options:
  ☑ Multi-value
  ☑ Include All option
  
Preview of values: [All, EU, US, ASIA]
```

**Étape 3 - Sauvegarder** :
```
→ Update → Save dashboard
```

**Étape 4 - Tester** :
Vous devriez voir un dropdown en haut du dashboard avec les régions disponibles.

---

#### Exercice 2: Variable "Job" (Services)

```yaml
Name: job
Type: Query
Label: Service
Data source: Prometheus

Query: label_values(up, job)

Refresh: On Dashboard Load
Sort: Alphabetical (asc)

Selection options:
  ☑ Multi-value
  ☑ Include All option
```

**Requêtes PromQL Utiles** :

```promql
# Lister tous les jobs
label_values(up, job)

# Lister toutes les instances
label_values(up, instance)

# Lister les status codes HTTP
label_values(http_requests_total, status)

# Lister les métriques disponibles
label_values(__name__)

# Lister les environnements
label_values(up, environment)
```

---

#### Exercice 3: Variables depuis InfluxDB (Flux)

```yaml
Name: bucket
Type: Query
Data source: InfluxDB

Query (Flux):
buckets()
  |> filter(fn: (r) => r.name !~ /^_/)
  |> keep(columns: ["name"])
```

**Autres Requêtes Flux** :

```flux
// Liste des measurements
from(bucket: "payments")
  |> range(start: -30d)
  |> keep(columns: ["_measurement"])
  |> distinct(column: "_measurement")

// Liste des valeurs d'un tag
from(bucket: "payments")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> keep(columns: ["region"])
  |> distinct(column: "region")
```

---

#### Exercice 4: Variables depuis MS SQL

```yaml
Name: database
Type: Query
Data source: MS SQL Server - E-Banking

Query (SQL):
SELECT name 
FROM sys.databases 
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
ORDER BY name
```

**Autres Requêtes SQL** :

```sql
-- Liste des tables
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Valeurs uniques d'une colonne
SELECT DISTINCT Region 
FROM Customers 
WHERE Region IS NOT NULL
ORDER BY Region;

-- Dates disponibles
SELECT DISTINCT CAST(TransactionDate AS DATE) as Date
FROM Transactions
WHERE TransactionDate >= DATEADD(day, -30, GETDATE())
ORDER BY Date DESC;
```

---

## 🔗 Partie 3: Variables Hiérarchiques (1h30)

### Concept de Chaînage

Les variables peuvent **dépendre les unes des autres** pour créer des filtres en cascade.

**Exemple d'Architecture** :
```
$region (All, EU, US, ASIA)
  └── $datacenter (depends on $region)
       └── $server (depends on $datacenter)
            └── $metric (independent)
```

---

### Exercice Complet: Monitoring Infrastructure

#### Variable 1: Region (Niveau 1)

```yaml
Name: region
Query: label_values(up, region)
Multi-value: Yes
Include All: Yes
```

#### Variable 2: Datacenter (Niveau 2 - dépend de region)

```yaml
Name: datacenter
Query: label_values(up{region=~"$region"}, datacenter)
Multi-value: Yes
Include All: Yes
```

**Note** : `region=~"$region"` filtre les valeurs en fonction de la région sélectionnée.

#### Variable 3: Server (Niveau 3 - dépend de datacenter)

```yaml
Name: server
Query: label_values(up{region=~"$region", datacenter=~"$datacenter"}, instance)
Multi-value: Yes
Include All: Yes
```

#### Variable 4: Metric (Indépendante)

```yaml
Name: metric
Type: Custom
Values: cpu,memory,disk,network
Multi-value: No
```

---

### Utiliser les Variables dans les Requêtes

#### Panel CPU Usage

```promql
# Sans variable (statique)
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Avec variables (dynamique)
100 - (avg by(instance) (rate(node_cpu_seconds_total{
  mode="idle",
  region=~"$region",
  datacenter=~"$datacenter",
  instance=~"$server"
}[5m])) * 100)
```

**Explications** :
- `=~"$region"` : Regex match, supporte multi-value
- `="$region"` : Exact match, ne supporte pas multi-value
- `$region` : Remplacé par la valeur sélectionnée

#### Panel Memory Usage

```promql
(node_memory_MemTotal_bytes{region=~"$region", instance=~"$server"} - 
 node_memory_MemAvailable_bytes{region=~"$region", instance=~"$server"}) / 
node_memory_MemTotal_bytes{region=~"$region", instance=~"$server"} * 100
```

#### Panel Disk Usage

```promql
100 - (node_filesystem_avail_bytes{
  region=~"$region",
  datacenter=~"$datacenter",
  instance=~"$server",
  mountpoint="/"
} / node_filesystem_size_bytes{
  region=~"$region",
  datacenter=~"$datacenter",
  instance=~"$server",
  mountpoint="/"
} * 100)
```

---

## 🎨 Partie 4: Usage Avancé (1h)

### Variables dans les Titres

**Titre Dashboard** :
```
Infrastructure Monitoring - $region - $datacenter
```

**Titre Panel** :
```
CPU Usage - $server
Request Rate - $job ($region)
Memory - ${server:percentencode}
```

**Formattage Variables** :

| Format | Syntaxe | Résultat | Usage |
|--------|---------|----------|-------|
| Brut | `$variable` | `value` | Standard |
| CSV | `${variable:csv}` | `"v1","v2"` | SQL IN |
| Pipe | `${variable:pipe}` | `v1\|v2` | Regex |
| Regex | `${variable:regex}` | `(v1\|v2)` | PromQL |
| JSON | `${variable:json}` | `["v1","v2"]` | JSON |
| Distributed | `${variable:distributed}` | `v1,v2` | - |
| URL Encode | `${variable:percentencode}` | `v1%20v2` | URLs |

---

### Variables Interval

**Configuration** :
```yaml
Name: interval
Type: Interval
Label: Resolution

Auto Option: Yes
Auto min interval: 10s

Values: 10s,30s,1m,5m,10m,30m,1h,6h,12h,1d

Current value: auto
```

**Usage dans Requêtes** :
```promql
# Sans interval variable
rate(http_requests_total[5m])

# Avec interval variable (s'adapte au time range)
rate(http_requests_total[$interval])

# Avec minimum interval
rate(http_requests_total[$__rate_interval])
```

**Avantages** :
- Performance optimisée selon le zoom
- Résolution adaptative
- Moins de points de données sur grands time ranges

---

### Variables Datasource

**Configuration** :
```yaml
Name: datasource
Type: Datasource
Label: Data Source

Datasource type: Prometheus

Multi-value: No
Include All: No
```

**Usage** :
```
Panel → Query → Data source → ${datasource}
```

**Use Case** :
- Comparer plusieurs instances Prometheus
- Basculer entre prod/staging
- Multi-cluster monitoring

---

### Repeat Panels

**Configuration Panel** :
```
Panel → Repeat options
  Repeat by variable: $server
  Max per row: 4
```

**Résultat** :
Si `$server = [server1, server2, server3, server4, server5]`, Grafana créera automatiquement :
- Row 1: Panel server1, Panel server2, Panel server3, Panel server4
- Row 2: Panel server5

**Use Cases** :
- Monitoring multi-serveurs
- Comparaison de métriques par environnement
- Dashboards par région

---

### Repeat Rows

**Configuration Row** :
```
Row → Settings
  Repeat for: $region
```

Chaque row sera dupliquée pour chaque valeur de `$region`.

---

### Variables Dépendantes Complexes

**Scénario** : Filtrer par Application ET Version

```yaml
# Variable 1: Application
Name: app
Query: label_values(app_info, app_name)

# Variable 2: Version (dépend de app)
Name: version
Query: label_values(app_info{app_name="$app"}, version)

# Variable 3: Instance (dépend de app ET version)
Name: instance
Query: label_values(app_info{app_name="$app", version="$version"}, instance)
```

**Requête Panel** :
```promql
rate(http_requests_total{
  app_name="$app",
  version="$version",
  instance=~"$instance"
}[5m])
```

---

### Variables avec Regex

**Filtrer instances par pattern** :
```yaml
Name: prod_servers
Query: label_values(up{instance=~".*prod.*"}, instance)
```

**Exclure certaines valeurs** :
```yaml
Name: non_system_jobs
Query: label_values(up{job!~"node-exporter|prometheus"}, job)
```

---

## 🎯 TP Pratique Complet (1h)

### Objectif
Créer un dashboard de monitoring E-Banking avec variables hiérarchiques.

### Spécifications

**Variables à Créer** :

1. **$region** : Query variable
   - Query: `label_values(up, region)`
   - Multi-value: Yes, Include All: Yes

2. **$environment** : Custom variable
   - Values: `production,staging,development`
   - Default: `production`

3. **$service** : Query variable (dépend de region)
   - Query: `label_values(up{region=~"$region"}, job)`
   - Multi-value: Yes, Include All: Yes

4. **$instance** : Query variable (dépend de service)
   - Query: `label_values(up{region=~"$region", job=~"$service"}, instance)`
   - Multi-value: Yes, Include All: Yes

5. **$interval** : Interval variable
   - Values: `10s,30s,1m,5m,15m,30m,1h`
   - Auto: Yes

---

### Panels à Créer

#### Panel 1: Request Rate
```promql
sum(rate(http_requests_total{
  region=~"$region",
  job=~"$service",
  instance=~"$instance"
}[$interval])) by (job)
```

**Type**: Graph  
**Titre**: `Request Rate - $service ($region)`  
**Unit**: req/s  
**Legend**: `{{job}}`

---

#### Panel 2: Latency p95
```promql
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket{
    region=~"$region",
    job=~"$service",
    instance=~"$instance"
  }[$interval])) by (le, job)
)
```

**Type**: Graph  
**Titre**: `API Latency p95 - $service`  
**Unit**: seconds (s)  
**Threshold**: Warning at 0.5s, Critical at 1s

---

#### Panel 3: Error Rate
```promql
(sum(rate(http_requests_total{
  status=~"5..",
  region=~"$region",
  job=~"$service",
  instance=~"$instance"
}[$interval])) / 
sum(rate(http_requests_total{
  region=~"$region",
  job=~"$service",
  instance=~"$instance"
}[$interval]))) * 100
```

**Type**: Gauge  
**Titre**: `Error Rate % - $service`  
**Unit**: percent (0-100)  
**Thresholds**: Green < 1%, Yellow < 5%, Red >= 5%

---

#### Panel 4: Active Connections
```promql
sum(http_connections_active{
  region=~"$region",
  job=~"$service",
  instance=~"$instance"
}) by (instance)
```

**Type**: Stat  
**Titre**: `Active Connections`  
**Repeat by**: `$instance` (max 6 per row)

---

#### Panel 5: Top Services by Traffic
```promql
topk(10, sum by (job) (
  rate(http_requests_total{
    region=~"$region"
  }[$interval])
))
```

**Type**: Bar Chart  
**Titre**: `Top 10 Services - $region`  
**Orientation**: Horizontal

---

### Configuration Dashboard

```yaml
Title: "E-Banking Monitoring - ${region} - ${environment}"

Time settings:
  - Default range: Last 6 hours
  - Refresh: 30s
  - Auto-refresh: Enabled

Variables order:
  1. region
  2. environment
  3. service
  4. instance
  5. interval

Layout:
  Row 1: Request Rate, Latency p95, Error Rate
  Row 2: Active Connections (repeat by $instance)
  Row 3: Top Services
```

---

## ✅ Critères de Réussite

- [ ] 5 variables créées et fonctionnelles
- [ ] Variables hiérarchiques (service dépend de region)
- [ ] 5 panels avec requêtes utilisant les variables
- [ ] Repeat panel opérationnel ($instance)
- [ ] Titre dashboard dynamique avec variables
- [ ] Changement de région met à jour tous les panels
- [ ] Sélection "All" fonctionne correctement
- [ ] Multi-value selections fonctionnent

---

## 📚 Bonnes Pratiques

### Nommage
- ✅ Noms courts et explicites: `region`, `service`, `env`
- ❌ Éviter: `my_variable_for_region_selection`

### Performance
- ✅ Utiliser `label_values()` pour les labels existants
- ✅ Limiter les multi-value à des cardinalités raisonnables
- ❌ Éviter les query variables trop complexes

### UX
- ✅ Utiliser des labels clairs: "Region" au lieu de "region"
- ✅ Trier alphabétiquement les valeurs
- ✅ Mettre "All" en premier quand pertinent
- ✅ Grouper les variables logiquement

### Maintenance
- ✅ Documenter les dépendances entre variables
- ✅ Tester avec "All" et valeurs spécifiques
- ✅ Vérifier le comportement sans données
- ✅ Utiliser des defaults sensés

---

## 🐛 Troubleshooting

### Problème: Variable vide

**Causes** :
1. Requête retourne aucune valeur
2. Datasource non disponible
3. Permissions insuffisantes

**Solution** :
```
Dashboard Settings → Variables → [Variable] → Test query
```

---

### Problème: Variable ne se met pas à jour

**Causes** :
1. Refresh setting incorrect
2. Cache datasource

**Solution** :
```yaml
Refresh: On Dashboard Load  # ou On Time Range Change
```

---

### Problème: Multi-value ne fonctionne pas

**Cause** : Utilisation de `=` au lieu de `=~`

**❌ Incorrect** :
```promql
up{instance="$server"}
```

**✅ Correct** :
```promql
up{instance=~"$server"}
```

---

### Problème: Variable dépendante ne filtre pas

**Cause** : Mauvaise référence à la variable parent

**✅ Correct** :
```promql
label_values(up{region=~"$region"}, datacenter)
```

**Note** : Utilisez `=~` même pour variable single-value pour compatibilité.

---

## 🎓 Exercices Supplémentaires

### Exercice 1: Dashboard Multi-Datasources

Créer un dashboard utilisant variables pour:
- Prometheus (métriques système)
- InfluxDB (métriques applicatives)
- MS SQL (données business)

**Variables** :
- $datasource_prometheus (type: Datasource)
- $datasource_influxdb (type: Datasource)
- $datasource_sql (type: Datasource)

---

### Exercice 2: Time-based Variables

Créer variables pour comparer périodes:
- $timeshift: `-1d`, `-1w`, `-1m`, `-1y`
- Requête comparant now vs $timeshift

```promql
# Métrique actuelle
rate(metric[5m])

# vs

# Métrique période précédente
rate(metric[5m] offset $timeshift)
```

---

### Exercice 3: Variables Calculées

Créer variable avec regex processing:
```yaml
Name: pod_name
Query: label_values(kube_pod_info, pod)
Regex: /^(.*)-[a-z0-9]{10}-[a-z0-9]{5}$/
```

Extrait le nom du deployment depuis le nom du pod.

---

## 📖 Ressources

- [Grafana Variables Documentation](https://grafana.com/docs/grafana/latest/dashboards/variables/)
- [PromQL Label Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/#label_values)
- [Flux Query Language](https://docs.influxdata.com/flux/)

---

## 🎉 Conclusion

Vous maîtrisez maintenant :
- ✅ Les types de variables Grafana
- ✅ La création de query variables
- ✅ Le chaînage de variables hiérarchiques
- ✅ L'utilisation avancée (repeat, formatting)
- ✅ Les bonnes pratiques de templating

**Prochaine étape** : Créer des dashboards production-ready réutilisables avec templating complet !
