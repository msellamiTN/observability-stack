# 🎛️ Lab 2.7 : Variables et Templates Multi-Niveau

**Durée estimée** : 2h30  
**Niveau** : Avancé  
**Prérequis** : Lab 2.4 (Dashboards), Lab 2.6 (Construction Avancée)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Créer des variables multi-niveau (région → serveur → métrique)
- ✅ Implémenter des dépendances entre variables
- ✅ Utiliser des variables dans les requêtes PromQL
- ✅ Créer des dashboards dynamiques et réutilisables
- ✅ Implémenter des filtres en cascade
- ✅ Optimiser les performances avec des variables

---

## 📋 Prérequis

### Services Requis

```bash
# Vérifier que les services sont actifs
docker ps | grep -E "grafana|prometheus|ebanking|node"

# Accès Grafana
URL: http://localhost:3000
User: admin
Password: GrafanaSecure123!Change@Me
```

### Métriques Disponibles

Votre stack expose des métriques avec les labels suivants :

| Label | Valeurs Possibles | Description |
|-------|-------------------|-------------|
| **environment** | training, development, staging, production | Environnement |
| **region** | eu-west-1, eu-central-1, us-east-1 | Région géographique |
| **instance** | localhost:9100, node-exporter:9100 | Instance serveur |
| **job** | ebanking-exporter, node-exporter, prometheus | Job Prometheus |
| **endpoint** | /api/v1/transfer, /api/v1/balance, etc. | Endpoint API |
| **transaction_type** | transfer, payment, withdrawal, deposit | Type de transaction |
| **status** | success, failed, pending, cancelled | Statut |

---

## 🎨 Architecture des Variables Multi-Niveau

### Hiérarchie des Variables

```
Level 1: Environment (training, production, staging)
    ↓
Level 2: Region (eu-west-1, eu-central-1, us-east-1)
    ↓
Level 3: Instance (server-01, server-02, server-03)
    ↓
Level 4: Metric Type (CPU, Memory, Disk, Network)
    ↓
Level 5: Endpoint (API endpoints dynamiques)
```

### Dépendances en Cascade

```
$environment → filtre $region
$region → filtre $instance
$instance → filtre $metric
$metric → filtre les panels
```

---

## 📝 PARTIE 1 : Création du Dashboard de Base (15 min)

### Étape 1.1 : Créer le Dashboard

1. **Grafana** → **Dashboards** → **New** → **New Dashboard**
2. **Settings** (⚙️) → **General**

```
Name: Multi-Level Variables Dashboard - Advanced Filtering
Description: Dashboard avec variables multi-niveau pour filtrage dynamique
Tags: variables, templates, advanced, ebanking
Folder: Default
```

3. **Save dashboard**

---

## 🎛️ PARTIE 2 : Variables Niveau 1 - Environment (20 min)

### Étape 2.1 : Créer la Variable Environment

1. **Settings** (⚙️) → **Variables** → **Add variable**

#### Configuration de Base

```
Name: environment
Type: Query
Label: Environment
Description: Sélectionner l'environnement (training, production, staging)
```

#### Query Options

```
Data source: Prometheus
Query type: Label values
Label: environment
Metric: ebanking_app_info
```

**Requête générée** :
```promql
label_values(ebanking_app_info, environment)
```

#### Selection Options

```
Multi-value: ✓ (coché)
Include All option: ✓ (coché)
Custom all value: .*
```

#### Preview of values

Vous devriez voir :
```
- All
- training
- development
- staging
- production
```

2. **Apply** → **Save dashboard**

### Étape 2.2 : Tester la Variable

1. **Retour au dashboard**
2. **En haut**, vous devriez voir : `Environment: All ▼`
3. **Cliquer** sur le dropdown
4. **Sélectionner** différentes valeurs

---

## 🌍 PARTIE 3 : Variables Niveau 2 - Region (Dépendante) (30 min)

### Étape 3.1 : Créer la Variable Region

1. **Settings** → **Variables** → **Add variable**

#### Configuration de Base

```
Name: region
Type: Query
Label: Region
Description: Région géographique (dépend de l'environnement)
```

#### Query Options

```
Data source: Prometheus
Query type: Label values
Label: region
Metric: ebanking_app_info{environment=~"$environment"}
```

**Requête avec dépendance** :
```promql
label_values(ebanking_app_info{environment=~"$environment"}, region)
```

**Explication** :
- `{environment=~"$environment"}` : Filtre par la variable `$environment`
- La région change automatiquement quand on change l'environnement

#### Selection Options

```
Multi-value: ✓
Include All option: ✓
Custom all value: .*
```

#### Advanced Options

```
Sort: Alphabetical (asc)
Refresh: On Dashboard Load
```

2. **Apply** → **Save dashboard**

### Étape 3.2 : Tester la Dépendance

1. **Retour au dashboard**
2. **Sélectionner** `Environment: production`
3. **Observer** : La liste `Region` se met à jour automatiquement
4. **Sélectionner** `Environment: training`
5. **Observer** : La liste `Region` change

---

## 🖥️ PARTIE 4 : Variables Niveau 3 - Instance (30 min)

### Étape 4.1 : Créer la Variable Instance

1. **Settings** → **Variables** → **Add variable**

#### Configuration de Base

```
Name: instance
Type: Query
Label: Server Instance
Description: Instance serveur (dépend de l'environnement et de la région)
```

#### Query Options

```
Data source: Prometheus
Query type: Label values
Label: instance
Metric: up{environment=~"$environment",region=~"$region"}
```

**Requête avec double dépendance** :
```promql
label_values(up{environment=~"$environment",region=~"$region"}, instance)
```

**Explication** :
- Filtre par `$environment` ET `$region`
- Les instances changent selon les 2 variables précédentes

#### Selection Options

```
Multi-value: ✓
Include All option: ✓
Custom all value: .*
```

#### Advanced Options

```
Sort: Alphabetical (asc)
Refresh: On Dashboard Load
```

2. **Apply** → **Save dashboard**

### Étape 4.2 : Créer la Variable Job

1. **Add variable**

```
Name: job
Type: Query
Label: Job
Data source: Prometheus
Query: label_values(up{environment=~"$environment"}, job)
Multi-value: ✓
Include All option: ✓
```

**Requête** :
```promql
label_values(up{environment=~"$environment"}, job)
```

---

## 📊 PARTIE 5 : Variables Niveau 4 - Métrique Dynamique (30 min)

### Étape 5.1 : Créer la Variable Metric Type

1. **Settings** → **Variables** → **Add variable**

#### Configuration de Base

```
Name: metric_type
Type: Custom
Label: Metric Type
Description: Type de métrique à afficher
```

#### Custom Options

```
Custom options (comma separated):
CPU,Memory,Disk,Network,API,Transactions,Sessions
```

**Valeurs** :
```
CPU
Memory
Disk
Network
API
Transactions
Sessions
```

#### Selection Options

```
Multi-value: ✗ (décoché - une seule sélection)
Include All option: ✗ (décoché)
```

2. **Apply** → **Save dashboard**

### Étape 5.2 : Créer la Variable Endpoint (Conditionnelle)

1. **Add variable**

#### Configuration de Base

```
Name: endpoint
Type: Query
Label: API Endpoint
Description: Endpoint API (visible seulement si Metric Type = API)
```

#### Query Options

```
Data source: Prometheus
Query: label_values(ebanking_api_requests_total{environment=~"$environment"}, endpoint)
```

**Requête** :
```promql
label_values(ebanking_api_requests_total{environment=~"$environment"}, endpoint)
```

#### Selection Options

```
Multi-value: ✓
Include All option: ✓
```

#### Advanced Options

```
Show on dashboard: Variable (affiche seulement si utilisée)
```

---

## 🎨 PARTIE 6 : Panels Dynamiques avec Variables (60 min)

### Panel 6.1 : Métrique Dynamique selon Type

#### Étape 6.1.1 : Créer le Panel

1. **Add** → **Visualization** → **Time series**

#### Étape 6.1.2 : Configuration des Requêtes Conditionnelles

**Query A - CPU (si metric_type = CPU)** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle",instance=~"$instance",job=~"$job"}[5m])) * 100)
```

**Query B - Memory (si metric_type = Memory)** :
```promql
(1 - (node_memory_MemAvailable_bytes{instance=~"$instance",job=~"$job"} / node_memory_MemTotal_bytes{instance=~"$instance",job=~"$job"})) * 100
```

**Query C - API Requests (si metric_type = API)** :
```promql
sum(rate(ebanking_api_requests_total{environment=~"$environment",endpoint=~"$endpoint"}[5m])) by (endpoint)
```

**Query D - Transactions (si metric_type = Transactions)** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment",status=~"$status"}[5m])) by (transaction_type)
```

**Query E - Sessions (si metric_type = Sessions)** :
```promql
ebanking_active_sessions{environment=~"$environment"}
```

#### Étape 6.1.3 : Configuration du Panel

**Panel options** :
```
Title: $metric_type Metrics - $environment ($region)
Description: Métriques dynamiques filtrées par variables
```

**Standard options** :
```
Unit: Auto (change selon la métrique)
```

**Legend** :
```
Mode: Table
Placement: Bottom
Values: Mean, Max, Last
```

#### Étape 6.1.4 : Utilisation de Variables dans le Titre

Le titre utilise des variables :
```
$metric_type Metrics - $environment ($region)
```

**Exemples de rendu** :
- `CPU Metrics - production (eu-west-1)`
- `API Metrics - training (All)`
- `Memory Metrics - staging (eu-central-1)`

---

### Panel 6.2 : Table de Performance par Endpoint

#### Étape 6.2.1 : Créer le Panel

1. **Add** → **Visualization** → **Table**

#### Étape 6.2.2 : Configuration des Requêtes

**Query A - Requests/sec** :
```promql
sum(rate(ebanking_api_requests_total{environment=~"$environment",endpoint=~"$endpoint",job=~"$job"}[5m])) by (endpoint)
```

**Query B - P95 Latency** :
```promql
histogram_quantile(0.95, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment=~"$environment",endpoint=~"$endpoint"}[5m])) 
  by (le, endpoint)
) * 1000
```

**Query C - Error Rate** :
```promql
(
  sum(rate(ebanking_api_requests_total{environment=~"$environment",endpoint=~"$endpoint",status_code=~"5.."}[5m])) 
  by (endpoint) 
  / 
  sum(rate(ebanking_api_requests_total{environment=~"$environment",endpoint=~"$endpoint"}[5m])) 
  by (endpoint)
) * 100
```

**Configuration** :
- Format: **Table**
- Instant: **Yes** (coché)

#### Étape 6.2.3 : Transformations

**Transformation 1 : Merge**
1. **Transform** → **Add transformation** → **Merge**

**Transformation 2 : Organize fields**
1. **Add transformation** → **Organize fields**

```
Rename:
  endpoint → Endpoint
  Value #A → Requests/sec
  Value #B → P95 Latency (ms)
  Value #C → Error Rate %

Hide:
  Time
```

#### Étape 6.2.4 : Configuration du Panel

**Panel options** :
```
Title: API Performance - $environment - Endpoints: $endpoint
Description: Performance filtrée par environnement et endpoint
```

---

### Panel 6.3 : Gauge Dynamique avec Thresholds Variables

#### Étape 6.3.1 : Créer une Variable pour Thresholds

1. **Settings** → **Variables** → **Add variable**

```
Name: threshold_warning
Type: Constant
Label: Warning Threshold
Value: 70
```

2. **Add variable**

```
Name: threshold_critical
Type: Constant
Label: Critical Threshold
Value: 90
```

#### Étape 6.3.2 : Créer le Panel Gauge

1. **Add** → **Visualization** → **Gauge**

**Query** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle",instance=~"$instance"}[5m])) * 100)
```

**Thresholds** :
```
Mode: Absolute
Steps:
  - 0: Green
  - $threshold_warning: Yellow
  - $threshold_critical: Red
```

**Panel options** :
```
Title: CPU Usage - $instance (Warning: $threshold_warning%, Critical: $threshold_critical%)
```

---

## 🔄 PARTIE 7 : Variables Avancées (45 min)

### Variable 7.1 : Interval Dynamique

#### Étape 7.1.1 : Créer la Variable

1. **Settings** → **Variables** → **Add variable**

```
Name: interval
Type: Interval
Label: Time Interval
Description: Intervalle d'agrégation des métriques
```

#### Interval Options

```
Values: 1m,5m,10m,30m,1h,6h,12h,1d
Auto Option: ✓
Auto min interval: 1m
Auto step count: 30
```

#### Étape 7.1.2 : Utiliser dans les Requêtes

**Avant** :
```promql
rate(ebanking_api_requests_total[5m])
```

**Après** :
```promql
rate(ebanking_api_requests_total[$interval])
```

**Avantage** : L'intervalle s'adapte automatiquement au time range sélectionné.

---

### Variable 7.2 : Agrégation Dynamique

#### Étape 7.2.1 : Créer la Variable

```
Name: aggregation
Type: Custom
Label: Aggregation Function
Custom options: sum,avg,min,max,count
```

#### Étape 7.2.2 : Utiliser dans les Requêtes

**Requête dynamique** :
```promql
$aggregation(rate(ebanking_api_requests_total{environment=~"$environment"}[$interval])) by (endpoint)
```

**Exemples de rendu** :
- Si `$aggregation = sum` : `sum(rate(...)) by (endpoint)`
- Si `$aggregation = avg` : `avg(rate(...)) by (endpoint)`
- Si `$aggregation = max` : `max(rate(...)) by (endpoint)`

---

### Variable 7.3 : Grouping Dynamique

#### Étape 7.3.1 : Créer la Variable

```
Name: groupby
Type: Custom
Label: Group By
Custom options: endpoint,transaction_type,status,channel,region
Multi-value: ✓
```

#### Étape 7.3.2 : Utiliser dans les Requêtes

**Requête avec grouping dynamique** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment"}[$interval])) by ($groupby)
```

**Exemples** :
- Si `$groupby = endpoint` : `by (endpoint)`
- Si `$groupby = endpoint,status` : `by (endpoint, status)`
- Si `$groupby = transaction_type,channel` : `by (transaction_type, channel)`

---

## 🎯 PARTIE 8 : Dashboard Complet Multi-Niveau (30 min)

### Étape 8.1 : Organisation des Variables

**Ordre d'affichage** (de gauche à droite) :

1. **environment** (Level 1)
2. **region** (Level 2 - dépend de environment)
3. **instance** (Level 3 - dépend de environment + region)
4. **job** (Level 3 - dépend de environment)
5. **metric_type** (Level 4 - indépendant)
6. **endpoint** (Level 5 - dépend de environment)
7. **interval** (Technique)
8. **aggregation** (Technique)
9. **groupby** (Technique)

### Étape 8.2 : Créer les Rows Dynamiques

#### Row 1 : Overview

**Panels** :
- Total Requests (Stat)
- Active Sessions (Gauge)
- Error Rate (Gauge)
- Revenue (Stat)

**Requêtes utilisant toutes les variables** :
```promql
sum(rate(ebanking_api_requests_total{environment=~"$environment",instance=~"$instance"}[$interval]))
```

#### Row 2 : Detailed Metrics ($metric_type)

**Panel dynamique** qui change selon `$metric_type` :
- CPU si metric_type = CPU
- Memory si metric_type = Memory
- API si metric_type = API
- etc.

#### Row 3 : Performance Table

**Table avec filtres complets** :
```promql
sum(rate(ebanking_api_requests_total{
  environment=~"$environment",
  region=~"$region",
  instance=~"$instance",
  endpoint=~"$endpoint"
}[$interval])) by ($groupby)
```

---

## 🧪 PARTIE 9 : Tests et Validation (20 min)

### Test 9.1 : Cascade de Filtres

1. **Sélectionner** `Environment: production`
2. **Observer** : Les régions se mettent à jour
3. **Sélectionner** `Region: eu-west-1`
4. **Observer** : Les instances se mettent à jour
5. **Sélectionner** `Instance: node-exporter:9100`
6. **Observer** : Tous les panels se mettent à jour

### Test 9.2 : Multi-Sélection

1. **Sélectionner** `Environment: production, staging` (multi)
2. **Observer** : Les données des 2 environnements s'affichent
3. **Sélectionner** `Endpoint: /api/v1/transfer, /api/v1/balance`
4. **Observer** : Seulement ces 2 endpoints s'affichent

### Test 9.3 : Variables Techniques

1. **Changer** `Interval: 1m` → `1h`
2. **Observer** : Les graphiques s'adaptent
3. **Changer** `Aggregation: sum` → `avg`
4. **Observer** : Les valeurs changent
5. **Changer** `Group By: endpoint` → `transaction_type`
6. **Observer** : Le grouping change

### Test 9.4 : Performance

**Checklist** :
- [ ] Les variables se chargent en < 2 secondes
- [ ] Les panels se mettent à jour en < 3 secondes
- [ ] Pas d'erreurs dans les requêtes
- [ ] Les dépendances fonctionnent correctement

---

## 📊 PARTIE 10 : Cas d'Usage Avancés (30 min)

### Cas 10.1 : Dashboard Multi-Tenant

**Objectif** : Un dashboard pour plusieurs clients

**Variables** :
```
$tenant → $application → $environment → $region
```

**Requête** :
```promql
sum(rate(requests_total{
  tenant=~"$tenant",
  application=~"$application",
  environment=~"$environment",
  region=~"$region"
}[$interval])) by ($groupby)
```

### Cas 10.2 : Dashboard Comparatif

**Objectif** : Comparer 2 environnements côte à côte

**Variables** :
```
$environment_a (production)
$environment_b (staging)
```

**Requêtes** :
```promql
# Panel A
sum(rate(metric{environment="$environment_a"}[$interval]))

# Panel B
sum(rate(metric{environment="$environment_b"}[$interval]))
```

### Cas 10.3 : Dashboard avec Calculs Dynamiques

**Variable** :
```
Name: percentile
Type: Custom
Values: 0.50,0.90,0.95,0.99
```

**Requête** :
```promql
histogram_quantile($percentile, 
  sum(rate(duration_bucket{environment=~"$environment"}[$interval])) by (le)
)
```

**Titre** :
```
P$percentile Latency - $environment
```

---

## 🎓 Bonnes Pratiques

### 1. Nommage des Variables

✅ **Bon** :
```
$environment
$region
$instance
$metric_type
```

❌ **Mauvais** :
```
$env
$r
$i
$type
```

### 2. Ordre des Variables

**Principe** : Du général au spécifique

```
1. Environment (global)
2. Region (géographique)
3. Instance (serveur)
4. Metric (détail)
```

### 3. Multi-Value vs Single-Value

**Multi-value** : Pour filtres multiples
```
$endpoint (multi) → /api/v1/*, /api/v2/*
```

**Single-value** : Pour sélection unique
```
$metric_type (single) → CPU ou Memory (pas les deux)
```

### 4. Performance

**Optimisations** :
- Utiliser `label_values()` au lieu de requêtes complexes
- Limiter le nombre de variables (max 10)
- Utiliser `Refresh: On Dashboard Load` pour variables statiques
- Éviter les variables dépendantes en cascade > 3 niveaux

### 5. Documentation

**Toujours ajouter** :
- **Label** : Nom affiché
- **Description** : Explication de la variable
- **Tooltip** : Aide contextuelle

---

## 🔧 Troubleshooting

### Problème 1 : Variable Vide

**Symptôme** : La variable ne retourne aucune valeur

**Solutions** :
```bash
# Vérifier la requête dans Prometheus
http://localhost:9090/graph

# Tester la requête
label_values(ebanking_app_info, environment)

# Vérifier que la métrique existe
ebanking_app_info
```

### Problème 2 : Dépendance ne Fonctionne Pas

**Symptôme** : La variable enfant ne se met pas à jour

**Solutions** :
1. **Vérifier** l'ordre des variables (parent avant enfant)
2. **Vérifier** la syntaxe : `{parent=~"$parent"}`
3. **Activer** `Refresh: On Time Range Change`

### Problème 3 : Performance Lente

**Symptôme** : Les variables mettent > 5 secondes à charger

**Solutions** :
1. **Simplifier** les requêtes
2. **Utiliser** `label_values()` au lieu de `query_result()`
3. **Limiter** le time range
4. **Désactiver** `Refresh: On Dashboard Load` si non nécessaire

---

## 📚 Exemples de Requêtes avec Variables

### Exemple 1 : Filtrage Simple

```promql
# Métrique filtrée par environnement
ebanking_active_sessions{environment=~"$environment"}
```

### Exemple 2 : Filtrage Multi-Niveau

```promql
# Métrique filtrée par 3 variables
sum(rate(ebanking_api_requests_total{
  environment=~"$environment",
  region=~"$region",
  endpoint=~"$endpoint"
}[$interval])) by (endpoint)
```

### Exemple 3 : Regex Avancé

```promql
# Filtrage avec regex
sum(rate(ebanking_api_requests_total{
  endpoint=~"$endpoint",
  status_code=~"$status_code"
}[$interval])) by (endpoint, status_code)
```

### Exemple 4 : Calcul Conditionnel

```promql
# Si $metric_type = "error_rate"
(
  sum(rate(requests_total{status=~"5.."}[$interval]))
  /
  sum(rate(requests_total[$interval]))
) * 100

# Si $metric_type = "success_rate"
(
  sum(rate(requests_total{status=~"2.."}[$interval]))
  /
  sum(rate(requests_total[$interval]))
) * 100
```

### Exemple 5 : Agrégation Dynamique

```promql
# $aggregation peut être sum, avg, min, max
$aggregation(rate(ebanking_transactions_processed_total{
  environment=~"$environment"
}[$interval])) by ($groupby)
```

---

## ✅ Checklist de Validation Finale

### Variables de Base

- [ ] Variable `$environment` créée et fonctionnelle
- [ ] Variable `$region` dépend de `$environment`
- [ ] Variable `$instance` dépend de `$environment` et `$region`
- [ ] Variable `$job` créée
- [ ] Variable `$metric_type` créée

### Variables Avancées

- [ ] Variable `$endpoint` créée
- [ ] Variable `$interval` créée (auto)
- [ ] Variable `$aggregation` créée
- [ ] Variable `$groupby` créée (multi-value)

### Panels

- [ ] Panel dynamique selon `$metric_type`
- [ ] Table avec transformations et variables
- [ ] Gauge avec thresholds variables
- [ ] Titres utilisent les variables

### Tests

- [ ] Cascade de filtres fonctionne
- [ ] Multi-sélection fonctionne
- [ ] Variables techniques fonctionnent
- [ ] Performance acceptable (< 3s)

### Documentation

- [ ] Toutes les variables ont un Label
- [ ] Toutes les variables ont une Description
- [ ] Dashboard sauvegardé avec un nom explicite

---

## 🎯 Résumé des Compétences Acquises

### Niveau 1 : Variables de Base

✅ Créer des variables Query  
✅ Utiliser `label_values()`  
✅ Configurer Multi-value et All  
✅ Utiliser des variables dans les requêtes  

### Niveau 2 : Variables Dépendantes

✅ Créer des dépendances entre variables  
✅ Implémenter des filtres en cascade  
✅ Gérer l'ordre des variables  
✅ Optimiser les refresh  

### Niveau 3 : Variables Avancées

✅ Variables Interval dynamiques  
✅ Variables Custom pour options  
✅ Variables Constant pour configuration  
✅ Agrégation et grouping dynamiques  

### Niveau 4 : Dashboards Dynamiques

✅ Panels conditionnels selon variables  
✅ Titres dynamiques avec variables  
✅ Thresholds variables  
✅ Requêtes composées avec variables  

---

## 📖 Ressources Complémentaires

### Documentation Officielle

- [Grafana Variables](https://grafana.com/docs/grafana/latest/dashboards/variables/)
- [Variable Syntax](https://grafana.com/docs/grafana/latest/dashboards/variables/variable-syntax/)
- [PromQL Label Matching](https://prometheus.io/docs/prometheus/latest/querying/basics/#instant-vector-selectors)

### Exemples de Dashboards

- [Node Exporter Full](https://grafana.com/grafana/dashboards/1860) - Variables multi-niveau
- [Kubernetes Cluster](https://grafana.com/grafana/dashboards/7249) - Cascade complexe

### Tutoriels Vidéo

- [Grafana Variables Tutorial](https://www.youtube.com/watch?v=...)
- [Advanced Templating](https://www.youtube.com/watch?v=...)

---

## 🎉 Félicitations !

Vous maîtrisez maintenant :

- ✅ **Variables multi-niveau** (5 niveaux)
- ✅ **Dépendances en cascade**
- ✅ **Filtrage dynamique**
- ✅ **Dashboards réutilisables**
- ✅ **Performance optimisée**
- ✅ **Cas d'usage avancés**

**Temps total** : 2h30  
**Niveau atteint** : Expert Variables & Templates 🏆

---

## 🔙 Navigation

- [⬅️ Lab 2.6 - Dashboard Construction Avancée](../Lab-2.6-Dashboard-Construction-Avance/)
- [➡️ Lab 3.1 - Performance Optimization](../../Day%203/Lab-3.1-Performance/)
- [🏠 Accueil Formation](../../README-MAIN.md)
