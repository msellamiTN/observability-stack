# 🎯 Plan d'Action: Adaptation au Programme 21h

## 📋 Résumé des Modifications Requises

### Modules à Créer (PRIORITÉ HAUTE)

| Module | Durée | Statut | Effort |
|--------|-------|--------|--------|
| **Day 2: Templates & Variables** | 4h | ❌ Manquant | 2 jours |
| **Day 3: Organisations & Users** | 2h | ❌ Manquant | 1 jour |
| **Day 2: Dashboards SLA/SLO/Perf** | 1h | ⚠️ Partiel | 1 jour |
| **Day 3: Best Practices Consolidé** | 1h | ⚠️ Partiel | 1 jour |

**Effort Total Estimé**: 5 jours de développement

---

## 📂 Nouvelle Structure Proposée

```
observability-stack/
├── hands-lab/                    # Formation COMPLÈTE (23h - actuelle)
│   ├── Day 1/                    # 8h - Fondamentaux + Datasources
│   ├── Day 2/                    # 8h - Logs, Traces, Observabilité Avancée
│   └── Day 3/                    # 7h - Production, HA, Optimisation
│
└── hands-lab-21h/                # Formation STANDARD (21h - programme demandé)
    ├── Day 1/                    # 7h - Fondamentaux Grafana
    │   ├── Lab-1.1-Introduction/
    │   ├── Lab-1.2-InfluxDB/
    │   ├── Lab-1.3-Prometheus/
    │   └── Lab-1.4-MSSQL/
    │
    ├── Day 2/                    # 7h - Dashboards & Templating
    │   ├── Lab-2.1-Dashboards/   🆕 À CRÉER
    │   └── Lab-2.2-Templates/    🆕 À CRÉER (CRITIQUE)
    │
    └── Day 3/                    # 7h - Organisation, Alerting, Best Practices
        ├── Lab-3.1-Organisations/ 🆕 À CRÉER (CRITIQUE)
        ├── Lab-3.2-Alerting/      ⚠️ Adapter existant
        └── Lab-3.3-BestPractices/ 🆕 À CRÉER
```

---

## 🆕 Contenu à Créer: Day 2 - Lab 2.2 Templates & Variables

### Objectif
Maîtriser le templating Grafana pour créer des dashboards dynamiques et réutilisables.

### Structure du Lab (4h)

```
Lab-2.2-Templates-Variables/
├── README.md                      # Guide principal
├── exercices/
│   ├── 01-variable-basics.md      # Types de variables
│   ├── 02-query-variables.md      # Variables depuis datasources
│   ├── 03-chained-variables.md    # Variables hiérarchiques
│   └── 04-advanced-usage.md       # Cas avancés
├── solutions/
│   ├── dashboard-single-var.json
│   ├── dashboard-multi-var.json
│   └── dashboard-complete.json
└── data/
    └── test-data.sh               # Génération données test
```

### Contenu Détaillé

#### Exercice 1: Types de Variables (1h)

**Variables à Créer**:

1. **Query Variable** (Prometheus)
```yaml
Name: region
Type: Query
Datasource: Prometheus
Query: label_values(up, region)
Refresh: On Dashboard Load
Multi-value: Yes
Include All: Yes
```

2. **Custom Variable**
```yaml
Name: environment
Type: Custom
Values: production,staging,development
Current: production
```

3. **Constant Variable**
```yaml
Name: cluster_name
Type: Constant
Value: oddo-ebanking-cluster
Hide: Variable
```

4. **Interval Variable**
```yaml
Name: interval
Type: Interval
Values: 1m,5m,15m,30m,1h
Auto: Yes
```

5. **Datasource Variable**
```yaml
Name: datasource
Type: Datasource
Datasource Type: Prometheus
Multi-value: No
```

**TP Pratique**:
```
1. Créer les 5 variables ci-dessus
2. Créer un panel utilisant $region et $interval
3. Tester le comportement avec "All" vs valeurs spécifiques
4. Observer le refresh automatique
```

---

#### Exercice 2: Query Variables (1h30)

**Requêtes Variables depuis Prometheus**:

```promql
# Liste des jobs
label_values(up, job)

# Liste des instances d'un job
label_values(up{job="$job"}, instance)

# Liste des métriques disponibles
label_values(__name__)

# Liste des codes HTTP status
label_values(http_requests_total, status)

# Liste dynamique basée sur regex
query_result(count by (service) (up{region="$region"}))
```

**Variables depuis InfluxDB (Flux)**:

```flux
// Liste des buckets
buckets()

// Liste des measurements
from(bucket: "$bucket")
  |> range(start: -30d)
  |> keep(columns: ["_measurement"])
  |> distinct(column: "_measurement")

// Liste des tags
from(bucket: "$bucket")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "$measurement")
  |> keys()
```

**Variables depuis MS SQL**:

```sql
-- Liste des databases
SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')

-- Liste des tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'

-- Valeurs uniques d'une colonne
SELECT DISTINCT Region FROM Customers ORDER BY Region
```

**TP Pratique**:
```
1. Créer variable "job" depuis Prometheus
2. Créer variable "instance" dépendante de $job
3. Créer variable "bucket" depuis InfluxDB
4. Créer variable "table" depuis MS SQL
5. Tester le chaînage automatique
```

---

#### Exercice 3: Variables Hiérarchiques (1h)

**Scénario**: Dashboard Multi-Niveau pour Infrastructure

**Architecture Variables**:
```
$region (All, EU, US, ASIA)
  └── $datacenter (depends on $region)
       └── $server (depends on $datacenter)
            └── $metric (cpu, memory, disk, network)
```

**Configuration Étape par Étape**:

```yaml
# Variable 1: Region
Name: region
Query: label_values(up, region)
Include All: true

# Variable 2: Datacenter (dépend de region)
Name: datacenter
Query: label_values(up{region=~"$region"}, datacenter)
Include All: true

# Variable 3: Server (dépend de datacenter)
Name: server
Query: label_values(up{region=~"$region", datacenter=~"$datacenter"}, instance)
Include All: true
Multi-value: true

# Variable 4: Metric (liste statique)
Name: metric
Type: Custom
Values: cpu,memory,disk,network
```

**Requêtes PromQL Utilisant ces Variables**:

```promql
# CPU Usage par server
100 - (avg by(instance) (rate(node_cpu_seconds_total{
  mode="idle",
  region=~"$region",
  datacenter=~"$datacenter",
  instance=~"$server"
}[5m])) * 100)

# Memory Usage
(node_memory_MemTotal_bytes{region=~"$region", instance=~"$server"} - 
 node_memory_MemAvailable_bytes{region=~"$region", instance=~"$server"}) / 
node_memory_MemTotal_bytes{region=~"$region", instance=~"$server"} * 100
```

**TP Pratique**:
```
1. Créer les 4 variables hiérarchiques
2. Créer 4 panels (CPU, Memory, Disk, Network)
3. Configurer repeat panels par $server
4. Tester avec:
   - region=All, datacenter=All, server=All
   - region=EU, datacenter=specific, server=specific
5. Observer la cascade de filtrage
```

---

#### Exercice 4: Usage Avancé (30min)

**Techniques Avancées**:

1. **Regex dans Variables**
```yaml
# Filtrer instances par pattern
Query: label_values(up{instance=~".*prod.*"}, instance)
```

2. **Variables dans Titres**
```
Title: "$region - $datacenter - CPU Usage"
```

3. **Variables Multi-Value**
```promql
# Supporte sélection multiple avec OR automatique
rate(http_requests_total{instance=~"$server"}[5m])
```

4. **Formattage Variables**
```
${variable}           # Valeur brute
${variable:csv}       # Format CSV: "val1","val2"
${variable:pipe}      # Format pipe: val1|val2
${variable:regex}     # Format regex: (val1|val2)
${variable:json}      # Format JSON
```

5. **Variables dans Annotations**
```yaml
Query: changes(app_version{region="$region"}[5m]) > 0
Title: "Deployment on $region"
```

**TP Final Consolidation** (voir section séparée ci-dessous)

---

## 🆕 Contenu à Créer: Day 3 - Lab 3.1 Organisations & Users

### Objectif
Mettre en place une gouvernance multi-tenant avec RBAC dans Grafana.

### Structure du Lab (2h)

```
Lab-3.1-Organisations-Users/
├── README.md
├── exercices/
│   ├── 01-create-organisations.md
│   ├── 02-manage-users.md
│   ├── 03-permissions-rbac.md
│   └── 04-audit-logs.md
├── scripts/
│   ├── create-orgs.sh            # Automatisation via API
│   ├── create-users.sh
│   └── assign-roles.sh
└── data/
    └── org-structure.yaml        # Définition organisations
```

### Contenu Détaillé

#### Partie 1: Create Organisation (30min)

**Concepts**:
- Multi-tenancy dans Grafana
- Isolation complète (dashboards, datasources, users)
- Use cases: départements, clients, environnements

**Via UI**:
```
1. Server Admin → Organizations
2. + New Org
3. Name: "Production Environment"
4. Create
```

**Via API**:
```bash
# Créer organisation
curl -X POST http://admin:password@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{"name":"Production Environment"}'

# Lister organisations
curl http://admin:password@localhost:3000/api/orgs
```

**TP**:
```
Créer 3 organisations:
1. "Production"    - Pour services live
2. "Development"   - Pour développeurs
3. "Support"       - Pour équipe support

Vérifier isolation:
- Chaque org a son propre espace
- Dashboards non partagés par défaut
```

---

#### Partie 2: Manage Organisations (30min)

**Gestion Utilisateurs par Org**:

```bash
# Ajouter user à une org
curl -X POST http://admin:password@localhost:3000/api/orgs/1/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail":"dev@company.com", "role":"Editor"}'

# Lister users d'une org
curl http://admin:password@localhost:3000/api/orgs/1/users

# Changer rôle
curl -X PATCH http://admin:password@localhost:3000/api/orgs/1/users/2 \
  -H "Content-Type: application/json" \
  -d '{"role":"Admin"}'

# Retirer user
curl -X DELETE http://admin:password@localhost:3000/api/orgs/1/users/2
```

**Préférences par Organisation**:
- Home Dashboard
- Timezone
- Theme (Light/Dark)
- Quotas (dashboards, datasources, users)

**TP**:
```
Organisation "Production":
- Ajouter: admin_prod (Admin), dev_prod (Editor), support_prod (Viewer)
- Configurer: Home Dashboard = "Production Overview"
- Quotas: Max 50 dashboards, 10 datasources

Organisation "Development":
- Ajouter: admin_dev (Admin), dev_team (Editor)
- Configurer: Theme = Dark
- Quotas: Unlimited
```

---

#### Partie 3: User Management (30min)

**Création Utilisateurs**:

```bash
# Créer user (global)
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name":"John Doe",
    "email":"john.doe@company.com",
    "login":"jdoe",
    "password":"SecurePass123!"
  }'

# Mise à jour user
curl -X PUT http://admin:password@localhost:3000/api/users/2 \
  -H "Content-Type: application/json" \
  -d '{
    "email":"john.doe@newdomain.com",
    "name":"John Doe Senior"
  }'

# Désactiver user
curl -X DELETE http://admin:password@localhost:3000/api/admin/users/2
```

**Gestion par UI**:
```
Server Admin → Users
- Create new user
- Edit existing user
- Manage org memberships
- Reset password
```

**TP**:
```
Créer profils utilisateurs:

1. Administrateurs:
   - admin_prod: Admin de "Production"
   - admin_dev: Admin de "Development"

2. Développeurs:
   - dev_team: Editor dans "Development"
   - dev_prod: Editor dans "Production" (lecture seule dashboards critiques)

3. Support:
   - support_l1: Viewer dans "Production" et "Support"
   - support_l2: Editor dans "Support", Viewer dans "Production"

Tester connexion avec chaque profil
```

---

#### Partie 4: Permissions et RBAC (30min)

**Rôles Grafana**:

| Rôle | Dashboards | Datasources | Users | Org Settings |
|------|------------|-------------|-------|--------------|
| **Viewer** | Lecture | - | - | - |
| **Editor** | CRUD | Lecture | - | - |
| **Admin** | CRUD | CRUD | CRUD | CRUD |

**Permissions Granulaires par Dashboard**:

```bash
# Définir permissions dashboard
curl -X POST http://admin:password@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {...},
    "folderId": 0,
    "overwrite": false,
    "permissions": [
      {"role": "Viewer", "permission": 1},   # View
      {"role": "Editor", "permission": 2},   # Edit
      {"userId": 5, "permission": 4}         # Admin
    ]
  }'
```

**Permissions par Folder**:
```
Production Dashboards/
├── Critical (Admin only)
├── Monitoring (Editor can edit)
└── Public (Viewer can see)
```

**TP**:
```
Configuration permissions:

1. Folder "Critical Production"
   - Admin: Full access
   - Editor: View only
   - Viewer: No access

2. Folder "Standard Monitoring"
   - Admin: Full access
   - Editor: Edit access
   - Viewer: View only

3. Dashboard "Public Status"
   - Tous: View only
   - Anonymous: Enabled

Tester avec différents rôles
```

---

## 📝 TP Consolidation Day 2 - Dashboard Complet avec Variables

### Objectif Final
Créer un dashboard production-ready avec templating avancé pour monitoring E-Banking.

### Spécifications

**Variables Requises**:
1. `$region`: Query variable (All, EU, US, ASIA)
2. `$environment`: Custom (production, staging)
3. `$service`: Query dépendant de $region
4. `$interval`: Interval (auto, 1m, 5m, 15m, 1h)
5. `$datasource`: Datasource type Prometheus

**Panels Requis** (6 panels):

1. **API Latency** (Graph)
```promql
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket{
    region=~"$region",
    service=~"$service"
  }[$interval])) by (le, service)
)
```

2. **Request Rate** (Stat)
```promql
sum(rate(http_requests_total{region=~"$region", service=~"$service"}[$interval]))
```

3. **Error Rate** (Gauge)
```promql
(sum(rate(http_requests_total{
  status=~"5..",
  region=~"$region",
  service=~"$service"
}[$interval])) / 
sum(rate(http_requests_total{
  region=~"$region",
  service=~"$service"
}[$interval]))) * 100
```

4. **Active Transactions** (Table depuis InfluxDB)
```flux
from(bucket: "payments")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> filter(fn: (r) => r.region == "${region}")
  |> aggregateWindow(every: ${interval}, fn: count)
```

5. **Top Services by Traffic** (Bar Chart)
```promql
topk(10, sum by (service) (
  rate(http_requests_total{region=~"$region"}[$interval])
))
```

6. **System Resources** (Repeat Panel par $service)
```promql
node_memory_MemAvailable_bytes{
  region=~"$region",
  service=~"$service"
} / node_memory_MemTotal_bytes * 100
```

**Configuration Dashboard**:
- Title: "E-Banking Monitoring - $region - $environment"
- Refresh: 30s
- Time range: Last 6 hours
- Repeat rows par $service (max 5)

**Critères de Réussite**:
- [ ] 5 variables fonctionnelles
- [ ] 6 panels avec données réelles
- [ ] Chaînage variables correct
- [ ] Repeat panels opérationnel
- [ ] Dashboard exportable en JSON
- [ ] Provisioning YAML créé

---

## 🎯 Priorités de Développement

### Sprint 1 (2 jours) - CRITIQUE
1. ✅ Créer `Lab-2.2-Templates-Variables/`
   - Exercices 1-4 avec solutions
   - TP consolidation
   - Data generation scripts

### Sprint 2 (1 jour) - CRITIQUE
2. ✅ Créer `Lab-3.1-Organisations-Users/`
   - 4 parties avec exercices
   - Scripts automation API
   - Cas pratiques multi-tenant

### Sprint 3 (1 jour)
3. ✅ Enrichir `Lab-2.1-Dashboards/`
   - Exemples SLA/SLO complets
   - PromQL optimisé avec labels
   - 3 dashboards types (SLA, Perf, App)

### Sprint 4 (1 jour)
4. ✅ Créer `Lab-3.3-Best-Practices/`
   - Observability strategies
   - Time series concepts
   - Custom plugins intro
   - Maturity model

---

## ✅ Checklist Finale de Conformité

### Structure
- [ ] Dossier `hands-lab-21h/` créé
- [ ] Day 1 (7h): 4 labs
- [ ] Day 2 (7h): 2 labs (dont Templates)
- [ ] Day 3 (7h): 3 labs (dont Organisations)

### Contenu Day 2
- [ ] Lab 2.1: Dashboards SLA/SLO/Perf
- [ ] Lab 2.2: Templates & Variables (complet)
  - [ ] Variable Syntax (tous types)
  - [ ] Query Variables
  - [ ] Chained Variables
  - [ ] Advanced Usage
  - [ ] TP consolidation

### Contenu Day 3
- [ ] Lab 3.1: Organisations & Users (complet)
  - [ ] Create Organisation
  - [ ] Manage Organisations
  - [ ] User Management
  - [ ] RBAC détaillé
  - [ ] Audit
- [ ] Lab 3.2: Alerting (adapté)
- [ ] Lab 3.3: Best Practices
  - [ ] Observability Strategies
  - [ ] Maturity Model
  - [ ] Time Series
  - [ ] Custom Plugins

### Documentation
- [ ] README principal `hands-lab-21h/`
- [ ] Chaque lab avec README détaillé
- [ ] Solutions et corrections
- [ ] Scripts d'automatisation

---

**Prochaine Action**: Commencer Sprint 1 - Créer `Lab-2.2-Templates-Variables/README.md`
