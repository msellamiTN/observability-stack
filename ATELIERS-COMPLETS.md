# 🎓 Liste Complète des Ateliers - Stack d'Observabilité Grafana

## 📚 Vue d'Ensemble

Cette stack d'observabilité complète couvre **tous les aspects** du monitoring moderne : métriques, logs, traces, et alerting. Voici la liste exhaustive des ateliers disponibles basés sur les composants déployés.

---

## 🗓️ JOUR 1 : Fondamentaux Grafana et Datasources

### 🎓 Atelier 1 : Introduction à Grafana (1h30)
**📍 Théorie + Démo**

**Contenu :**
- 🏗️ Architecture et philosophie Grafana
- 📊 Comparaison OSS vs Enterprise vs Cloud
- 🔑 Fonctionnalités clés (Dashboards, Alerting, Plugins)
- 🎯 Positionnement dans l'écosystème d'observabilité
- 💡 Use cases et bonnes pratiques

**Livrables :**
- ✅ Compréhension de l'architecture
- ✅ Quiz de validation
- ✅ Documentation de référence

---

### 🚀 Atelier 2 : Installation avec Docker Compose (2h)
**🛠️ Pratique**

**Contenu :**
- 📦 Déploiement de la stack complète
- ⚙️ Configuration du fichier .env
- 🔐 Sécurisation des accès
- 🖥️ Navigation dans l'interface
- 🐛 Troubleshooting courant

**Commandes Clés :**
```bash
# Démarrer la stack
docker compose up -d

# Vérifier les services
docker compose ps

# Accéder à Grafana
http://localhost:3000
```

**Livrables :**
- ✅ Stack opérationnelle
- ✅ Accès Grafana configuré
- ✅ Checklist de vérification

**💡 Tips :**
- Changez immédiatement les mots de passe par défaut
- Vérifiez les logs avec `docker compose logs`
- Utilisez `docker compose restart` en cas de problème

---

### 🗄️ Atelier 3 : Datasource InfluxDB (1h30)
**🛠️ Pratique**

**Contenu :**
- 📊 Modèle de données InfluxDB (Buckets, Measurements, Tags, Fields)
- 🔌 Configuration de la connexion
- 📝 Langage Flux : requêtes basiques
- 📈 Visualisation de séries temporelles

**Architecture InfluxDB :**
```
Organization (myorg)
└── Bucket (payments)
    └── Measurement (payment_transactions)
        ├── Tags: type, status, region
        ├── Fields: amount, fee, duration
        └── Timestamp
```

**Requêtes Flux Essentielles :**
```flux
// Lire les données
from(bucket: "payments")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "payment_transactions")

// Agrégation
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 5m, fn: sum)

// Grouper par tag
from(bucket: "payments")
  |> range(start: -1h)
  |> group(columns: ["type"])
  |> sum()
```

**Livrables :**
- ✅ Datasource InfluxDB configurée
- ✅ Données de test créées
- ✅ Requêtes Flux fonctionnelles
- ✅ Premier panel de visualisation

**🐛 Troubleshooting :**
- **Connection refused** → Vérifier que InfluxDB est démarré
- **Unauthorized** → Vérifier le token dans .env
- **No data** → Créer des données de test

---

### 📈 Atelier 4 : Datasource Prometheus (1h30)
**🛠️ Pratique**

**Contenu :**
- 🎯 Architecture Prometheus (Pull-based)
- 📊 Modèle de métriques (Counters, Gauges, Histograms)
- 🔍 Langage PromQL
- 📉 Visualisation de métriques système

**Métriques Disponibles :**
- `up` : Statut des targets
- `http_requests_total` : Nombre de requêtes HTTP
- `http_request_duration_seconds` : Latence des requêtes
- `node_cpu_seconds_total` : Utilisation CPU
- `node_memory_MemAvailable_bytes` : Mémoire disponible

**Requêtes PromQL Essentielles :**
```promql
# Métrique simple
http_requests_total

# Filtrer par label
http_requests_total{method="GET", status="200"}

# Rate (requêtes par seconde)
rate(http_requests_total[5m])

# Agrégation
sum by (method) (rate(http_requests_total[5m]))

# Taux d'erreur
(
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
) * 100

# Percentile 95
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
)
```

**Livrables :**
- ✅ Datasource Prometheus configurée
- ✅ Exploration des targets
- ✅ Requêtes PromQL maîtrisées
- ✅ Dashboard de métriques système

**💡 Tips :**
- Utilisez `rate()` pour les counters
- Agrégez avec `sum()`, `avg()`, `max()`
- Filtrez avec `by` ou `without`
- Testez vos requêtes dans Prometheus UI (port 9090)

---

### 💾 Atelier 5 : Datasource MS SQL Server (1h30)
**🛠️ Pratique**

**Contenu :**
- 🗄️ Connexion à MS SQL Server
- 📝 Requêtes SQL pour Grafana
- 🔄 Utilisation des macros Grafana
- 📊 Visualisation de données métier

**Configuration :**
```yaml
Host: mssql:1433
Database: EBankingDB
User: sa
Password: EBanking@Secure123!
```

**Requêtes SQL pour Grafana :**
```sql
-- Time Series
SELECT 
    TransactionDate AS time,
    SUM(Amount) AS value,
    TransactionType AS metric
FROM Transactions
WHERE $__timeFilter(TransactionDate)
GROUP BY TransactionDate, TransactionType
ORDER BY time

-- Agrégation
SELECT 
    TransactionType,
    COUNT(*) AS count,
    SUM(Amount) AS total_amount,
    AVG(Amount) AS avg_amount
FROM Transactions
WHERE TransactionDate >= DATEADD(day, -7, GETDATE())
GROUP BY TransactionType

-- Avec variables Grafana
SELECT 
    TransactionDate AS time,
    Amount AS value
FROM Transactions
WHERE 
    $__timeFilter(TransactionDate)
    AND TransactionType = '$transaction_type'
ORDER BY time
```

**Macros Grafana :**
| Macro | Description |
|-------|-------------|
| `$__timeFrom()` | Début de la plage temporelle |
| `$__timeTo()` | Fin de la plage temporelle |
| `$__timeFilter(column)` | Filtre temporel complet |
| `$__interval` | Intervalle automatique |

**Livrables :**
- ✅ Datasource MS SQL configurée
- ✅ Base de données EBankingDB créée
- ✅ Requêtes SQL fonctionnelles
- ✅ Dashboard de données métier

---

### 🎯 Atelier 6 : Premier Dashboard Multi-Sources (1h30)
**🛠️ Pratique**

**Contenu :**
- 📊 Création d'un dashboard complet
- 🔄 Combinaison de plusieurs datasources
- 🎨 Personnalisation des visualisations
- 💾 Sauvegarde et partage

**Dashboard Recommandé : "Observabilité E-Banking"**

**Panel 1 : Transactions par Type (InfluxDB)**
```flux
from(bucket: "payments")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["type"])
  |> aggregateWindow(every: 5m, fn: sum)
```
**Visualization:** Time Series

**Panel 2 : Taux de Requêtes API (Prometheus)**
```promql
sum by (status) (rate(http_requests_total[5m]))
```
**Visualization:** Graph

**Panel 3 : Top 10 Comptes (MS SQL)**
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
**Visualization:** Table

**Livrables :**
- ✅ Dashboard multi-sources opérationnel
- ✅ Variables configurées
- ✅ Panels sauvegardés et organisés

---

## 🗓️ JOUR 2 : Logs, Traces et Observabilité Avancée

### 📝 Atelier 7 : Loki - Agrégation de Logs (2h)
**🛠️ Pratique**

**Contenu :**
- 📚 Architecture Loki + Promtail
- 🔍 LogQL : langage de requête
- 🎯 Filtrage et parsing de logs
- 📊 Corrélation logs ↔ métriques

**Architecture :**
```
Applications → Promtail → Loki → Grafana
```

**Requêtes LogQL :**
```logql
// Logs d'une application
{ServiceName="payment-api"}

// Filtrer par niveau
{ServiceName="payment-api"} |= "ERROR"

// Parser JSON
{ServiceName="payment-api"} | json | level="error"

// Métriques depuis logs
sum(rate({ServiceName="payment-api"} |= "ERROR" [5m]))

// Logs d'une trace spécifique
{ServiceName="payment-api"} | json | trace_id="abc123"
```

**Livrables :**
- ✅ Loki + Promtail configurés
- ✅ Logs collectés et indexés
- ✅ Requêtes LogQL maîtrisées
- ✅ Dashboard de logs

**💡 Tips :**
- Utilisez des labels à faible cardinalité
- Parsez les logs structurés (JSON)
- Corrélation avec traces via trace_id

---

### 🔍 Atelier 8 : Tempo - Distributed Tracing (2h)
**🛠️ Pratique**

**Contenu :**
- 🎯 Concepts du tracing distribué
- 🔗 OpenTelemetry et instrumentation
- 📊 Analyse de traces
- 🔄 Corrélation traces ↔ métriques ↔ logs

**Architecture :**
```
Application (OpenTelemetry)
    ↓ OTLP (gRPC/HTTP)
Tempo (Storage)
    ↓
Grafana (Visualization)
```

**Protocoles Supportés :**
- **OTLP gRPC** : Port 4317
- **OTLP HTTP** : Port 4318
- **Zipkin** : Port 9411
- **Jaeger** : Port 14268

**API de Test :**
```bash
# Générer une trace
curl http://localhost:8888/api/payment/process \
  -H "Content-Type: application/json" \
  -d '{"amount": 100, "currency": "EUR"}'

# Vérifier dans Grafana Explore
# Query: {service.name="payment-api-instrumented"}
```

**Requêtes TraceQL :**
```traceql
// Toutes les traces d'un service
{service.name="payment-api-instrumented"}

// Traces avec erreurs
{service.name="payment-api-instrumented" && status=error}

// Traces lentes (> 1s)
{service.name="payment-api-instrumented" && duration > 1s}

// Filtrer par attribut
{service.name="payment-api-instrumented" && http.method="POST"}
```

**Livrables :**
- ✅ Tempo configuré
- ✅ Application instrumentée
- ✅ Traces collectées
- ✅ Analyse de latence et erreurs
- ✅ Corrélation avec logs et métriques

**🐛 Troubleshooting :**
- Vérifier les endpoints OTLP : `curl http://localhost:4318/v1/traces`
- Tester l'instrumentation : `docker compose logs payment-api_instrumented`
- Vérifier les traces : http://localhost:3200

---

### 🔔 Atelier 9 : Alerting Avancé (2h)
**🛠️ Pratique**

**Contenu :**
- 🚨 Configuration des règles d'alerte
- 📧 Canaux de notification (Email, Slack, Webhook)
- 🔀 Politiques de routage
- 🔕 Silences et maintenance

**Architecture Alerting :**
```
Grafana Alert Rules
    ↓
Alert Manager
    ↓ (routing)
├─ Email (Gmail SMTP)
├─ Slack (Webhook)
├─ PagerDuty
└─ Custom Webhook
```

**Règles d'Alerte Pré-configurées :**

**1. Service Down**
```yaml
Condition: up == 0
Severity: Critical
Notification: Slack + Email
```

**2. High CPU**
```promql
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.8
```
**Severity:** Warning

**3. High Error Rate**
```promql
(
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
) > 0.05
```
**Severity:** Critical

**4. Database Connection Issues**
```sql
SELECT COUNT(*) FROM sys.dm_exec_connections
WHERE session_id > 50
HAVING COUNT(*) > 100
```

**Configuration Slack :**
```yaml
# grafana/provisioning/alerting/contactpoints.yaml
name: slack-notifications
type: slack
settings:
  url: https://hooks.slack.com/services/YOUR/WEBHOOK
  text: |
    🚨 {{ .CommonLabels.alertname }}
    Severity: {{ .CommonLabels.severity }}
    {{ .CommonAnnotations.description }}
```

**Configuration Email (Gmail) :**
```ini
# grafana/grafana.ini
[smtp]
enabled = true
host = smtp.gmail.com:587
user = your-email@gmail.com
password = your-app-password
from_address = your-email@gmail.com
```

**Livrables :**
- ✅ Règles d'alerte configurées
- ✅ Canaux de notification testés
- ✅ Politiques de routage définies
- ✅ Documentation des runbooks

**💡 Tips :**
- Évitez l'alert fatigue : alertez sur l'actionnable
- Utilisez des seuils adaptatifs
- Documentez les procédures de résolution
- Testez régulièrement les notifications

---

### 📊 Atelier 10 : Dashboards Avancés (2h)
**🛠️ Pratique**

**Contenu :**
- 🎨 Techniques de visualisation avancées
- 🔄 Variables et templating
- 📐 Transformations de données
- 🔗 Drill-down et navigation

**Techniques Avancées :**

**1. Variables Dashboard**
```
# Variable : Environment
Type: Query
Query (Prometheus): label_values(up, environment)

# Variable : Service
Type: Query
Query (Prometheus): label_values(up{environment="$environment"}, job)

# Utilisation dans requête
up{environment="$environment", job="$service"}
```

**2. Transformations**
- **Merge** : Combiner plusieurs séries
- **Filter by value** : Filtrer les valeurs
- **Organize fields** : Réorganiser les colonnes
- **Calculate field** : Calculer de nouvelles valeurs
- **Group by** : Regrouper les données

**3. Drill-Down**
```
# Panel 1 : Vue d'ensemble
Link: /d/detail-dashboard?var-service=$__field_labels.service

# Panel 2 : Détail du service
Affiche les métriques détaillées du service sélectionné
```

**4. Annotations**
```promql
# Annoter les déploiements
ALERTS{alertname="DeploymentStarted"}
```

**Dashboard Recommandé : "Golden Signals"**

**Panel 1 : Latency (P50, P95, P99)**
```promql
histogram_quantile(0.50, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)
```

**Panel 2 : Traffic (Requests/sec)**
```promql
sum(rate(http_requests_total[5m]))
```

**Panel 3 : Errors (Error rate %)**
```promql
(
  sum(rate(http_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))
) * 100
```

**Panel 4 : Saturation (CPU, Memory)**
```promql
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m]))
```

**Livrables :**
- ✅ Dashboard avec variables
- ✅ Transformations appliquées
- ✅ Navigation drill-down
- ✅ Annotations configurées

---

### 💼 Atelier 11 : Monitoring E-Banking (2h)
**🛠️ Cas Pratique**

**Contenu :**
- 💰 Métriques métier (Transactions, Comptes, Fraude)
- 📊 KPIs financiers
- 🔍 Détection d'anomalies
- 📈 Reporting

**Métriques E-Banking :**

**1. Transactions**
```flux
// Volume de transactions
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1h, fn: count)

// Montant moyen
from(bucket: "payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._field == "amount")
  |> mean()
```

**2. Taux de Réussite**
```sql
SELECT 
    CAST(TransactionDate AS DATE) AS date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful,
    (SUM(CASE WHEN Status = 'SUCCESS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS success_rate
FROM Transactions
WHERE TransactionDate >= DATEADD(day, -30, GETDATE())
GROUP BY CAST(TransactionDate AS DATE)
ORDER BY date
```

**3. Détection de Fraude**
```sql
-- Transactions suspectes (montant élevé + fréquence)
SELECT 
    AccountID,
    COUNT(*) AS transaction_count,
    SUM(Amount) AS total_amount,
    MAX(Amount) AS max_amount
FROM Transactions
WHERE 
    TransactionDate >= DATEADD(hour, -1, GETDATE())
    AND Amount > 1000
GROUP BY AccountID
HAVING COUNT(*) > 5
ORDER BY total_amount DESC
```

**4. SLA Monitoring**
```promql
# Disponibilité du service (SLA 99.9%)
avg_over_time(up{job="payment-api"}[30d]) * 100

# Latence P95 < 500ms
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket{job="payment-api"}[5m])
) < 0.5
```

**Dashboard : "E-Banking Overview"**
- 💰 Volume de transactions (24h)
- 📊 Taux de réussite (%)
- 🚨 Alertes actives
- 📈 Tendances (7 jours)
- 🔍 Transactions suspectes
- ⏱️ Latence P95
- 💾 Utilisation des ressources

**Livrables :**
- ✅ Dashboard E-Banking complet
- ✅ Alertes métier configurées
- ✅ Détection de fraude active
- ✅ Reporting automatisé

---

## 🗓️ JOUR 3 : Optimisation et Production

### ⚡ Atelier 12 : Performance et Optimisation (2h)
**🛠️ Pratique**

**Contenu :**
- 🚀 Optimisation des requêtes
- 💾 Gestion du cache
- 📊 Downsampling et agrégation
- 🔧 Tuning de la stack

**Optimisations InfluxDB :**
```flux
// ❌ Mauvais : Trop de données
from(bucket: "payments")
  |> range(start: -365d)
  |> filter(fn: (r) => r._measurement == "payment_transactions")

// ✅ Bon : Agrégation
from(bucket: "payments")
  |> range(start: -365d)
  |> filter(fn: (r) => r._measurement == "payment_transactions")
  |> aggregateWindow(every: 1d, fn: mean)
  |> limit(n: 1000)
```

**Optimisations Prometheus :**
```promql
# ❌ Mauvais : Haute cardinalité
http_requests_total{user_id=~".*"}

# ✅ Bon : Agrégation
sum by (method, status) (http_requests_total)
```

**Optimisations SQL :**
```sql
-- ❌ Mauvais : Scan complet
SELECT * FROM Transactions
WHERE TransactionDate >= '2024-01-01'

-- ✅ Bon : Index + Limite
SELECT TOP 1000 
    TransactionID, Amount, TransactionDate
FROM Transactions WITH (INDEX(IX_TransactionDate))
WHERE TransactionDate >= DATEADD(day, -7, GETDATE())
ORDER BY TransactionDate DESC
```

**Configuration Grafana :**
```ini
[dataproxy]
timeout = 30
keep_alive_seconds = 30

[caching]
enabled = true

[query_history]
enabled = true
```

**Livrables :**
- ✅ Requêtes optimisées
- ✅ Cache configuré
- ✅ Performance améliorée
- ✅ Documentation des optimisations

---

### 🔐 Atelier 13 : Sécurité et RBAC (1h30)
**🛠️ Pratique**

**Contenu :**
- 👥 Gestion des utilisateurs et équipes
- 🔒 Permissions et rôles (RBAC)
- 🔑 Authentification (LDAP, OAuth, SAML)
- 🛡️ Sécurisation des datasources

**Rôles Grafana :**
- **Viewer** : Lecture seule
- **Editor** : Création/modification de dashboards
- **Admin** : Administration complète

**Configuration RBAC :**
```bash
# Créer une équipe
curl -X POST http://localhost:3000/api/teams \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{"name": "DevOps Team"}'

# Assigner des permissions
curl -X POST http://localhost:3000/api/folders/1/permissions \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{
    "items": [
      {"teamId": 1, "permission": 2}
    ]
  }'
```

**Livrables :**
- ✅ Utilisateurs et équipes créés
- ✅ Permissions configurées
- ✅ Authentification sécurisée

---

### 📦 Atelier 14 : Backup et Disaster Recovery (1h30)
**🛠️ Pratique**

**Contenu :**
- 💾 Sauvegarde des dashboards
- 🔄 Export/Import de configuration
- 🗄️ Backup des données
- 🚨 Plan de reprise d'activité

**Backup Grafana :**
```bash
# Backup des dashboards
curl -X GET http://localhost:3000/api/search \
  -u admin:password | jq -r '.[].uid' | \
  while read uid; do
    curl -X GET "http://localhost:3000/api/dashboards/uid/$uid" \
      -u admin:password > "backup_$uid.json"
  done

# Backup des volumes Docker
docker run --rm \
  -v observability-stack_grafana_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup.tar.gz /data
```

**Livrables :**
- ✅ Scripts de backup automatisés
- ✅ Procédure de restauration testée
- ✅ Plan de DR documenté

---

### 🚀 Atelier 15 : Déploiement en Production (2h)
**🛠️ Pratique**

**Contenu :**
- 🌐 Configuration pour la production
- 🔒 SSL/TLS avec reverse proxy
- 📊 Monitoring de la stack elle-même
- 📈 Scalabilité et haute disponibilité

**Architecture Production :**
```
Internet
    ↓
Nginx (Reverse Proxy + SSL)
    ↓
Grafana (HA - 2+ instances)
    ↓
├─ Prometheus (HA)
├─ Loki (HA)
├─ Tempo (HA)
└─ PostgreSQL (Primary + Replica)
```

**Configuration Nginx :**
```nginx
server {
    listen 443 ssl http2;
    server_name grafana.example.com;

    ssl_certificate /etc/ssl/certs/grafana.crt;
    ssl_certificate_key /etc/ssl/private/grafana.key;

    location / {
        proxy_pass http://grafana:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Livrables :**
- ✅ Configuration production
- ✅ SSL/TLS activé
- ✅ Haute disponibilité configurée
- ✅ Documentation de déploiement

---

## 📚 Ressources et Documentation

### 🔗 Liens Utiles

| Ressource | URL | Description |
|-----------|-----|-------------|
| **Grafana Docs** | https://grafana.com/docs/ | Documentation officielle |
| **Prometheus** | https://prometheus.io/docs/ | Guide Prometheus |
| **InfluxDB** | https://docs.influxdata.com/ | Documentation InfluxDB |
| **Loki** | https://grafana.com/docs/loki/ | Guide Loki |
| **Tempo** | https://grafana.com/docs/tempo/ | Documentation Tempo |

### 📖 Fichiers de la Stack

| Fichier | Description |
|---------|-------------|
| `docker-compose.yml` | Configuration complète de la stack |
| `.env.example` | Template de configuration |
| `DEPLOYMENT-GUIDE.md` | Guide de déploiement |
| `ALERTING-README.md` | Configuration des alertes |
| `OBSERVABILITY-DESIGN-PATTERNS.md` | Patterns d'observabilité |

### 🎯 Checklist Complète

#### Jour 1
- [ ] Grafana installé et accessible
- [ ] InfluxDB configuré et testé
- [ ] Prometheus configuré et testé
- [ ] MS SQL configuré et testé
- [ ] Premier dashboard créé

#### Jour 2
- [ ] Loki et Promtail configurés
- [ ] Tempo et tracing opérationnels
- [ ] Alerting configuré et testé
- [ ] Dashboard avancé créé
- [ ] Monitoring E-Banking déployé

#### Jour 3
- [ ] Optimisations appliquées
- [ ] RBAC configuré
- [ ] Backup automatisé
- [ ] Configuration production prête

---

## 🎉 Conclusion

Cette formation complète couvre **tous les aspects** d'une stack d'observabilité moderne :

✅ **15 ateliers pratiques**  
✅ **3 jours de formation intensive**  
✅ **Métriques, Logs, Traces**  
✅ **Alerting et Dashboards**  
✅ **Production-ready**  

**🚀 Vous êtes maintenant prêt à déployer et gérer une infrastructure d'observabilité complète !**

---

**📧 Support :** Consultez les fichiers README de chaque composant  
**🐛 Issues :** Référez-vous aux sections Troubleshooting  
**📚 Documentation :** Tous les guides sont dans le répertoire `observability-stack/`
