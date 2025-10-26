# 📊 Lab 1.6 : Premier Dashboard Multi-Sources

**⏱️ Durée** : 1h30 | **👤 Niveau** : Débutant | **💻 Type** : Pratique

---

## 🎯 Objectifs

À la fin de ce lab, vous serez capable de :

✅ Créer un dashboard complet combinant plusieurs datasources  
✅ Utiliser des variables de dashboard pour la dynamique  
✅ Configurer des liens entre panels (drill-down)  
✅ Organiser et structurer un dashboard professionnel  
✅ Appliquer les bonnes pratiques de visualisation  
✅ Exporter et partager un dashboard  

---

## 🛠️ Prérequis

- ✅ Labs 1.3, 1.4, 1.5 complétés
- ✅ Toutes les datasources configurées
- ✅ Données de test disponibles

---

## 📚 Introduction

### Pourquoi un Dashboard Multi-Sources ?

Un dashboard efficace combine différentes sources de données pour donner une vue complète :

```
┌─────────────────────────────────────────────────────────────┐
│           DASHBOARD E-BANKING MULTI-SOURCES                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  📈 PROMETHEUS (Infrastructure)                              │
│  ├─ CPU Usage                                                │
│  ├─ Memory Usage                                             │
│  └─ HTTP Requests Rate                                       │
│                                                               │
│  🗄️ INFLUXDB (Time Series Metrics)                          │
│  ├─ Payment Volume                                           │
│  ├─ Transaction Latency                                      │
│  └─ Processing Time                                          │
│                                                               │
│  💾 MS SQL (Business Data)                                   │
│  ├─ Total Revenue                                            │
│  ├─ Success Rate                                             │
│  ├─ Top Customers                                            │
│  └─ Fraud Alerts                                             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Principes de Design

| Principe | Description |
|----------|-------------|
| **📊 Hiérarchie** | KPIs en haut, détails en bas |
| **🎨 Cohérence** | Couleurs et styles uniformes |
| **📏 Simplicité** | Pas plus de 12 panels par dashboard |
| **⚡ Performance** | Optimiser les requêtes |
| **🔗 Navigation** | Liens entre dashboards |

---

## 🎨 Étape 1 : Créer le Dashboard

### 1.1 Nouveau Dashboard

1. Grafana → **Dashboards** → **New** → **New Dashboard**
2. Cliquer sur **Dashboard settings** (⚙️ en haut à droite)
3. Configurer :

```yaml
Title: E-Banking Observability
Description: Dashboard multi-sources pour monitoring E-Banking
Tags: ebanking, monitoring, multi-source
Timezone: Browser Time
Refresh: 30s
Time range: Last 6 hours
```

4. **Save** (💾)

---

## 📊 Étape 2 : Row 1 - KPIs Globaux

### 2.1 Panel : Total Transactions (MS SQL)

**Add visualization** → **MS SQL Server - E-Banking**

**Query** :
```sql
SELECT COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
```

**Configuration** :
- Title : "📊 Total Transactions"
- Visualization : **Stat**
- Value options :
  - Show : Calculate
  - Calculation : Last (not null)
- Standard options :
  - Unit : short
  - Decimals : 0
- Thresholds :
  - Base : Green
  - 100 : Yellow
  - 1000 : Green

### 2.2 Panel : Montant Total (MS SQL)

**Query** :
```sql
SELECT SUM(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
```

**Configuration** :
- Title : "💰 Montant Total"
- Visualization : **Stat**
- Unit : Currency → Euro (€)
- Decimals : 2
- Color : Value
- Graph mode : Area

### 2.3 Panel : Taux de Succès (MS SQL)

**Query** :
```sql
SELECT
  CAST(SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
```

**Configuration** :
- Title : "✅ Taux de Succès"
- Visualization : **Gauge**
- Unit : Percent (0-100)
- Min : 0, Max : 100
- Thresholds :
  - 0 : Red
  - 90 : Yellow
  - 95 : Green

### 2.4 Panel : Services UP (Prometheus)

**Query** :
```promql
count(up == 1)
```

**Configuration** :
- Title : "🟢 Services UP"
- Visualization : **Stat**
- Unit : short
- Color : Green

---

## 📈 Étape 3 : Row 2 - Infrastructure

### 3.1 Créer une Row

1. Cliquer **Add** → **Row**
2. Title : "🖥️ Infrastructure Monitoring"
3. Drag & drop pour organiser

### 3.2 Panel : CPU Usage (Prometheus)

**Query** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Configuration** :
- Title : "CPU Usage"
- Visualization : **Time series**
- Unit : Percent (0-100)
- Fill opacity : 10
- Line width : 2
- Thresholds :
  - 70 : Yellow
  - 90 : Red

### 3.3 Panel : Memory Usage (Prometheus)

**Query** :
```promql
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes) * 100
```

**Configuration** :
- Title : "Memory Usage"
- Visualization : **Time series**
- Unit : Percent (0-100)
- Color scheme : Green-Yellow-Red

### 3.4 Panel : HTTP Requests Rate (Prometheus)

**Query** :
```promql
sum(rate(http_requests_total[5m])) by (job)
```

**Configuration** :
- Title : "HTTP Requests/sec"
- Visualization : **Time series**
- Unit : reqps
- Legend : {{job}}
- Stack : Normal

---

## 💳 Étape 4 : Row 3 - Transactions

### 4.1 Panel : Volume par Heure (MS SQL)

**Query** :
```sql
SELECT
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0) AS time,
  COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```

**Configuration** :
- Title : "Transactions par Heure"
- Visualization : **Bar chart**
- Unit : short
- Orientation : Horizontal

### 4.2 Panel : Montant par Type (MS SQL)

**Query** :
```sql
SELECT
  TransactionDate AS time,
  SUM(Amount) AS value,
  TransactionType AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND Status = 'SUCCESS'
GROUP BY 
  DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0),
  TransactionType
ORDER BY time
```

**Configuration** :
- Title : "Montant par Type"
- Visualization : **Time series**
- Unit : Currency → Euro (€)
- Stack : Normal
- Legend : {{metric}}

### 4.3 Panel : Répartition par Type (MS SQL)

**Query** :
```sql
SELECT
  TransactionType AS metric,
  COUNT(*) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY TransactionType
```

**Configuration** :
- Title : "Répartition par Type"
- Visualization : **Pie chart**
- Legend : Values + Percent
- Pie type : Donut

---

## 🔧 Étape 5 : Variables de Dashboard

### 5.1 Ajouter une Variable : Interval

1. Dashboard settings → **Variables** → **Add variable**

```yaml
Name: interval
Type: Interval
Label: Interval
Values: 5m,10m,30m,1h,6h,12h,1d
Auto: true
```

### 5.2 Ajouter une Variable : Account

1. **Add variable**

```yaml
Name: account
Type: Query
Label: Account
Data source: MS SQL Server - E-Banking
Query:
  SELECT DISTINCT AccountID
  FROM Transactions
  ORDER BY AccountID
Multi-value: true
Include All: true
```

### 5.3 Utiliser les Variables

Modifier une requête pour utiliser `$account` :

```sql
SELECT
  TransactionDate AS time,
  SUM(Amount) AS value
FROM Transactions
WHERE $__timeFilter(TransactionDate)
  AND AccountID IN ($account)
GROUP BY DATEADD(HOUR, DATEDIFF(HOUR, 0, TransactionDate), 0)
ORDER BY time
```

---

## 🔗 Étape 6 : Drill-Down et Navigation

### 6.1 Ajouter un Lien sur un Panel

1. Panel → **Edit**
2. **Panel options** → **Links** → **Add link**

```yaml
Title: Voir détails compte
URL: /d/account-details?var-account=${__field.labels.account}
Open in new tab: false
```

### 6.2 Data Links

Sur un panel Time series :

1. **Overrides** → **Add field override**
2. **Fields with name** : value
3. **Add override property** → **Data links**

```yaml
Title: Détails transaction
URL: /d/transaction-details?var-time=${__value.time}
```

---

## 🎨 Étape 7 : Personnalisation Visuelle

### 7.1 Couleurs Cohérentes

**Thème de couleurs E-Banking** :
- 🟢 Success : #73BF69
- 🔴 Error : #F2495C
- 🟡 Warning : #FF9830
- 🔵 Info : #5794F2
- ⚪ Neutral : #B4B4B4

### 7.2 Annotations

1. Dashboard settings → **Annotations** → **Add annotation query**

```yaml
Name: Deployments
Data source: MS SQL Server
Query:
  SELECT
    DeploymentDate AS time,
    'Deployment' AS text,
    Version AS tags
  FROM Deployments
  WHERE $__timeFilter(DeploymentDate)
```

### 7.3 Organisation

**Structure recommandée** :
```
Row 1: KPIs (4 stats horizontaux)
Row 2: Infrastructure (3 time series)
Row 3: Transactions (2 time series + 1 pie)
Row 4: Top Lists (2 tables)
```

---

## 💾 Étape 8 : Export et Partage

### 8.1 Exporter le Dashboard

1. Dashboard settings → **JSON Model**
2. **Copy to clipboard** ou **Save to file**

### 8.2 Créer un Snapshot

1. **Share** (icône partage) → **Snapshot**
2. **Snapshot name** : E-Banking Dashboard - 2025-10-26
3. **Expire** : 7 days
4. **Publish to snapshots.raintank.io** : Off (local only)
5. **Local Snapshot**

### 8.3 Exporter en PDF (Enterprise)

```bash
# Via API (nécessite Grafana Image Renderer)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "http://localhost:3000/render/d-solo/DASHBOARD_UID/panel-1?width=1000&height=500" \
  -o panel.png
```

---

## 🎯 Exercice Final : Dashboard Complet

Créez un dashboard E-Banking complet avec :

### Checklist

- [ ] 4 KPIs en haut (Transactions, Montant, Taux succès, Services UP)
- [ ] Row Infrastructure avec 3 panels (CPU, RAM, HTTP)
- [ ] Row Transactions avec 3 panels (Volume, Montant, Répartition)
- [ ] 2 variables (interval, account)
- [ ] Annotations pour les déploiements
- [ ] Liens de drill-down
- [ ] Couleurs cohérentes
- [ ] Titre et description
- [ ] Tags appropriés

---

## 📚 Bonnes Pratiques

### ✅ À Faire

- **Hiérarchie claire** : KPIs → Tendances → Détails
- **Couleurs significatives** : Rouge = danger, Vert = OK
- **Titres explicites** : "CPU Usage (%)" pas juste "CPU"
- **Unités correctes** : €, %, req/s, etc.
- **Légendes utiles** : Afficher quand nécessaire
- **Refresh automatique** : 30s ou 1min
- **Variables** : Pour la flexibilité
- **Documentation** : Description du dashboard

### ❌ À Éviter

- **Trop de panels** : Max 12 par dashboard
- **Couleurs aléatoires** : Cohérence visuelle
- **Requêtes lentes** : Optimiser les queries
- **Pas de contexte** : Toujours expliquer
- **Échelles inadaptées** : Min/Max appropriés
- **Trop de détails** : Garder l'essentiel
- **Pas de variables** : Dashboard rigide

---

## 🐛 Troubleshooting

### Panel vide

```
1. Vérifier la datasource (icône en haut du panel)
2. Vérifier la période (Time range)
3. Exécuter la requête dans Query Inspector
4. Vérifier les données sources
```

### Variables ne fonctionnent pas

```
1. Vérifier la syntaxe : $variable ou ${variable}
2. Tester la query de la variable
3. Vérifier Multi-value et Include All
4. Refresh du dashboard
```

### Performance lente

```
1. Réduire le nombre de panels
2. Optimiser les requêtes (index, agrégation)
3. Augmenter l'intervalle de refresh
4. Utiliser des recording rules (Prometheus)
```

---

## ✅ Validation

- [ ] Dashboard créé avec titre et description
- [ ] Au moins 3 datasources utilisées
- [ ] KPIs en haut du dashboard
- [ ] Rows organisées logiquement
- [ ] Variables fonctionnelles
- [ ] Couleurs cohérentes
- [ ] Unités correctes
- [ ] Dashboard exporté en JSON
- [ ] Snapshot créé

---

## 🎯 Résumé du Jour 1

**Félicitations ! Vous avez terminé le Jour 1** 🎉

Vous avez appris à :
- ✅ Installer et configurer la stack Grafana
- ✅ Comprendre les fichiers de configuration
- ✅ Configurer InfluxDB, Prometheus et MS SQL
- ✅ Écrire des requêtes Flux, PromQL et SQL
- ✅ Créer un dashboard multi-sources professionnel

**Prochaine étape** : [Jour 2](../../Day%202/) - Logs, Traces et Observabilité Avancée

---

## 📚 Ressources

### Documentation
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [Dashboard Variables](https://grafana.com/docs/grafana/latest/dashboards/variables/)
- [Panel Links](https://grafana.com/docs/grafana/latest/panels/configure-data-links/)

### Templates

Dashboards communautaires :
- [Node Exporter Full](https://grafana.com/grafana/dashboards/1860)
- [Prometheus 2.0 Stats](https://grafana.com/grafana/dashboards/3662)
- [MS SQL Server](https://grafana.com/grafana/dashboards/14864)

---

**🎓 Bravo !** Vous êtes maintenant prêt pour le monitoring avancé !
