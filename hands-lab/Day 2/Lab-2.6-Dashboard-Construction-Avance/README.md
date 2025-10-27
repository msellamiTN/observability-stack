# 🎨 Lab 2.6 : Construction Avancée de Dashboard - Étape par Étape

**Durée estimée** : 4 heures  
**Niveau** : Avancé  
**Objectif** : Reconstruire le dashboard "eBanking Professional Observability" via l'interface Grafana

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Créer un dashboard professionnel multi-niveaux
- ✅ Configurer des panels avec transformations complexes
- ✅ Utiliser des agrégations et requêtes composées
- ✅ Implémenter des corrélations entre métriques
- ✅ Configurer des overrides et thresholds avancés
- ✅ Créer des tables avec transformations multiples

---

## 📋 Prérequis

### Services Requis

```bash
# Vérifier que les services sont actifs
docker ps | grep -E "grafana|prometheus|ebanking"

# Générer des données de test
cd payment-api-instrumented
./test-observability.ps1
```

### Accès Grafana

```
URL: http://localhost:3000
User: admin
Password: GrafanaSecure123!Change@Me
```

---

## 🏗️ Structure du Dashboard

Le dashboard est organisé en **4 niveaux** :

1. **🎯 Executive Summary** - KPIs décisionnels (4 panels)
2. **🔍 Advanced Analytics** - Corrélations avancées (4 panels)
3. **🎓 Training & Learning** - Guide pédagogique (1 panel)
4. **Variables** - Filtres dynamiques

---

## 📝 PARTIE 1 : Création du Dashboard (10 min)

### Étape 1.1 : Créer un Nouveau Dashboard

1. **Accéder à Grafana** : `http://localhost:3000`
2. **Menu** → **Dashboards** → **New** → **New Dashboard**
3. **Cliquer** sur l'icône ⚙️ (Settings) en haut à droite

### Étape 1.2 : Configuration Générale

Dans l'onglet **General** :

```
Name: eBanking Professional Observability Dashboard - Data2AI Academy V2
Description: Dashboard professionnel pour monitoring eBanking avec corrélations avancées
Tags: ebanking, observability, training
Folder: Default
```

### Étape 1.3 : Configuration des Annotations

Dans l'onglet **Annotations** :

**Annotation 1 : Deployment Events**

1. **Cliquer** sur **Add annotation query**
2. **Configuration** :
   ```
   Name: Deployment Events
   Data source: Prometheus
   Query: changes(ebanking_app_info{environment=~"$environment"}[5m]) > 0
   Icon color: green
   Tag keys: version
   Title format: Deployment
   ```

### Étape 1.4 : Configuration des Variables

Dans l'onglet **Variables** :

**Variable : environment**

1. **Cliquer** sur **Add variable**
2. **Configuration** :
   ```
   Name: environment
   Type: Query
   Data source: Prometheus
   Query: label_values(ebanking_app_info, environment)
   Regex: .*
   Multi-value: Yes
   Include All option: Yes
   ```

3. **Cliquer** sur **Apply** puis **Save dashboard**

---

## 🎨 PARTIE 2 : Row 1 - Executive Summary (60 min)

### Panel 2.1 : 📊 Daily Revenue (Gauge)

#### Étape 2.1.1 : Créer le Panel

1. **Retour au dashboard** → **Add** → **Visualization**
2. **Sélectionner** : **Gauge**

#### Étape 2.1.2 : Configuration de la Requête

**Query A** :
```promql
ebanking_daily_revenue_eur{environment=~"$environment"}
```

**Configuration** :
- Legend: (vide)
- Format: Time series

#### Étape 2.1.3 : Configuration du Panel

**Panel options** :
```
Title: 📊 Daily Revenue (EUR)
Description: Revenu quotidien en temps réel
```

**Standard options** :
```
Unit: Currency → Euro (€)
Min: (auto)
Max: (auto)
Decimals: 0
```

**Thresholds** :
```
Mode: Absolute
Steps:
  - 0: Red
  - 50000: Orange
  - 100000: Green
```

**Gauge options** :
```
Orientation: Auto
Show threshold labels: No
Show threshold markers: Yes
```

**Value options** :
```
Calculation: Last (not null)
```

#### Étape 2.1.4 : Positionnement

```
Position: Row 1, Column 1
Width: 6
Height: 6
```

**Cliquer** sur **Apply**

---

### Panel 2.2 : 😊 Customer Satisfaction Score (Gauge)

#### Étape 2.2.1 : Créer le Panel

1. **Add** → **Visualization** → **Gauge**

#### Étape 2.2.2 : Configuration de la Requête

**Query A** :
```promql
ebanking_customer_satisfaction_score{environment=~"$environment"}
```

#### Étape 2.2.3 : Configuration du Panel

**Panel options** :
```
Title: 😊 Customer Satisfaction Score
Description: Score de satisfaction client (0-100)
```

**Standard options** :
```
Unit: Percent (0-100)
Min: 0
Max: 100
Decimals: 1
```

**Thresholds** :
```
Mode: Absolute
Steps:
  - 0: Red
  - 80: Orange
  - 90: Green
```

#### Étape 2.2.4 : Positionnement

```
Position: Row 1, Column 2
Width: 6
Height: 6
X: 6
Y: 1
```

**Cliquer** sur **Apply**

---

### Panel 2.3 : 👥 Active User Sessions Trend (Time Series)

#### Étape 2.3.1 : Créer le Panel

1. **Add** → **Visualization** → **Time series**

#### Étape 2.3.2 : Configuration de la Requête

**Query A** :
```promql
ebanking_active_sessions{environment=~"$environment"}
```

**Legend** :
```
Legend: Active Sessions
```

#### Étape 2.3.3 : Configuration du Panel

**Panel options** :
```
Title: 👥 Active User Sessions Trend
Description: Évolution des sessions utilisateurs actives
```

**Graph styles** :
```
Style: Line
Line interpolation: Smooth
Line width: 2
Fill opacity: 20%
Gradient mode: None
Show points: Never
```

**Legend** :
```
Visibility: Yes
Mode: Table
Placement: Bottom
Values: Mean, Max, Last
```

**Tooltip** :
```
Mode: All
Sort: None
```

#### Étape 2.3.4 : Positionnement

```
Position: Row 1, Column 3-4
Width: 12
Height: 8
X: 12
Y: 1
```

**Cliquer** sur **Apply**

---

## 🔍 PARTIE 3 : Row 2 - Advanced Analytics (90 min)

### Créer une Nouvelle Row

1. **Add** → **Row**
2. **Title** : `🔍 Advanced Analytics & Correlations (Niveau Avancé)`
3. **Cliquer** sur la row pour la fermer/ouvrir

---

### Panel 3.1 : 📈 Business Impact Correlation (Dual Axis)

#### Étape 3.1.1 : Créer le Panel

1. **Add** → **Visualization** → **Time series**

#### Étape 3.1.2 : Configuration des Requêtes

**Query A - Error Rate** :
```promql
(
  sum(rate(ebanking_api_requests_total{environment=~"$environment",status_code=~"5.."}[5m])) 
  / 
  sum(rate(ebanking_api_requests_total{environment=~"$environment"}[5m]))
) * 100
```

**Legend** :
```
Legend: Error Rate
```

**Query B - Revenue** :
```promql
ebanking_daily_revenue_eur{environment=~"$environment"}
```

**Legend** :
```
Legend: Revenue
```

#### Étape 3.1.3 : Configuration du Panel

**Panel options** :
```
Title: 📈 Business Impact Correlation: Error Rate vs Revenue
Description: Corrélation entre taux d'erreur et revenu
```

**Standard options (Query A - Error Rate)** :
```
Unit: Percent (0-100)
Color: Red
```

**Thresholds (Query A)** :
```
Mode: Absolute
Steps:
  - 0: Green
  - 2: Yellow
  - 5: Red
```

#### Étape 3.1.4 : Configuration des Overrides (IMPORTANT)

**Override 1 : Revenue (Query B)**

1. **Field overrides** → **Add field override**
2. **Fields with name** : `Revenue`
3. **Add override property** :

```
Axis placement: Right
Axis label: Revenue (EUR)
Unit: Currency → Euro (€)
Color: Fixed color → Green
Line width: 2
Fill opacity: 0
```

**Override 2 : Error Rate (Query A)**

1. **Add field override**
2. **Fields with name** : `Error Rate`
3. **Add override property** :

```
Axis placement: Left
Axis label: Error Rate %
Unit: Percent (0-100)
Color: Fixed color → Red
Line width: 2
Thresholds style: Line
```

#### Étape 3.1.5 : Positionnement

```
Width: 12
Height: 8
X: 0
Y: 10
```

**Cliquer** sur **Apply**

---

### Panel 3.2 : ⏱️ User Session Duration Analysis (Bar Chart)

#### Étape 3.2.1 : Créer le Panel

1. **Add** → **Visualization** → **Bar chart**

#### Étape 3.2.2 : Configuration de la Requête

**Query A** :
```promql
sum(rate(ebanking_session_duration_seconds_bucket{environment=~"$environment"}[5m])) by (le)
```

**Legend** :
```
Legend: {{le}}s
```

#### Étape 3.2.3 : Configuration du Panel

**Panel options** :
```
Title: ⏱️ User Session Duration Analysis
Description: Distribution des durées de session
```

**Bar chart options** :
```
Orientation: Horizontal
X axis: Time
Bar alignment: Center
Bar width factor: 0.8
Group width: 0.7
```

**Standard options** :
```
Unit: Seconds (s)
Color scheme: Green-Yellow-Red (by value)
```

**Legend** :
```
Visibility: Yes
Mode: List
Placement: Right
```

#### Étape 3.2.4 : Positionnement

```
Width: 12
Height: 8
X: 12
Y: 10
```

**Cliquer** sur **Apply**

---

### Panel 3.3 : 📊 Transaction Status Distribution (Stacked Time Series)

#### Étape 3.3.1 : Créer le Panel

1. **Add** → **Visualization** → **Time series**

#### Étape 3.3.2 : Configuration des Requêtes

**Query A - Success** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment",status="success"}[5m]))
```

**Legend** : `Success`

**Query B - Failed** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment",status="failed"}[5m]))
```

**Legend** : `Failed`

**Query C - Pending** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment",status="pending"}[5m]))
```

**Legend** : `Pending`

**Query D - Cancelled** :
```promql
sum(rate(ebanking_transactions_processed_total{environment=~"$environment",status="cancelled"}[5m]))
```

**Legend** : `Cancelled`

#### Étape 3.3.3 : Configuration du Panel

**Panel options** :
```
Title: 📊 Transaction Status Distribution Over Time
Description: Répartition des transactions par statut
```

**Graph styles** :
```
Style: Line
Line interpolation: Smooth
Line width: 1
Fill opacity: 50%
Gradient mode: Opacity
Stack: Normal (stacked)
```

**Standard options** :
```
Unit: ops (operations per second)
```

**Color scheme** :
```
Success: Green
Failed: Red
Pending: Orange
Cancelled: Gray
```

#### Étape 3.3.4 : Configuration des Overrides

**Override pour chaque Query** :

1. **Success** → Color: Green
2. **Failed** → Color: Red
3. **Pending** → Color: Orange
4. **Cancelled** → Color: Gray

#### Étape 3.3.5 : Positionnement

```
Width: 24
Height: 8
X: 0
Y: 18
```

**Cliquer** sur **Apply**

---

## 🎯 PARTIE 4 : Panel Avancé avec Transformations (60 min)

### Panel 4.1 : 🎯 API Endpoint Performance Summary (Table avec Transformations)

Ce panel est le **plus complexe** du dashboard. Il combine **3 requêtes** et utilise **2 transformations**.

#### Étape 4.1.1 : Créer le Panel

1. **Add** → **Visualization** → **Table**

#### Étape 4.1.2 : Configuration des Requêtes

**Query A - Requests per Second** :
```promql
sum(rate(ebanking_api_requests_total{environment=~"$environment"}[5m])) by (endpoint)
```

**Configuration** :
- Format: **Table**
- Instant: **Yes** (cocher)
- Legend: (vide)

**Query B - P95 Latency** :
```promql
histogram_quantile(0.95, 
  sum(rate(ebanking_request_duration_seconds_bucket{environment=~"$environment"}[5m])) 
  by (le, endpoint)
) * 1000
```

**Configuration** :
- Format: **Table**
- Instant: **Yes** (cocher)
- Legend: (vide)

**Query C - Error Rate** :
```promql
(
  sum(rate(ebanking_api_requests_total{environment=~"$environment",status_code=~"5.."}[5m])) 
  by (endpoint) 
  / 
  sum(rate(ebanking_api_requests_total{environment=~"$environment"}[5m])) 
  by (endpoint)
) * 100
```

**Configuration** :
- Format: **Table**
- Instant: **Yes** (cocher)
- Legend: (vide)

#### Étape 4.1.3 : Configuration des Transformations (CRUCIAL)

**Transformation 1 : Merge**

1. **Onglet Transform** → **Add transformation**
2. **Sélectionner** : **Merge**
3. **Options** : (laisser par défaut)

Cette transformation fusionne les 3 tables en une seule.

**Transformation 2 : Organize fields**

1. **Add transformation**
2. **Sélectionner** : **Organize fields**
3. **Configuration** :

**Exclude by name** :
```
Time: ✓ (cocher pour cacher)
```

**Rename by name** :
```
endpoint → Endpoint
Value #A → Requests/sec
Value #B → P95 Latency (ms)
Value #C → Error Rate %
```

**Index by name** (ordre des colonnes) :
```
0: endpoint (Endpoint)
1: Value #A (Requests/sec)
2: Value #B (P95 Latency (ms))
3: Value #C (Error Rate %)
```

#### Étape 4.1.4 : Configuration du Panel

**Panel options** :
```
Title: 🎯 API Endpoint Performance Summary (SLO Dashboard)
Description: Vue consolidée des performances par endpoint
```

**Table options** :
```
Show header: Yes
Cell height: Small
Sort by: Requests/sec (descending)
```

#### Étape 4.1.5 : Configuration des Overrides (Coloration)

**Override 1 : P95 Latency (ms)**

1. **Field overrides** → **Add field override**
2. **Fields with name** : `P95 Latency (ms)`
3. **Add override property** :

```
Cell display mode: Color background
Unit: milliseconds (ms)
Thresholds:
  - 0: Green
  - 200: Yellow
  - 500: Orange
  - 1000: Red
```

**Override 2 : Error Rate %**

1. **Add field override**
2. **Fields with name** : `Error Rate %`
3. **Add override property** :

```
Cell display mode: Color background
Unit: Percent (0-100)
Decimals: 2
Thresholds:
  - 0: Green
  - 1: Yellow
  - 5: Red
```

**Override 3 : Requests/sec**

1. **Add field override**
2. **Fields with name** : `Requests/sec`
3. **Add override property** :

```
Unit: ops (operations per second)
Decimals: 2
```

#### Étape 4.1.6 : Positionnement

```
Width: 24
Height: 10
X: 0
Y: 27
```

**Cliquer** sur **Apply**

---

## 🎓 PARTIE 5 : Panel Pédagogique (15 min)

### Panel 5.1 : 📖 PromQL Learning Guide

#### Étape 5.1.1 : Créer le Panel

1. **Add** → **Visualization** → **Text**

#### Étape 5.1.2 : Configuration du Contenu

**Mode** : Markdown

**Contenu** :

```markdown
# 📖 PromQL Learning Guide & Examples

## 🎯 Requêtes Utilisées dans ce Dashboard

### 1️⃣ Taux de Requêtes (Rate)
```promql
sum(rate(ebanking_api_requests_total[5m])) by (endpoint)
```
**Explication** : Calcule le nombre de requêtes par seconde sur 5 minutes, groupé par endpoint.

### 2️⃣ Percentile 95 (Latence)
```promql
histogram_quantile(0.95, 
  sum(rate(ebanking_request_duration_seconds_bucket[5m])) by (le, endpoint)
) * 1000
```
**Explication** : Calcule le 95ème percentile de latence (95% des requêtes sont plus rapides).

### 3️⃣ Taux d'Erreur
```promql
(
  sum(rate(ebanking_api_requests_total{status_code=~"5.."}[5m])) 
  / 
  sum(rate(ebanking_api_requests_total[5m]))
) * 100
```
**Explication** : Pourcentage de requêtes en erreur (5xx) sur le total.

### 4️⃣ Corrélation Multi-Métriques
Utilise **dual axis** pour comparer Error Rate (left) vs Revenue (right).

## 🔧 Transformations Avancées

### Merge
Fusionne plusieurs requêtes en une seule table.

### Organize Fields
- Renomme les colonnes
- Réordonne les colonnes
- Cache des colonnes

## 💡 Bonnes Pratiques

1. **Toujours utiliser `rate()` pour les counters**
2. **Grouper avec `by (label)`** pour segmenter
3. **Utiliser `histogram_quantile()` pour les percentiles**
4. **Instant queries** pour les tables (cocher "Instant")
5. **Overrides** pour la coloration conditionnelle

## 📚 Ressources

- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Transformations](https://grafana.com/docs/grafana/latest/panels/transformations/)
```

#### Étape 5.1.3 : Configuration du Panel

**Panel options** :
```
Title: 📖 PromQL Learning Guide & Examples
Description: Guide pédagogique des requêtes utilisées
```

#### Étape 5.1.4 : Positionnement

```
Width: 24
Height: 12
X: 0
Y: 38
```

**Cliquer** sur **Apply**

---

## ✅ PARTIE 6 : Finalisation et Sauvegarde (10 min)

### Étape 6.1 : Vérification Globale

1. **Vérifier** que tous les panels s'affichent correctement
2. **Tester** le filtre `$environment`
3. **Vérifier** les annotations de déploiement

### Étape 6.2 : Configuration Finale

1. **Cliquer** sur l'icône ⚙️ (Settings)
2. **Onglet General** :

```
Timezone: Browser
Refresh: 30s
Time options: Last 6 hours
Refresh intervals: 5s, 10s, 30s, 1m, 5m, 15m, 30m, 1h
Graph tooltip: Shared crosshair
```

### Étape 6.3 : Sauvegarde

1. **Cliquer** sur l'icône 💾 (Save dashboard)
2. **Save changes** :

```
Title: eBanking Professional Observability Dashboard - Data2AI Academy V2
Folder: Default
Description: Dashboard professionnel avec corrélations avancées et transformations
```

3. **Cliquer** sur **Save**

---

## 🧪 PARTIE 7 : Tests et Validation (20 min)

### Test 1 : Génération de Données

```bash
# Générer du trafic
cd payment-api-instrumented
./test-observability.ps1
```

### Test 2 : Vérification des Panels

**Checklist** :

- [ ] Panel Revenue affiche une valeur > 0
- [ ] Panel Satisfaction affiche un score 80-100
- [ ] Panel Sessions affiche une courbe
- [ ] Panel Correlation affiche 2 axes (gauche/droite)
- [ ] Panel Session Duration affiche des barres
- [ ] Panel Transaction Status affiche un graphique empilé
- [ ] Table Performance affiche des endpoints avec couleurs
- [ ] Panel Learning Guide affiche le markdown

### Test 3 : Vérification des Transformations

**Table Performance** :

1. **Vérifier** que les 3 colonnes sont présentes :
   - Requests/sec
   - P95 Latency (ms)
   - Error Rate %

2. **Vérifier** les couleurs :
   - Latence < 200ms : Vert
   - Latence > 500ms : Orange/Rouge
   - Error Rate < 1% : Vert
   - Error Rate > 5% : Rouge

### Test 4 : Vérification des Variables

1. **Sélectionner** différentes valeurs pour `$environment`
2. **Vérifier** que tous les panels se mettent à jour

---

## 📊 Résumé des Techniques Avancées Utilisées

### 1. Requêtes Composées

```promql
# Division de métriques
(numerator / denominator) * 100

# Agrégation multi-labels
sum(rate(metric[5m])) by (label1, label2)

# Percentiles
histogram_quantile(0.95, sum(rate(bucket[5m])) by (le))
```

### 2. Transformations

| Transformation | Usage | Exemple |
|----------------|-------|---------|
| **Merge** | Fusionner plusieurs queries | 3 queries → 1 table |
| **Organize** | Renommer/réordonner colonnes | Value #A → Requests/sec |
| **Filter** | Filtrer lignes | Garder seulement errors > 0 |
| **Join** | Joindre sur un label | Combiner metrics + logs |

### 3. Overrides

| Override | Propriété | Usage |
|----------|-----------|-------|
| **Axis placement** | Left/Right | Dual axis |
| **Color** | Fixed/Thresholds | Coloration conditionnelle |
| **Unit** | ms, %, EUR | Formatage |
| **Cell display** | Color background | Tables colorées |

### 4. Options Avancées

- **Instant queries** : Pour tables (snapshot)
- **Stacking** : Graphiques empilés
- **Legend calculations** : Mean, Max, Last
- **Thresholds style** : Line, Area, Dashed

---

## 🎓 Points Clés à Retenir

### Requêtes PromQL

1. ✅ **`rate()`** pour les counters (toujours !)
2. ✅ **`histogram_quantile()`** pour les percentiles
3. ✅ **`by (label)`** pour grouper
4. ✅ **`* 100`** pour convertir en pourcentage
5. ✅ **`* 1000`** pour convertir secondes → millisecondes

### Transformations

1. ✅ **Merge** : Fusionner queries en table
2. ✅ **Organize** : Renommer et réordonner
3. ✅ **Ordre important** : Merge AVANT Organize

### Overrides

1. ✅ **By name** : Cibler une colonne/série spécifique
2. ✅ **Thresholds** : Définir les seuils de couleur
3. ✅ **Cell display** : Color background pour tables

### Bonnes Pratiques

1. ✅ Toujours tester avec des données réelles
2. ✅ Utiliser des emojis pour la lisibilité
3. ✅ Documenter les requêtes complexes
4. ✅ Organiser en rows thématiques
5. ✅ Utiliser des variables pour la flexibilité

---

## 📚 Ressources Complémentaires

### Documentation Officielle

- [Grafana Panels](https://grafana.com/docs/grafana/latest/panels/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Transformations](https://grafana.com/docs/grafana/latest/panels/transformations/)
- [Field Overrides](https://grafana.com/docs/grafana/latest/panels/configure-overrides/)

### Exemples de Requêtes

```promql
# RED Method (Rate, Errors, Duration)
rate(requests_total[5m])
rate(requests_total{status=~"5.."}[5m]) / rate(requests_total[5m])
histogram_quantile(0.95, rate(duration_bucket[5m]))

# USE Method (Utilization, Saturation, Errors)
100 - (avg(rate(cpu_idle[5m])) * 100)
node_load1 / count(node_cpu_seconds_total{mode="idle"})
rate(errors_total[5m])
```

---

## ✅ Checklist de Validation Finale

### Configuration Dashboard

- [ ] Titre et description configurés
- [ ] Tags ajoutés (ebanking, observability)
- [ ] Variables créées ($environment)
- [ ] Annotations configurées (Deployment Events)
- [ ] Time range configuré (Last 6 hours)
- [ ] Refresh interval configuré (30s)

### Panels Executive Summary

- [ ] Panel Revenue (Gauge) avec thresholds
- [ ] Panel Satisfaction (Gauge) avec thresholds
- [ ] Panel Sessions (Time series) avec legend

### Panels Advanced Analytics

- [ ] Panel Correlation (Dual axis) avec overrides
- [ ] Panel Session Duration (Bar chart)
- [ ] Panel Transaction Status (Stacked)
- [ ] Table Performance avec 3 queries + transformations

### Panels Learning

- [ ] Panel Learning Guide (Text/Markdown)

### Tests

- [ ] Toutes les requêtes retournent des données
- [ ] Les transformations fonctionnent
- [ ] Les overrides colorent correctement
- [ ] Les variables filtrent correctement
- [ ] Dashboard sauvegardé

---

## 🎉 Félicitations !

Vous avez créé un **dashboard professionnel de niveau production** avec :

- ✅ 8 panels avancés
- ✅ Requêtes PromQL complexes
- ✅ Transformations multiples
- ✅ Overrides conditionnels
- ✅ Corrélations multi-métriques
- ✅ Documentation intégrée

**Temps total** : ~4 heures  
**Niveau atteint** : Expert Grafana 🏆

---

## 🔙 Navigation

- [⬅️ Lab 2.5 - EBanking Monitoring](../Lab-2.5-EBanking-Monitoring/)
- [➡️ Lab 3.1 - Performance Optimization](../../Day%203/Lab-3.1-Performance/)
- [🏠 Accueil Formation](../../README-MAIN.md)
