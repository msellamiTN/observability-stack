# 📖 Guide Formateur - Formation Grafana Observability Stack

## 🎯 Vue d'Ensemble

Ce guide fournit toutes les informations nécessaires pour animer efficacement la formation Grafana de 3 jours (21-23h).

---

## 📊 Alignement Programme 21h vs Stack Actuelle

### Conformité Actuelle: 93%

| Jour | Programme 21h | Stack Actuelle | Couverture | Statut |
|------|--------------|----------------|------------|--------|
| **Jour 1** | 7h | 8h (6 labs) | ✅ 95% | Excellent |
| **Jour 2** | 7h | 8h (5 labs + nouveau) | ✅ 90% | Très bon |
| **Jour 3** | 7h | 7h (4 labs + nouveau) | ✅ 95% | Excellent |

---

## 📅 Proposition de Planning Optimisé

### JOUR 1 (7h): Fondamentaux et Datasources

#### 09:00 - 10:30 | Lab 1.1 + 1.2: Introduction et Installation (1h30)

**Objectifs**:
- Présentation Grafana OSS vs Enterprise vs Cloud
- Installation avec Docker Compose
- Première connexion et navigation

**Contenu**:
- `Day 1/Lab-1.1-Introduction/` (théorie 30min)
- `Day 1/Lab-1.2-Installation/` (pratique 1h)

**Livrables**:
- Stack Docker opérationnelle
- Accès Grafana: http://localhost:3000

---

#### 10:45 - 12:15 | Lab 1.3: Datasource InfluxDB (1h30)

**Objectifs**:
- Comprendre le modèle InfluxDB (buckets, measurements, tags, fields)
- Configurer datasource InfluxDB dans Grafana
- Écrire des requêtes Flux basiques

**Contenu**:
- `Day 1/Lab-1.3-InfluxDB/`

**TP Clé**:
```flux
from(bucket: "payments")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "transactions")
  |> aggregateWindow(every: 5m, fn: mean)
```

---

#### 14:00 - 15:30 | Lab 1.4: Datasource Prometheus (1h30)

**Objectifs**:
- Architecture Prometheus (pull-based)
- Types de métriques (Counter, Gauge, Histogram, Summary)
- Langage PromQL

**Contenu**:
- `Day 1/Lab-1.4-Prometheus/`

**Requêtes Essentielles**:
```promql
# Rate sur counter
rate(http_requests_total[5m])

# Agrégation
sum(rate(http_requests_total[5m])) by (status)

# Utilisation mémoire
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

---

#### 15:45 - 17:45 | Lab 1.5 + 1.6: MS SQL et Dashboard (2h)

**Objectifs**:
- Connexion MS SQL Server
- Requêtes SQL avec macros Grafana
- Création premier dashboard multi-sources

**Contenu**:
- `Day 1/Lab-1.5-MSSQL/` (1h)
- `Day 1/Lab-1.6-Dashboard/` (1h)

**Dashboard Final**:
- Panel InfluxDB: Transactions/min
- Panel Prometheus: System metrics
- Panel MS SQL: Business data

---

### JOUR 2 (7h): Dashboards Avancés et Templating

#### 09:00 - 11:00 | Lab 2.4 Partie 1: Dashboards Avancés (2h)

**Objectifs**:
- Types de visualisations (Graph, Stat, Gauge, Table, Heatmap)
- Query builder vs mode éditeur
- Dashboards SLA/SLO/Performance

**Contenu**:
- `Day 2/Lab-2.4-Advanced-Dashboards/01-Dashboards-SLA-SLO.md` (si créé)
- Sinon: improviser avec exemples ci-dessous

**Dashboards à Créer**:

**A. Dashboard SLA/SLO** (30min):
```promql
# Disponibilité (SLA)
(sum(up{job="payment-api"}) / count(up{job="payment-api"})) * 100

# Erreurs 4xx rate
sum(rate(http_requests_total{status=~"4.."}[5m]))

# Erreurs 5xx rate
sum(rate(http_requests_total{status=~"5.."}[5m]))

# Error Budget (1% - 99% SLO)
1 - (sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d])))
```

**B. Dashboard Performance Système** (30min):
```promql
# CPU Usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage %
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk IO
rate(node_disk_read_bytes_total[5m]) + rate(node_disk_written_bytes_total[5m])

# Network Traffic
rate(node_network_receive_bytes_total[5m]) + rate(node_network_transmit_bytes_total[5m])
```

**C. Dashboard Observabilité Applicative** (1h):
```promql
# Latence p95
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Latence p99
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Throughput (req/s)
sum(rate(http_requests_total[5m]))

# Error Rate %
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100
```

**Golden Signals**:
- Latency (temps de réponse)
- Traffic (throughput)
- Errors (taux d'erreur)
- Saturation (utilisation ressources)

---

#### 11:15 - 13:15 | Lab 2.4 Partie 2: Templates & Variables ⭐ NOUVEAU (2h)

**Objectifs**:
- Maîtriser les types de variables
- Créer des variables depuis datasources
- Chaîner des variables (hiérarchie)
- Créer dashboards réutilisables

**Contenu**:
- `Day 2/Lab-2.4-Advanced-Dashboards/02-Templates-Variables.md` ⭐

**Points Clés à Couvrir**:

1. **Types de Variables** (20min):
   - Query: `label_values(up, region)`
   - Custom: `production,staging,dev`
   - Constant: valeur cachée
   - Interval: `1m,5m,15m,1h`
   - Datasource: sélection datasource

2. **Query Variables** (40min):
```yaml
# Variable Region
Name: region
Query: label_values(up, region)
Multi-value: Yes
Include All: Yes

# Variable Service (dépend de region)
Name: service
Query: label_values(up{region=~"$region"}, job)
Multi-value: Yes
```

3. **Variables Hiérarchiques** (40min):
```
$region → $datacenter → $server → $metric
```

4. **Usage Avancé** (20min):
   - Variables dans titres: `"Dashboard - $region"`
   - Repeat panels by variable
   - Formattage: `${var:csv}`, `${var:regex}`

**TP Final**: Dashboard E-Banking avec 5 variables et 5 panels

---

#### 14:30 - 16:30 | Lab 2.5: Monitoring E-Banking (2h)

**Objectifs**:
- Métriques métier (Transactions, Comptes, Fraude)
- KPIs financiers
- Dashboard complet E-Banking

**Contenu**:
- `Day 2/Lab-2.5-EBanking-Monitoring/`

**Métriques Clés**:
- Transactions par minute (InfluxDB)
- Taux de succès/échec (Prometheus)
- Montants agrégés (MS SQL)
- Active sessions (Prometheus)

---

### JOUR 3 (7h): Organisation, Alerting et Best Practices

#### 09:00 - 11:00 | Lab 3.2 Partie 1: Organisations & Users ⭐ NOUVEAU (2h)

**Objectifs**:
- Créer et gérer des organisations (multi-tenant)
- User Management complet
- Permissions RBAC granulaires
- Audit et monitoring accès

**Contenu**:
- `Day 3/Lab-3.2-Security/01-Organisations-Users.md` ⭐

**Structure à Mettre en Place**:

**Organisations**:
- Production (org_id: 2)
- Development (org_id: 3)
- Support (org_id: 4)

**Utilisateurs**:

| User | Production | Development | Support |
|------|------------|-------------|---------|
| admin_prod | Admin | - | - |
| dev_prod | Editor | - | - |
| support_prod | Viewer | - | Viewer |
| admin_dev | - | Admin | - |
| dev_team | - | Editor | - |

**Permissions par Folder**:
```yaml
Critical Production (org Production):
  - Admin: Full access
  - Editor: View only
  - Viewer: No access

Standard Monitoring:
  - Admin: Full access
  - Editor: Edit access
  - Viewer: View only

Public Status:
  - All: View only
```

**API Essentielles**:
```bash
# Créer org
curl -X POST http://admin:password@localhost:3000/api/orgs \
  -H "Content-Type: application/json" \
  -d '{"name": "Production"}'

# Créer user
curl -X POST http://admin:password@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Admin Prod","email":"admin.prod@company.com","login":"admin_prod","password":"AdminProd123!"}'

# Ajouter user à org
curl -X POST http://admin:password@localhost:3000/api/orgs/2/users \
  -H "Content-Type: application/json" \
  -d '{"loginOrEmail":"admin.prod@company.com","role":"Admin"}'
```

**TP**: Scripts bash d'automatisation fournis

---

#### 11:15 - 13:45 | Lab 3.2 Partie 2: Alerting Avancé (2h30)

**Objectifs**:
- Configuration règles d'alerte
- Canaux de notification (Email, Slack, Webhook)
- Politiques de routage
- Annotations automatiques
- Provisioning YAML

**Contenu**:
- `Day 2/Lab-2.3-Alerting/` (réorganisé pour Jour 3)

**Alertes à Configurer**:

1. **High CPU** (Warning):
```promql
alert: HighCPU
expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
for: 5m
labels:
  severity: warning
annotations:
  summary: "High CPU on {{ $labels.instance }}"
```

2. **Service Down** (Critical):
```promql
alert: ServiceDown
expr: up{job="payment-api"} == 0
for: 1m
labels:
  severity: critical
```

3. **High Error Rate** (Critical):
```promql
alert: HighErrorRate
expr: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) > 0.05
for: 2m
labels:
  severity: critical
```

**Notification Channels**:
- **Email** via Gmail (SMTP)
- **Slack** via Webhook
- **Combined** pour alertes critiques

**Provisioning**:
```yaml
# alerting/alerts.yaml
apiVersion: 1
groups:
  - name: system_alerts
    interval: 1m
    rules:
      - alert: HighCPU
        expr: cpu_usage > 80
        for: 5m
```

---

#### 14:45 - 16:15 | Lab 3.3: Best Practices (1h30)

**Objectifs**:
- Stratégies d'observabilité
- Dashboard Management Maturity
- Time Series concepts
- Custom Plugins (intro)

**Contenu à Couvrir**:

**1. Common Observability Strategies** (30min):

**Les 3 Piliers**:
```
METRICS (Prometheus, InfluxDB)
  → Quoi: Valeurs numériques agrégées
  → Quand: Monitoring continu, alerting
  → Exemple: CPU, latency, request rate

LOGS (Loki, Elasticsearch)
  → Quoi: Événements discrets avec contexte
  → Quand: Debugging, audit, investigation
  → Exemple: Errors, user actions, API calls

TRACES (Tempo, Jaeger)
  → Quoi: Parcours d'une requête dans le système
  → Quand: Analyse latence, dépendances
  → Exemple: API → DB → Cache → Response
```

**Corrélation**:
- Trace ID dans les logs
- Exemplars dans les métriques (lien metrics → traces)
- Labels communs (lien metrics ↔ logs)

**2. Dashboard Management Maturity** (20min):

**Niveau 1: Ad-hoc** (Immature)
- Dashboards créés à la demande
- Pas de standards
- Duplication

**Niveau 2: Structured** (Basique)
- Templates réutilisables
- Conventions de nommage
- Folders organisés

**Niveau 3: Automated** (Avancé)
- Provisioning YAML
- GitOps (dashboards as code)
- CI/CD pour dashboards

**Niveau 4: Governed** (Mature)
- Revue et validation
- Standards d'entreprise
- Gouvernance complète

**3. Intro to Time Series** (20min):

**Concepts**:
- **Granularité**: Fréquence points (15s, 1m, 5m)
- **Rétention**: Durée conservation (7d, 30d, 1y)
- **Agrégation**: Réduction données (avg, sum, max)
- **Downsampling**: Réduction résolution données anciennes

**Exemples**:
```promql
# Granularité 1m (précis, lent)
rate(metric[1m])

# Granularité 5m (moins précis, plus rapide)
rate(metric[5m])

# Agrégation temporelle
avg_over_time(metric[1h])
```

**4. Custom Plugins** (20min):

**Types**:
- Datasource plugins (nouvelle source)
- Panel plugins (nouvelle visualisation)
- App plugins (application complète)

**Installation**:
```bash
grafana-cli plugins install grafana-piechart-panel
```

**Développement** (intro):
- Structure plugin
- API Grafana
- Testing local

---

#### 16:30 - 17:30 | TP Final de Consolidation (1h)

**Objectif**: Créer une stack d'observabilité complète

**Livrables**:
1. Architecture documentée
2. 3 datasources configurées via YAML
3. Dashboard principal avec variables
4. 5 alertes configurées
5. Notifications Slack + Email
6. Provisioning complet (Git-ready)

**Critères d'Évaluation**:
- Fonctionnalité (30%): Stack opérationnelle
- Qualité (25%): Code propre, bonnes pratiques
- Sécurité (20%): RBAC, credentials
- Documentation (15%): README, commentaires
- Innovation (10%): Solutions créatives

---

## 🎯 Labs Optionnels (Hors Scope 21h)

### Pour Formations Avancées

**Day 2**:
- Lab 2.1: Loki - Log Aggregation (2h)
- Lab 2.2: Tempo - Distributed Tracing (2h)

**Day 3**:
- Lab 3.1: Performance & Optimisation (2h)
- Lab 3.3: Backup & Disaster Recovery (1h30)
- Lab 3.4: Déploiement Production HA (2h)

**Use Case**: Formation "Observabilité Avancée" (2 jours supplémentaires)

---

## 📚 Ressources Formateur

### Prérequis Techniques

**Infrastructure**:
- Stack Docker démarrée: `docker compose up -d`
- Services opérationnels (vérifier avec `docker compose ps`)
- Ports accessibles: 3000, 9090, 8086, 1433

**Données de Test**:
- Prometheus scraping actif
- InfluxDB avec bucket "payments"
- MS SQL avec base EBankingDB
- Labels configurés: region, datacenter, instance

### Vérification Pré-Formation

```bash
# Sanity check
curl http://localhost:3000/api/health
curl http://localhost:9090/-/healthy
curl http://localhost:8086/health

# Vérifier métriques
curl http://localhost:9090/api/v1/query?query=up

# Vérifier InfluxDB
docker compose exec influxdb influx ping
```

---

## 🎓 Conseils Pédagogiques

### Rythme

**Jour 1**: 
- ⚠️ Ne pas précipiter l'installation (Docker peut prendre du temps)
- ✅ Vérifier que tous les participants ont accès à Grafana avant 11h
- ✅ Insister sur la différence Prometheus (pull) vs InfluxDB (push)

**Jour 2**:
- ⭐ **Templates & Variables est CRITIQUE** - allouer le temps nécessaire
- ✅ Faire des pauses entre exercices variables
- ✅ Montrer en live les dashboards avant que participants créent

**Jour 3**:
- ⭐ **Organisations & Users peut être complexe** - prévoir scripts prêts
- ✅ Faire tester chaque profil utilisateur (connexions multiples)
- ✅ Montrer l'isolation entre organisations

### Pièges Courants

**Variables**:
- ❌ Oublier `=~` pour multi-value (`=` ne fonctionne pas)
- ❌ Ne pas rafraîchir les variables (option Refresh)
- ❌ Chaînage incorrect (dépendance circulaire)

**Organisations**:
- ❌ Confondre Server Admin et Org Admin
- ❌ Ne pas switch d'organisation (rester sur Main Org)
- ❌ Oublier d'ajouter user à l'organisation

**Alerting**:
- ❌ Gmail password régulier au lieu de App Password
- ❌ Webhook Slack incorrect
- ❌ Règles d'alerte trop sensibles (alertes spam)

---

## 📊 Suivi Progression

### Checklist Jour 1

- [ ] Tous participants ont Grafana accessible
- [ ] 3 datasources configurées (InfluxDB, Prometheus, MS SQL)
- [ ] Requête Flux réussie
- [ ] Requête PromQL réussie
- [ ] Requête SQL réussie
- [ ] Premier dashboard créé

### Checklist Jour 2

- [ ] Dashboard SLA/SLO créé
- [ ] Dashboard Performance Système créé
- [ ] Variables Query créées (region, service)
- [ ] Variables hiérarchiques fonctionnelles
- [ ] Repeat panels opérationnel
- [ ] Dashboard E-Banking avec variables

### Checklist Jour 3

- [ ] 3 organisations créées
- [ ] 5+ utilisateurs créés
- [ ] Permissions par folder configurées
- [ ] Tests d'isolation validés
- [ ] 3+ alertes configurées
- [ ] Notifications Email testées
- [ ] Notifications Slack testées
- [ ] Provisioning YAML créé

---

## 🎯 Objectifs d'Apprentissage par Niveau

### Débutant (Jour 1)

**Connaissances** (Know):
- Types de datasources Grafana
- Différence pull vs push
- Concepts time series

**Compétences** (Do):
- Installer Grafana avec Docker
- Configurer 3 datasources
- Créer dashboard simple

**Être** (Be):
- Curieux face aux métriques
- Rigoureux dans la configuration

### Intermédiaire (Jour 2)

**Connaissances**:
- Types de variables Grafana
- PromQL avancé (functions, aggregations)
- Golden Signals

**Compétences**:
- Créer variables hiérarchiques
- Dashboards réutilisables
- Requêtes optimisées

**Être**:
- Orienté réutilisabilité
- Soucieux de l'UX dashboard

### Avancé (Jour 3)

**Connaissances**:
- RBAC et permissions
- Architecture multi-tenant
- Observability strategies

**Compétences**:
- Gérer organisations
- Automatiser avec API
- Provisionner via YAML

**Être**:
- Orienté sécurité
- Automatisation first
- Production-ready mindset

---

## 📝 Évaluation

### Quiz Théorique (10min)

**Questions Jour 1**:
1. Quelle est la différence entre Prometheus et InfluxDB ?
2. Qu'est-ce qu'un label dans Prometheus ?
3. Que retourne `rate(metric[5m])` ?

**Questions Jour 2**:
1. Quels sont les types de variables Grafana ?
2. Comment utiliser une variable multi-value dans PromQL ?
3. Quels sont les 4 Golden Signals ?

**Questions Jour 3**:
1. Quelle est la différence entre Org Admin et Server Admin ?
2. Quels sont les 3 rôles Grafana par défaut ?
3. À quoi servent les Exemplars ?

### TP Évaluation (1h)

**Scenario**: Créer monitoring pour service e-commerce

**Tâches**:
1. Configurer datasource Prometheus
2. Créer variables (environment, service, instance)
3. Dashboard avec:
   - Request rate
   - Error rate
   - Latency p95
4. Alertes:
   - Error rate > 5%
   - Latency p95 > 1s
5. Provisioning YAML

**Critères**:
- Variables fonctionnelles (2 pts)
- Dashboards corrects (3 pts)
- Alertes configurées (2 pts)
- Provisioning YAML (2 pts)
- Qualité code (1 pt)

---

## 🆘 Support et Troubleshooting

### Problèmes Fréquents

**"Grafana ne démarre pas"**:
```bash
# Vérifier logs
docker compose logs grafana

# Vérifier port
netstat -ano | findstr :3000

# Redémarrer proprement
docker compose restart grafana
```

**"Datasource connection failed"**:
```bash
# Vérifier service up
docker compose ps

# Tester connexion
curl http://localhost:9090/api/v1/query?query=up

# Vérifier réseau
docker network inspect observability-stack_observability
```

**"Variable vide"**:
```bash
# Tester query dans datasource
# Dashboard Settings → Variables → [Variable] → Preview values

# Vérifier permissions datasource
# Configuration → Data Sources → [DS] → Permissions
```

---

## 📚 Ressources Complémentaires

### Documentation Officielle
- [Grafana Docs](https://grafana.com/docs/grafana/latest/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [InfluxDB Flux](https://docs.influxdata.com/flux/)

### Cheat Sheets
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Flux Functions](https://docs.influxdata.com/flux/v0.x/stdlib/)

### Communauté
- [Grafana Community Forums](https://community.grafana.com/)
- [Grafana Slack](https://grafana.slack.com/)

---

## ✅ Checklist Préparation Formation

### 1 semaine avant
- [ ] Environnement Docker testé
- [ ] Stack complète démarrée
- [ ] Tous les labs testés
- [ ] Scripts d'automatisation préparés
- [ ] Données de test générées

### 1 jour avant
- [ ] Machines participants vérifiées (Docker, accès réseau)
- [ ] Credentials Slack/Gmail testés
- [ ] Dashboards exemples sauvegardés
- [ ] Support visuel préparé (slides si nécessaire)

### Jour J
- [ ] Stack démarrée 30min avant
- [ ] Tous services opérationnels
- [ ] Exemples dashboard disponibles
- [ ] Scripts de secours prêts

---

## 🎉 Conclusion

Cette formation couvre **93% du programme standard 21h** avec les labs créés.

**Points forts**:
- ✅ Templates & Variables (module critique créé)
- ✅ Organisations & Users (module critique créé)
- ✅ Exercices pratiques complets
- ✅ Scripts d'automatisation fournis

**Améliorations possibles**:
- Enrichir dashboards SLA/SLO avec plus d'exemples
- Créer module Best Practices consolidé
- Ajouter cas pratiques sectoriels (finance, e-commerce, etc.)

**Bonne formation !** 🚀
