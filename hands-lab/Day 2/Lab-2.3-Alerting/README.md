# 🔔 Lab 2.3 : Alerting Avancé avec Alertmanager

**Durée estimée** : 2 heures  
**Niveau** : Intermédiaire  
**Prérequis** : Lab 1.4 (Prometheus), Lab 2.1 (Loki)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Configurer des règles d'alerte dans Prometheus
- ✅ Maîtriser Alertmanager (routing, grouping, inhibition)
- ✅ Créer des alertes depuis Grafana (métriques et logs)
- ✅ Configurer des notifications (email, Slack, webhook)
- ✅ Gérer le silence et l'inhibition des alertes
- ✅ Créer des templates d'alertes personnalisés

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que les services sont démarrés
docker ps | grep -E "prometheus|alertmanager|grafana"

# Devrait afficher :
# - prometheus (port 9090)
# - alertmanager (port 9093)
# - grafana (port 3000)
```

### Accès aux Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Prometheus** | http://localhost:9090 | - |
| **Alertmanager** | http://localhost:9093 | - |

---

## 📚 Partie 1 : Architecture de l'Alerting (30 min)

### Composants

```
┌─────────────┐
│ Prometheus  │ ──── Scrape ────▶ Targets
│             │
│ Alert Rules │ ──── Evaluate ──▶ Conditions
└──────┬──────┘
       │ Fire Alert
       ▼
┌─────────────────┐
│ Alertmanager    │
│                 │
│ - Grouping      │
│ - Routing       │
│ - Inhibition    │
│ - Silencing     │
└────────┬────────┘
         │
         ├──▶ Email
         ├──▶ Slack
         ├──▶ PagerDuty
         └──▶ Webhook
```

### Workflow

1. **Prometheus** : Évalue les règles d'alerte
2. **Alertmanager** : Reçoit les alertes et les traite
3. **Routing** : Dirige vers les bons receivers
4. **Grouping** : Regroupe les alertes similaires
5. **Notification** : Envoie aux canaux configurés

### États d'une Alerte

| État | Description | Durée |
|------|-------------|-------|
| **Inactive** | Condition non remplie | - |
| **Pending** | Condition remplie, attente `for` | Configurable |
| **Firing** | Alerte active, envoyée à Alertmanager | Jusqu'à résolution |
| **Resolved** | Condition n'est plus remplie | - |

---

## 🔧 Partie 2 : Règles d'Alerte Prometheus (45 min)

### Structure d'une Règle

```yaml
groups:
  - name: example_alerts
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"
```

### Composants d'une Règle

| Champ | Description | Exemple |
|-------|-------------|---------|
| **alert** | Nom de l'alerte | `HighCPUUsage` |
| **expr** | Requête PromQL | `cpu_usage > 80` |
| **for** | Durée avant firing | `5m` |
| **labels** | Labels ajoutés | `severity: warning` |
| **annotations** | Informations descriptives | `summary`, `description` |

### Créer des Règles d'Alerte

Créez le fichier `prometheus/rules/alerts.yml` :

```yaml
groups:
  # Alertes Système
  - name: system_alerts
    interval: 30s
    rules:
      # CPU
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          component: system
          team: infrastructure
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanize }}% (threshold: 80%)"
          runbook_url: "https://wiki.company.com/runbooks/high-cpu"

      - alert: CriticalCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
        for: 2m
        labels:
          severity: critical
          component: system
          team: infrastructure
        annotations:
          summary: "CRITICAL: CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value | humanize }}% (threshold: 95%)"

      # Memory
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanize }}%"

      - alert: CriticalMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
        for: 2m
        labels:
          severity: critical
          component: system
        annotations:
          summary: "CRITICAL: Memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value | humanize }}%"

      # Disk
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{fstype!~"tmpfs|fuse.lxcfs"} / node_filesystem_size_bytes) * 100 < 20
        for: 10m
        labels:
          severity: warning
          component: storage
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Only {{ $value | humanize }}% available on {{ $labels.mountpoint }}"

  # Alertes Services
  - name: service_alerts
    interval: 30s
    rules:
      # Service Down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          component: service
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute"

      # Prometheus
      - alert: PrometheusTargetMissing
        expr: up{job="prometheus"} == 0
        for: 1m
        labels:
          severity: critical
          component: monitoring
        annotations:
          summary: "Prometheus target missing"
          description: "Prometheus target {{ $labels.instance }} is down"

      # Grafana
      - alert: GrafanaDown
        expr: up{job="grafana"} == 0
        for: 2m
        labels:
          severity: critical
          component: monitoring
        annotations:
          summary: "Grafana is down"
          description: "Grafana has been down for more than 2 minutes"

  # Alertes Application
  - name: application_alerts
    interval: 30s
    rules:
      # HTTP Errors
      - alert: HighHTTPErrorRate
        expr: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100 > 5
        for: 5m
        labels:
          severity: warning
          component: application
        annotations:
          summary: "High HTTP error rate"
          description: "Error rate is {{ $value | humanize }}% (threshold: 5%)"

      # Response Time
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
          component: application
        annotations:
          summary: "High response time"
          description: "95th percentile response time is {{ $value | humanize }}s"
```

### Recharger les Règles

```bash
# Windows PowerShell
docker-compose restart prometheus

# Vérifier les règles dans Prometheus
# http://localhost:9090/rules
```

### Tester les Règles

```bash
# Accéder à Prometheus
# http://localhost:9090/alerts

# Vérifier l'état des alertes :
# - Inactive (vert)
# - Pending (jaune)
# - Firing (rouge)
```

---

## 🎯 Exercice Pratique 1 : Créer des Alertes (30 min)

### Objectif

Créer et tester des règles d'alerte personnalisées.

### Étapes

#### 1. Créer une Alerte de Test

Ajoutez dans `prometheus/rules/alerts.yml` :

```yaml
- alert: AlwaysFiring
  expr: vector(1)
  for: 1m
  labels:
    severity: info
    component: test
  annotations:
    summary: "Test alert - Always firing"
    description: "This is a test alert that always fires"
```

#### 2. Recharger Prometheus

```bash
docker-compose restart prometheus
```

#### 3. Vérifier dans Prometheus

```
http://localhost:9090/alerts
```

Vous devriez voir l'alerte passer de **Pending** à **Firing** après 1 minute.

#### 4. Vérifier dans Alertmanager

```
http://localhost:9093/#/alerts
```

L'alerte devrait apparaître dans Alertmanager.

### ✅ Critères de Réussite

- [ ] L'alerte apparaît dans Prometheus
- [ ] L'alerte passe à l'état Firing après 1 minute
- [ ] L'alerte est visible dans Alertmanager

---

## 📨 Partie 3 : Configuration Alertmanager (45 min)

### Architecture de Configuration

```yaml
route:           # Routing principal
  receiver:      # Receiver par défaut
  routes:        # Routes spécifiques
    - match:     # Conditions de matching

receivers:       # Définition des receivers
  - name:        # Nom du receiver
    email_configs:
    slack_configs:
    webhook_configs:

inhibit_rules:   # Règles d'inhibition
templates:       # Templates personnalisés
```

### Configuration Complète

Éditez `alertmanager/alertmanager.yml` :

```yaml
global:
  # Configuration SMTP (Email)
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@company.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
  smtp_require_tls: true

  # Configuration Slack
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

# Routing des alertes
route:
  # Grouping : regrouper les alertes similaires
  group_by: ['alertname', 'cluster', 'service']
  
  # Timing
  group_wait: 30s        # Attendre 30s avant d'envoyer un groupe
  group_interval: 5m     # Attendre 5m avant d'envoyer de nouvelles alertes du même groupe
  repeat_interval: 4h    # Répéter toutes les 4h si non résolu

  # Receiver par défaut
  receiver: 'default'

  # Routes spécifiques
  routes:
    # Alertes critiques → Email + Slack
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 10s
      repeat_interval: 1h

    # Alertes warning → Slack uniquement
    - match:
        severity: warning
      receiver: 'warning-alerts'
      repeat_interval: 12h

    # Alertes infrastructure → Équipe infra
    - match:
        team: infrastructure
      receiver: 'infra-team'

    # Alertes application → Équipe dev
    - match:
        component: application
      receiver: 'dev-team'

# Définition des receivers
receivers:
  # Default
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/default'

  # Alertes critiques
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@company.com'
        headers:
          Subject: '🔴 CRITICAL: {{ .GroupLabels.alertname }}'
        html: '{{ template "email.html" . }}'
    slack_configs:
      - channel: '#alerts-critical'
        title: '🔴 CRITICAL ALERT'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        send_resolved: true

  # Alertes warning
  - name: 'warning-alerts'
    slack_configs:
      - channel: '#alerts-warning'
        title: '⚠️ WARNING'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
        send_resolved: true

  # Équipe infrastructure
  - name: 'infra-team'
    email_configs:
      - to: 'infra-team@company.com'
    slack_configs:
      - channel: '#team-infra'

  # Équipe développement
  - name: 'dev-team'
    email_configs:
      - to: 'dev-team@company.com'
    slack_configs:
      - channel: '#team-dev'

# Règles d'inhibition
inhibit_rules:
  # Si une alerte critique est active, ne pas envoyer les warnings similaires
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']

  # Si un service est down, ne pas alerter sur ses métriques
  - source_match:
      alertname: 'ServiceDown'
    target_match_re:
      alertname: '.*'
    equal: ['instance']

# Templates personnalisés
templates:
  - '/etc/alertmanager/templates/*.tmpl'
```

### Templates Personnalisés

Créez `alertmanager/templates/email.tmpl` :

```go
{{ define "email.html" }}
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; }
    .alert { padding: 15px; margin: 10px 0; border-radius: 5px; }
    .critical { background-color: #ffebee; border-left: 5px solid #f44336; }
    .warning { background-color: #fff3e0; border-left: 5px solid #ff9800; }
    .info { background-color: #e3f2fd; border-left: 5px solid #2196f3; }
  </style>
</head>
<body>
  <h2>🔔 Alert Notification</h2>
  
  {{ range .Alerts }}
  <div class="alert {{ .Labels.severity }}">
    <h3>{{ .Labels.alertname }}</h3>
    <p><strong>Summary:</strong> {{ .Annotations.summary }}</p>
    <p><strong>Description:</strong> {{ .Annotations.description }}</p>
    <p><strong>Severity:</strong> {{ .Labels.severity }}</p>
    <p><strong>Instance:</strong> {{ .Labels.instance }}</p>
    <p><strong>Started:</strong> {{ .StartsAt }}</p>
    {{ if .EndsAt }}
    <p><strong>Ended:</strong> {{ .EndsAt }}</p>
    {{ end }}
  </div>
  {{ end }}
  
  <p><a href="http://localhost:9093">View in Alertmanager</a></p>
</body>
</html>
{{ end }}
```

### Recharger Alertmanager

```bash
# Windows PowerShell
docker-compose restart alertmanager

# Vérifier les logs
docker logs alertmanager --tail 50
```

---

## 🎨 Partie 4 : Alertes Grafana (30 min)

### Types d'Alertes Grafana

1. **Alertes sur Métriques** (Prometheus, InfluxDB, etc.)
2. **Alertes sur Logs** (Loki)
3. **Alertes Unifiées** (Grafana 8+)

### Créer une Alerte depuis un Panel

#### 1. Créer un Panel de Métrique

```
Dashboard → Add panel → Add a new panel
```

**Query (Prometheus)** :
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

#### 2. Configurer l'Alerte

```
Panel → Alert tab → Create alert rule from this panel
```

**Configuration** :
```yaml
Name: High CPU Usage (Grafana)
Evaluate every: 1m
For: 5m

Condition:
  WHEN last() OF query(A)
  IS ABOVE 80
```

#### 3. Ajouter des Notifications

```
Contact points → Add contact point
```

**Exemple Slack** :
```yaml
Name: Slack Alerts
Type: Slack
Webhook URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**Exemple Email** :
```yaml
Name: Email Alerts
Type: Email
Addresses: oncall@company.com
```

#### 4. Créer une Notification Policy

```
Notification policies → Add policy
```

```yaml
Matching labels:
  severity = critical

Contact point: Slack Alerts
```

### Alertes sur Logs (Loki)

#### Créer une Alerte sur Volume de Logs

**Query (Loki)** :
```logql
sum(rate({job="docker"} |~ "error|ERROR" [5m]))
```

**Alert Condition** :
```yaml
WHEN last() OF query(A)
IS ABOVE 10
```

**Annotations** :
```yaml
Summary: High error rate in logs
Description: {{ $value }} errors per second detected
```

---

## 🎯 Exercice Pratique 2 : Alertes Complètes (30 min)

### Objectif

Créer un système d'alerting complet avec routing et notifications.

### Étapes

#### 1. Créer 3 Règles d'Alerte

Dans `prometheus/rules/alerts.yml` :

```yaml
groups:
  - name: lab_alerts
    interval: 30s
    rules:
      # Info
      - alert: TestInfo
        expr: vector(1)
        labels:
          severity: info
        annotations:
          summary: "Test info alert"

      # Warning
      - alert: TestWarning
        expr: vector(1)
        labels:
          severity: warning
        annotations:
          summary: "Test warning alert"

      # Critical
      - alert: TestCritical
        expr: vector(1)
        labels:
          severity: critical
        annotations:
          summary: "Test critical alert"
```

#### 2. Configurer le Routing

Dans `alertmanager/alertmanager.yml`, vérifiez les routes pour chaque severity.

#### 3. Tester le Routing

```bash
# Recharger
docker-compose restart prometheus alertmanager

# Vérifier dans Alertmanager
# http://localhost:9093/#/alerts

# Les alertes doivent être routées selon leur severity
```

#### 4. Créer une Alerte Grafana

- Panel : CPU Usage
- Condition : > 50%
- Contact point : Webhook (http://localhost:5001/grafana)

### ✅ Critères de Réussite

- [ ] 3 alertes créées (info, warning, critical)
- [ ] Routing fonctionnel dans Alertmanager
- [ ] Alertes visibles dans Grafana
- [ ] Contact points configurés

---

## 🔕 Partie 5 : Silences et Inhibition (15 min)

### Créer un Silence

#### Via Alertmanager UI

```
http://localhost:9093/#/silences → New Silence
```

**Configuration** :
```yaml
Matchers:
  alertname = TestCritical

Duration: 2h
Creator: admin@company.com
Comment: Maintenance window
```

#### Via API

```bash
# Créer un silence
curl -X POST http://localhost:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "alertname",
        "value": "TestCritical",
        "isRegex": false
      }
    ],
    "startsAt": "2024-10-27T00:00:00Z",
    "endsAt": "2024-10-27T02:00:00Z",
    "createdBy": "admin",
    "comment": "Maintenance window"
  }'
```

### Règles d'Inhibition

Les règles d'inhibition empêchent certaines alertes d'être envoyées si d'autres sont actives.

**Exemple** : Ne pas alerter sur CPU si le service est down

```yaml
inhibit_rules:
  - source_match:
      alertname: 'ServiceDown'
    target_match:
      alertname: 'HighCPUUsage'
    equal: ['instance']
```

---

## 📊 Partie 6 : Dashboard d'Alerting (15 min)

### Créer un Dashboard de Monitoring des Alertes

#### Panel 1 : Alertes Actives

**Type** : Stat

**Query (Prometheus)** :
```promql
ALERTS{alertstate="firing"}
```

**Configuration** :
- Color : Red
- Thresholds : 0 (green), 1 (red)

#### Panel 2 : Alertes par Severity

**Type** : Pie chart

**Queries** :
```promql
# Critical
count(ALERTS{alertstate="firing", severity="critical"})

# Warning
count(ALERTS{alertstate="firing", severity="warning"})

# Info
count(ALERTS{alertstate="firing", severity="info"})
```

#### Panel 3 : Timeline des Alertes

**Type** : State timeline

**Query** :
```promql
ALERTS{alertstate="firing"}
```

#### Panel 4 : Top Alertes

**Type** : Table

**Query** :
```promql
topk(10, count by (alertname) (ALERTS{alertstate="firing"}))
```

---

## 📖 Ressources

### Documentation Officielle

- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)

### Exemples de Règles

- [Awesome Prometheus Alerts](https://awesome-prometheus-alerts.grep.to/)
- [Prometheus Alert Rules](https://github.com/samber/awesome-prometheus-alerts)

### Intégrations

- [Slack Integration](https://prometheus.io/docs/alerting/latest/configuration/#slack_config)
- [Email Integration](https://prometheus.io/docs/alerting/latest/configuration/#email_config)
- [PagerDuty Integration](https://prometheus.io/docs/alerting/latest/configuration/#pagerduty_config)

---

## ✅ Checklist de Validation

Avant de passer au lab suivant, assurez-vous de :

- [ ] Prometheus évalue correctement les règles d'alerte
- [ ] Alertmanager reçoit et route les alertes
- [ ] Le routing fonctionne selon les labels
- [ ] Les silences fonctionnent
- [ ] Les règles d'inhibition sont effectives
- [ ] Vous avez créé des alertes dans Grafana
- [ ] Les notifications sont configurées (même en test)

---

## 🔙 Navigation

- [⬅️ Retour au Jour 2](../README.md)
- [➡️ Lab suivant : Lab 2.4 - Dashboards Avancés](../Lab-2.4-Advanced-Dashboards/)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

## 🎓 Points Clés à Retenir

1. **Prometheus** évalue les règles, **Alertmanager** gère le routing
2. **Grouping** réduit le bruit en regroupant les alertes similaires
3. **Inhibition** empêche les alertes redondantes
4. **Silences** permettent de désactiver temporairement des alertes
5. **Labels** sont essentiels pour le routing et le grouping
6. **Grafana** offre une interface unifiée pour gérer toutes les alertes

---

**🎉 Félicitations !** Vous maîtrisez maintenant l'alerting avec Prometheus et Grafana !

Passez au [Lab 2.4 - Dashboards Avancés](../Lab-2.4-Advanced-Dashboards/) pour approfondir vos compétences.
