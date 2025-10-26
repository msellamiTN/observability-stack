# 💼 Lab 2.5 : Monitoring E-Banking - Cas Pratique

**Durée estimée** : 2 heures  
**Niveau** : Avancé  
**Prérequis** : Tous les labs précédents (Jour 1 + Jour 2)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Monitorer une application bancaire complète
- ✅ Créer des métriques métier (transactions, comptes, fraude)
- ✅ Construire un dashboard opérationnel complet
- ✅ Configurer des alertes métier critiques
- ✅ Corréler métriques, logs et traces
- ✅ Analyser les performances d'un système bancaire

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que tous les services sont démarrés
docker ps | grep -E "grafana|prometheus|influxdb|mssql|loki|tempo|ebanking"

# Devrait afficher :
# - grafana (port 3000)
# - prometheus (port 9090)
# - influxdb (port 8086)
# - mssql (port 1433)
# - loki (port 3100)
# - tempo (port 3200)
# - ebanking_metrics_exporter (port 9201)
# - payment-api_instrumented (port 8888)
```

### Accès aux Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Prometheus** | http://localhost:9090 | - |
| **InfluxDB** | http://localhost:8086 | admin / InfluxSecure123!Change@Me |
| **Payment API** | http://localhost:8888 | - |
| **EBanking Exporter** | http://localhost:9201/metrics | - |

---

## 📚 Partie 1 : Architecture E-Banking (20 min)

### Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────┐
│                    E-Banking System                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐      ┌──────────────┐                │
│  │   Frontend   │─────▶│  Payment API │                │
│  │   (Web/App)  │      │  (Port 8888) │                │
│  └──────────────┘      └───────┬──────┘                │
│                                 │                        │
│                        ┌────────┴────────┐              │
│                        │                 │              │
│                   ┌────▼─────┐    ┌─────▼────┐         │
│                   │  MS SQL  │    │ External │         │
│                   │ Database │    │   APIs   │         │
│                   └──────────┘    └──────────┘         │
│                                                          │
└─────────────────────────────────────────────────────────┘
                           │
                           │ Observability
                           ▼
┌─────────────────────────────────────────────────────────┐
│              Observability Stack                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Métriques:    Prometheus + InfluxDB                    │
│  Logs:         Loki                                      │
│  Traces:       Tempo                                     │
│  Visualisation: Grafana                                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Métriques Métier E-Banking

#### 1. Métriques Transactionnelles

| Métrique | Description | Type |
|----------|-------------|------|
| **Transactions/s** | Nombre de transactions par seconde | Counter |
| **Montant moyen** | Montant moyen des transactions | Gauge |
| **Taux de succès** | % de transactions réussies | Gauge |
| **Taux de rejet** | % de transactions rejetées | Gauge |
| **Délai de traitement** | Temps de traitement moyen | Histogram |

#### 2. Métriques de Comptes

| Métrique | Description | Type |
|----------|-------------|------|
| **Comptes actifs** | Nombre de comptes actifs | Gauge |
| **Solde total** | Solde total de tous les comptes | Gauge |
| **Nouveaux comptes** | Comptes créés par jour | Counter |
| **Comptes bloqués** | Comptes bloqués pour fraude | Gauge |

#### 3. Métriques de Fraude

| Métrique | Description | Type |
|----------|-------------|------|
| **Tentatives de fraude** | Nombre de tentatives détectées | Counter |
| **Taux de fraude** | % de transactions frauduleuses | Gauge |
| **Montant bloqué** | Montant total bloqué | Counter |
| **Faux positifs** | Transactions légitimes bloquées | Counter |

#### 4. Métriques Business

| Métrique | Description | Type |
|----------|-------------|------|
| **Revenu** | Revenu généré (frais) | Counter |
| **Coût opérationnel** | Coût des transactions | Counter |
| **Marge** | Revenu - Coût | Gauge |
| **Clients actifs** | Clients ayant fait une transaction | Gauge |

---

## 🔧 Partie 2 : EBanking Metrics Exporter (30 min)

### Vérifier l'Exporter

```bash
# Vérifier le statut
docker ps | grep ebanking_metrics_exporter

# Voir les métriques exposées
curl http://localhost:9201/metrics
```

### Métriques Exposées

```prometheus
# Transactions
ebanking_transactions_total{type="payment",status="success"} 1234
ebanking_transactions_total{type="payment",status="failed"} 56
ebanking_transactions_total{type="transfer",status="success"} 789

# Montants
ebanking_transaction_amount_total{currency="EUR"} 123456.78
ebanking_transaction_amount_avg{currency="EUR"} 156.32

# Comptes
ebanking_accounts_total{status="active"} 5432
ebanking_accounts_total{status="blocked"} 12
ebanking_accounts_balance_total{currency="EUR"} 9876543.21

# Fraude
ebanking_fraud_attempts_total 45
ebanking_fraud_blocked_amount_total{currency="EUR"} 12345.67

# Performance
ebanking_processing_duration_seconds_bucket{le="0.1"} 1000
ebanking_processing_duration_seconds_bucket{le="0.5"} 1800
ebanking_processing_duration_seconds_bucket{le="1.0"} 1950
ebanking_processing_duration_seconds_sum 1234.56
ebanking_processing_duration_seconds_count 2000

# Business
ebanking_revenue_total{currency="EUR"} 5678.90
ebanking_operational_cost_total{currency="EUR"} 2345.67
```

### Configurer Prometheus

Vérifiez que l'exporter est dans `prometheus/prometheus.yml` :

```yaml
scrape_configs:
  - job_name: 'ebanking'
    static_configs:
      - targets: ['ebanking_metrics_exporter:9200']
        labels:
          service: 'ebanking'
          environment: 'production'
```

### Tester dans Prometheus

```
http://localhost:9090/graph

# Requête test
ebanking_transactions_total
```

---

## 📊 Partie 3 : Dashboard E-Banking (60 min)

### Créer le Dashboard Principal

#### Row 1 : Vue d'Ensemble (KPIs)

**Panel 1.1 : Transactions/s**

**Type** : Stat

**Query** :
```promql
sum(rate(ebanking_transactions_total[5m]))
```

**Configuration** :
- Unit : ops/s
- Color : Green
- Sparkline : Show

**Panel 1.2 : Taux de Succès**

**Type** : Gauge

**Query** :
```promql
sum(rate(ebanking_transactions_total{status="success"}[5m])) 
/ 
sum(rate(ebanking_transactions_total[5m])) * 100
```

**Configuration** :
- Unit : Percent (0-100)
- Min : 0, Max : 100
- Thresholds : 
  - 95 (red)
  - 98 (yellow)
  - 99 (green)

**Panel 1.3 : Montant Moyen**

**Type** : Stat

**Query** :
```promql
ebanking_transaction_amount_avg{currency="EUR"}
```

**Configuration** :
- Unit : Currency (EUR)
- Decimals : 2

**Panel 1.4 : Comptes Actifs**

**Type** : Stat

**Query** :
```promql
ebanking_accounts_total{status="active"}
```

**Configuration** :
- Unit : short
- Color : Blue

#### Row 2 : Transactions

**Panel 2.1 : Volume de Transactions**

**Type** : Time series

**Queries** :
```promql
# Succès
sum(rate(ebanking_transactions_total{status="success"}[1m])) by (type)

# Échecs
sum(rate(ebanking_transactions_total{status="failed"}[1m])) by (type)
```

**Configuration** :
- Legend : `{{type}} - {{status}}`
- Stack : Normal
- Fill opacity : 30%

**Panel 2.2 : Répartition par Type**

**Type** : Pie chart

**Query** :
```promql
sum by (type) (increase(ebanking_transactions_total[1h]))
```

**Configuration** :
- Legend : Values + Percent
- Pie type : Donut

**Panel 2.3 : Latence (P50, P95, P99)**

**Type** : Time series

**Queries** :
```promql
# P50
histogram_quantile(0.50, rate(ebanking_processing_duration_seconds_bucket[5m]))

# P95
histogram_quantile(0.95, rate(ebanking_processing_duration_seconds_bucket[5m]))

# P99
histogram_quantile(0.99, rate(ebanking_processing_duration_seconds_bucket[5m]))
```

**Configuration** :
- Unit : seconds (s)
- Legend : P50, P95, P99

#### Row 3 : Fraude & Sécurité

**Panel 3.1 : Tentatives de Fraude**

**Type** : Time series

**Query** :
```promql
rate(ebanking_fraud_attempts_total[5m]) * 60
```

**Configuration** :
- Unit : /min
- Color : Red
- Alert : > 10/min

**Panel 3.2 : Montant Bloqué**

**Type** : Stat

**Query** :
```promql
increase(ebanking_fraud_blocked_amount_total[24h])
```

**Configuration** :
- Unit : Currency (EUR)
- Color : Red

**Panel 3.3 : Taux de Fraude**

**Type** : Gauge

**Query** :
```promql
rate(ebanking_fraud_attempts_total[5m]) 
/ 
sum(rate(ebanking_transactions_total[5m])) * 100
```

**Configuration** :
- Unit : Percent (0-100)
- Thresholds :
  - 0.1 (green)
  - 0.5 (yellow)
  - 1.0 (red)

#### Row 4 : Business Metrics

**Panel 4.1 : Revenu**

**Type** : Time series

**Query** :
```promql
rate(ebanking_revenue_total[5m]) * 3600 * 24
```

**Configuration** :
- Unit : Currency (EUR/day)
- Fill : Gradient

**Panel 4.2 : Marge**

**Type** : Stat

**Query** :
```promql
(increase(ebanking_revenue_total[24h]) - increase(ebanking_operational_cost_total[24h])) 
/ 
increase(ebanking_revenue_total[24h]) * 100
```

**Configuration** :
- Unit : Percent (0-100)
- Color mode : Value
- Thresholds :
  - 20 (red)
  - 40 (yellow)
  - 60 (green)

**Panel 4.3 : Clients Actifs**

**Type** : Time series

**Query** :
```promql
ebanking_active_customers
```

**Configuration** :
- Unit : short
- Color : Blue

#### Row 5 : Corrélation (Logs + Traces)

**Panel 5.1 : Logs d'Erreur**

**Type** : Logs

**Query (Loki)** :
```logql
{container="payment-api_instrumented"} |~ "error|ERROR|Error"
```

**Panel 5.2 : Traces Lentes**

**Type** : Traces

**Query (Tempo)** :
```
Service: payment-api-instrumented
Min duration: 500ms
```

### Variables de Dashboard

```yaml
# Période
Name: time_range
Type: Interval
Values: 5m, 15m, 1h, 6h, 24h
Default: 5m

# Type de transaction
Name: transaction_type
Type: Query
Datasource: Prometheus
Query: label_values(ebanking_transactions_total, type)
Multi-value: Yes
Include All: Yes

# Devise
Name: currency
Type: Query
Datasource: Prometheus
Query: label_values(ebanking_transaction_amount_total, currency)
Default: EUR
```

---

## 🎯 Exercice Pratique 1 : Dashboard Complet (40 min)

### Objectif

Créer le dashboard E-Banking complet avec tous les panels.

### Étapes

#### 1. Créer le Dashboard

```
Grafana → Dashboards → New Dashboard
```

#### 2. Ajouter les 5 Rows

- Row 1 : KPIs (4 panels)
- Row 2 : Transactions (3 panels)
- Row 3 : Fraude (3 panels)
- Row 4 : Business (3 panels)
- Row 5 : Corrélation (2 panels)

#### 3. Configurer les Variables

Ajouter les 3 variables (time_range, transaction_type, currency).

#### 4. Tester avec des Données

```powershell
# Générer des transactions
.\scripts\generate-ebanking-traffic.ps1
```

### ✅ Critères de Réussite

- [ ] Dashboard avec 5 rows et 15 panels
- [ ] Toutes les métriques affichées correctement
- [ ] Variables fonctionnelles
- [ ] Corrélation logs/traces visible
- [ ] Dashboard sauvegardé

---

## 🔔 Partie 4 : Alertes Métier (30 min)

### Alertes Critiques

#### Alerte 1 : Taux de Succès Faible

```yaml
alert: LowSuccessRate
expr: |
  sum(rate(ebanking_transactions_total{status="success"}[5m])) 
  / 
  sum(rate(ebanking_transactions_total[5m])) * 100 < 95
for: 5m
labels:
  severity: critical
  team: operations
annotations:
  summary: "Taux de succès des transactions faible"
  description: "Le taux de succès est de {{ $value }}% (seuil: 95%)"
```

#### Alerte 2 : Fraude Élevée

```yaml
alert: HighFraudRate
expr: |
  rate(ebanking_fraud_attempts_total[5m]) * 60 > 10
for: 2m
labels:
  severity: critical
  team: security
annotations:
  summary: "Taux de fraude élevé"
  description: "{{ $value }} tentatives de fraude par minute détectées"
```

#### Alerte 3 : Latence Élevée

```yaml
alert: HighLatency
expr: |
  histogram_quantile(0.95, 
    rate(ebanking_processing_duration_seconds_bucket[5m])
  ) > 1
for: 5m
labels:
  severity: warning
  team: performance
annotations:
  summary: "Latence P95 élevée"
  description: "La latence P95 est de {{ $value }}s (seuil: 1s)"
```

#### Alerte 4 : Comptes Bloqués

```yaml
alert: TooManyBlockedAccounts
expr: |
  ebanking_accounts_total{status="blocked"} > 50
for: 10m
labels:
  severity: warning
  team: compliance
annotations:
  summary: "Trop de comptes bloqués"
  description: "{{ $value }} comptes sont actuellement bloqués"
```

#### Alerte 5 : Marge Faible

```yaml
alert: LowMargin
expr: |
  (increase(ebanking_revenue_total[1h]) - increase(ebanking_operational_cost_total[1h])) 
  / 
  increase(ebanking_revenue_total[1h]) * 100 < 30
for: 1h
labels:
  severity: warning
  team: finance
annotations:
  summary: "Marge opérationnelle faible"
  description: "La marge est de {{ $value }}% (seuil: 30%)"
```

### Configurer les Alertes

Ajoutez ces règles dans `prometheus/rules/ebanking-alerts.yml` :

```yaml
groups:
  - name: ebanking_alerts
    interval: 30s
    rules:
      # ... (coller les 5 alertes ci-dessus)
```

### Redémarrer Prometheus

```bash
docker-compose restart prometheus
```

---

## 📈 Partie 5 : Analyse de Performance (20 min)

### Scénarios d'Analyse

#### Scénario 1 : Pic de Trafic

**Symptômes** :
- Transactions/s augmente soudainement
- Latence P95 augmente
- Taux de succès diminue

**Analyse** :
1. Vérifier le volume dans le dashboard
2. Regarder les traces lentes (Tempo)
3. Identifier le goulot (DB, API externe)
4. Vérifier les logs d'erreur (Loki)

#### Scénario 2 : Attaque par Fraude

**Symptômes** :
- Tentatives de fraude en hausse
- Montant bloqué augmente
- Comptes bloqués augmentent

**Analyse** :
1. Dashboard fraude : identifier le pattern
2. Logs : voir les IPs/users suspects
3. Traces : analyser les transactions frauduleuses
4. Action : ajuster les règles de détection

#### Scénario 3 : Dégradation Progressive

**Symptômes** :
- Latence augmente lentement
- Taux de succès diminue progressivement
- Marge diminue

**Analyse** :
1. Comparer avec période précédente
2. Corréler avec métriques système (CPU, Memory)
3. Vérifier les requêtes SQL lentes
4. Analyser les dépendances externes

---

## 📖 Ressources

### Documentation

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [RED Method](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/)
- [USE Method](http://www.brendangregg.com/usemethod.html)

### Exemples de Dashboards

- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [Awesome Prometheus](https://github.com/roaldnefs/awesome-prometheus)

---

## ✅ Checklist de Validation

Avant de terminer la formation, assurez-vous de :

- [ ] Dashboard E-Banking complet créé
- [ ] Toutes les métriques métier affichées
- [ ] Alertes critiques configurées
- [ ] Corrélation logs/traces/métriques fonctionnelle
- [ ] Vous pouvez analyser un incident de bout en bout
- [ ] Vous comprenez les métriques business
- [ ] Dashboard sauvegardé et exporté

---

## 🔙 Navigation

- [⬅️ Retour au Jour 2](../README.md)
- [➡️ Jour suivant : Jour 3 - Production](../../Day%203/README.md)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

## 🎓 Points Clés à Retenir

1. **Métriques Métier** : Au-delà des métriques techniques, monitorer le business
2. **RED Method** : Rate, Errors, Duration pour les services
3. **Corrélation** : Lier métriques, logs et traces pour troubleshooting
4. **Alertes Métier** : Alerter sur ce qui impacte le business
5. **Dashboards Opérationnels** : Vue d'ensemble + détails
6. **Analyse de Performance** : Identifier rapidement les goulots
7. **Observabilité Complète** : Les 3 piliers ensemble sont plus puissants

---

## 🎉 Félicitations !

Vous avez terminé le **Jour 2** de la formation !

Vous maîtrisez maintenant :
- ✅ L'agrégation de logs avec Loki
- ✅ Le distributed tracing avec Tempo
- ✅ L'alerting avancé avec Alertmanager
- ✅ Les dashboards avancés avec variables
- ✅ Le monitoring d'une application bancaire complète

**Prochaine étape** : [Jour 3 - Optimisation et Production](../../Day%203/README.md)

---

**💼 Cas Pratique Terminé !** Vous êtes maintenant prêt à monitorer des applications en production !
