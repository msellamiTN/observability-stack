# 🔍 Lab 2.2 : Tempo - Distributed Tracing

**Durée estimée** : 2 heures  
**Niveau** : Avancé  
**Prérequis** : Lab 1.4 (Prometheus), Lab 2.1 (Loki)

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce lab, vous serez capable de :

- ✅ Comprendre le distributed tracing et OpenTelemetry
- ✅ Configurer Tempo pour collecter des traces
- ✅ Instrumenter une application avec OpenTelemetry
- ✅ Visualiser des traces dans Grafana
- ✅ Corréler traces, logs et métriques
- ✅ Analyser les performances avec le tracing

---

## 📋 Prérequis

### Services Docker Requis

```bash
# Vérifier que les services sont démarrés
docker ps | grep -E "tempo|payment-api_instrumented|grafana"

# Devrait afficher :
# - tempo (ports 3200, 4317, 4318)
# - payment-api_instrumented (port 8888)
# - grafana (port 3000)
```

### Accès aux Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **Tempo** | http://localhost:3200 | - |
| **Payment API** | http://localhost:8888 | - |

---

## 📚 Partie 1 : Concepts du Tracing (30 min)

### Qu'est-ce que le Distributed Tracing ?

Le **tracing distribué** permet de suivre une requête à travers plusieurs services d'une architecture microservices.

### Terminologie

| Terme | Description | Exemple |
|-------|-------------|---------|
| **Trace** | Parcours complet d'une requête | Paiement de bout en bout |
| **Span** | Unité de travail dans une trace | Appel à la base de données |
| **Trace ID** | Identifiant unique de la trace | `a1b2c3d4e5f6` |
| **Span ID** | Identifiant unique du span | `1a2b3c4d` |
| **Parent Span** | Span appelant | Service API |
| **Child Span** | Span appelé | Requête SQL |

### Architecture d'une Trace

```
Trace ID: a1b2c3d4e5f6
│
├─ Span 1: HTTP POST /payment (200ms)
│  │
│  ├─ Span 2: Validate Payment (10ms)
│  │
│  ├─ Span 3: Database Query (50ms)
│  │  │
│  │  └─ Span 4: SQL SELECT (45ms)
│  │
│  └─ Span 5: External API Call (120ms)
│     │
│     └─ Span 6: HTTP GET /fraud-check (115ms)
```

### Les 3 Piliers de l'Observabilité

```
┌─────────────┐
│  MÉTRIQUES  │ ─── Quoi ? (CPU, Memory, Requests/s)
└─────────────┘

┌─────────────┐
│    LOGS     │ ─── Quand ? (Événements, Erreurs)
└─────────────┘

┌─────────────┐
│   TRACES    │ ─── Pourquoi ? (Latence, Dépendances)
└─────────────┘
```

### OpenTelemetry

**OpenTelemetry** est le standard open-source pour l'instrumentation :

- **Traces** : Distributed tracing
- **Metrics** : Métriques applicatives
- **Logs** : Logs structurés
- **Baggage** : Contexte propagé

### Architecture Tempo

```
┌──────────────────┐
│   Application    │
│  (Instrumented)  │
└────────┬─────────┘
         │ OTLP (gRPC/HTTP)
         ▼
┌──────────────────┐
│      Tempo       │
│   (Collector)    │
└────────┬─────────┘
         │ Store
         ▼
┌──────────────────┐
│  Object Storage  │
│ (Local/S3/MinIO) │
└──────────────────┘
         │ Query
         ▼
┌──────────────────┐
│     Grafana      │
│  (Visualization) │
└──────────────────┘
```

---

## 🔧 Partie 2 : Configuration Tempo (20 min)

### Vérifier la Configuration

```bash
# Voir la configuration Tempo
docker exec tempo cat /etc/tempo.yaml
```

### Configuration Tempo (Référence)

```yaml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318

ingester:
  trace_idle_period: 10s
  max_block_bytes: 1_000_000
  max_block_duration: 5m

compactor:
  compaction:
    block_retention: 1h

storage:
  trace:
    backend: local
    local:
      path: /var/tempo/traces
    wal:
      path: /var/tempo/wal
    pool:
      max_workers: 100
      queue_depth: 10000
```

### Ports Tempo

| Port | Protocole | Usage |
|------|-----------|-------|
| **3200** | HTTP | API Tempo |
| **4317** | gRPC | OTLP receiver (gRPC) |
| **4318** | HTTP | OTLP receiver (HTTP) |

### Tester Tempo

```bash
# Vérifier l'API
curl http://localhost:3200/status

# Devrait retourner du JSON avec le statut
```

---

## 🎨 Partie 3 : Application Instrumentée (30 min)

### Payment API Instrumentée

L'application `payment-api_instrumented` est déjà instrumentée avec OpenTelemetry.

### Vérifier l'Application

```bash
# Vérifier les logs
docker logs payment-api_instrumented --tail 50

# Tester l'API
curl http://localhost:8888/health
```

### Endpoints Disponibles

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Health check |
| `/api/payments` | GET | Liste des paiements |
| `/api/payments/{id}` | GET | Détail d'un paiement |
| `/api/payments` | POST | Créer un paiement |
| `/api/payments/process` | POST | Traiter un paiement |

### Générer des Traces

```powershell
# Windows PowerShell - Générer du trafic

# 1. Health check
Invoke-WebRequest -Uri http://localhost:8888/health

# 2. Créer un paiement
$body = @{
    amount = 100.50
    currency = "EUR"
    customerId = "CUST001"
    description = "Test payment"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:8888/api/payments `
    -Method Post -Body $body -ContentType "application/json"

# 3. Lister les paiements
Invoke-RestMethod -Uri http://localhost:8888/api/payments

# 4. Traiter un paiement
$processBody = @{
    paymentId = "PAY001"
    action = "approve"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:8888/api/payments/process `
    -Method Post -Body $processBody -ContentType "application/json"
```

### Script de Charge

```powershell
# generate-traces.ps1
Write-Host "🚀 Generating traces..." -ForegroundColor Cyan

1..50 | ForEach-Object {
    $amount = Get-Random -Minimum 10 -Maximum 1000
    
    $body = @{
        amount = $amount
        currency = "EUR"
        customerId = "CUST$(Get-Random -Minimum 1 -Maximum 100)"
        description = "Payment #$_"
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri http://localhost:8888/api/payments `
            -Method Post -Body $body -ContentType "application/json" | Out-Null
        Write-Host "  ✅ Payment #$_ created" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Payment #$_ failed" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 100
}

Write-Host "✅ Generated 50 traces!" -ForegroundColor Green
```

---

## 🔍 Partie 4 : Visualisation des Traces (40 min)

### Configurer la Datasource Tempo dans Grafana

#### 1. Accéder à Grafana

```
http://localhost:3000
```

#### 2. Ajouter Tempo comme Datasource

```
Configuration → Data sources → Add data source → Tempo
```

**Configuration** :
```yaml
Name: Tempo
URL: http://tempo:3200
```

**Trace to logs** (optionnel) :
```yaml
Data source: Loki
Tags: container, namespace
```

**Trace to metrics** (optionnel) :
```yaml
Data source: Prometheus
Tags: service_name, operation
```

#### 3. Sauvegarder et Tester

```
Save & test
```

### Explorer les Traces

#### 1. Accéder à l'Explorateur

```
Grafana → Explore → Datasource: Tempo
```

#### 2. Rechercher des Traces

**Par Service** :
```
Service: payment-api-instrumented
```

**Par Operation** :
```
Operation: POST /api/payments
```

**Par Durée** :
```
Min duration: 100ms
Max duration: 1s
```

**Par Tags** :
```
http.status_code = 200
http.method = POST
```

#### 3. Analyser une Trace

Une trace affiche :
- **Timeline** : Durée de chaque span
- **Service Map** : Dépendances entre services
- **Span Details** : Attributs, événements, logs
- **Trace ID** : Pour corrélation

### Attributs d'un Span

| Attribut | Description | Exemple |
|----------|-------------|---------|
| `service.name` | Nom du service | `payment-api` |
| `http.method` | Méthode HTTP | `POST` |
| `http.url` | URL appelée | `/api/payments` |
| `http.status_code` | Code de réponse | `200` |
| `db.system` | Type de BDD | `mssql` |
| `db.statement` | Requête SQL | `SELECT * FROM...` |
| `error` | Erreur présente | `true/false` |

---

## 🎯 Exercice Pratique 1 : Analyser les Traces (30 min)

### Objectif

Analyser les performances de l'API de paiement avec les traces.

### Étapes

#### 1. Générer du Trafic

```powershell
.\scripts\generate-traces.ps1
```

#### 2. Trouver la Trace la Plus Lente

```
Grafana → Explore → Tempo
Sort by: Duration (descending)
```

**Questions** :
- Quelle est la durée totale ?
- Quel span prend le plus de temps ?
- Y a-t-il des erreurs ?

#### 3. Analyser les Dépendances

Regardez le **Service Graph** :
- Quels services sont appelés ?
- Quel est le chemin critique ?

#### 4. Identifier les Goulots d'Étranglement

Pour chaque span lent :
- Regarder les attributs (`db.statement`, `http.url`)
- Vérifier les logs associés
- Identifier la cause (BDD, API externe, etc.)

### ✅ Critères de Réussite

- [ ] Vous pouvez visualiser les traces dans Grafana
- [ ] Vous identifiez les spans les plus lents
- [ ] Vous comprenez le parcours d'une requête
- [ ] Vous pouvez corréler traces et logs

---

## 🔗 Partie 5 : Corrélation Traces ↔ Logs ↔ Métriques (30 min)

### Concept

L'observabilité complète nécessite de corréler les 3 piliers :

```
Métrique élevée (latence)
    ↓
Trace spécifique (span lent)
    ↓
Logs détaillés (erreur SQL)
```

### Configuration de la Corrélation

#### 1. Traces → Logs

Dans la datasource Tempo :

```yaml
Trace to logs:
  Data source: Loki
  Tags:
    - key: container
      value: container
  Map tag names: Yes
  Span start/end shift: -1h / +1h
```

#### 2. Traces → Métriques

```yaml
Trace to metrics:
  Data source: Prometheus
  Tags:
    - key: service_name
      value: service
  Queries:
    - name: Request rate
      query: rate(http_requests_total{service="$__tags"}[5m])
    - name: Error rate
      query: rate(http_requests_total{service="$__tags",status=~"5.."}[5m])
```

#### 3. Logs → Traces

Dans les logs Loki, ajouter le Trace ID :

```logql
{container="payment-api_instrumented"} | json | line_format "{{.message}} [trace_id={{.trace_id}}]"
```

### Utilisation

#### Depuis une Trace

1. Cliquer sur un span
2. Cliquer sur **"Logs for this span"**
3. Voir les logs correspondants dans Loki

#### Depuis des Logs

1. Extraire le `trace_id` des logs
2. Cliquer sur le lien
3. Voir la trace complète dans Tempo

#### Depuis une Métrique

1. Panel Prometheus avec spike de latence
2. Cliquer sur **"View traces"**
3. Voir les traces de cette période

---

## 📊 Partie 6 : Dashboard de Tracing (20 min)

### Créer un Dashboard APM

#### Panel 1 : Request Rate

**Type** : Time series

**Query (Prometheus)** :
```promql
sum(rate(http_requests_total{service="payment-api"}[5m])) by (method, endpoint)
```

#### Panel 2 : Latency (P50, P95, P99)

**Type** : Time series

**Queries** :
```promql
# P50
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# P95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# P99
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
```

#### Panel 3 : Error Rate

**Type** : Stat

**Query** :
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

**Configuration** :
- Unit : Percent (0-100)
- Thresholds : 0 (green), 1 (yellow), 5 (red)

#### Panel 4 : Traces (Recent)

**Type** : Traces

**Query (Tempo)** :
```
Service: payment-api-instrumented
Limit: 20
```

#### Panel 5 : Service Map

**Type** : Node graph

**Query (Tempo)** :
```
Service graph query
```

---

## 🎯 Exercice Pratique 2 : Dashboard Complet (20 min)

### Objectif

Créer un dashboard APM (Application Performance Monitoring) complet.

### Structure

1. **Row 1 : Golden Signals**
   - Request Rate (Prometheus)
   - Latency P95 (Prometheus)
   - Error Rate (Prometheus)
   - Saturation (Prometheus)

2. **Row 2 : Traces**
   - Recent Traces (Tempo)
   - Slowest Traces (Tempo)
   - Failed Traces (Tempo)

3. **Row 3 : Service Map**
   - Dependencies (Tempo)
   - Call graph (Tempo)

### Variables

```yaml
# Service
Name: service
Type: Query
Datasource: Prometheus
Query: label_values(http_requests_total, service)

# Endpoint
Name: endpoint
Type: Query
Datasource: Prometheus
Query: label_values(http_requests_total{service="$service"}, endpoint)
```

### ✅ Critères de Réussite

- [ ] Dashboard avec 3 rows
- [ ] Métriques RED (Rate, Errors, Duration)
- [ ] Traces visibles et cliquables
- [ ] Service map fonctionnel
- [ ] Variables pour filtrer par service/endpoint

---

## 🚀 Partie 7 : Instrumentation Custom (Bonus)

### Exemple .NET (C#)

```csharp
using OpenTelemetry;
using OpenTelemetry.Trace;
using OpenTelemetry.Resources;

// Configuration
services.AddOpenTelemetry()
    .WithTracing(builder => builder
        .SetResourceBuilder(ResourceBuilder.CreateDefault()
            .AddService("payment-api"))
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation()
        .AddOtlpExporter(options =>
        {
            options.Endpoint = new Uri("http://tempo:4317");
        }));

// Créer un span custom
using var activity = ActivitySource.StartActivity("ProcessPayment");
activity?.SetTag("payment.id", paymentId);
activity?.SetTag("payment.amount", amount);

try
{
    // Logique métier
    var result = await ProcessPaymentAsync(paymentId);
    activity?.SetTag("payment.status", "success");
    return result;
}
catch (Exception ex)
{
    activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
    activity?.RecordException(ex);
    throw;
}
```

### Exemple Python

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configuration
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

otlp_exporter = OTLPSpanExporter(endpoint="http://tempo:4317")
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Créer un span
with tracer.start_as_current_span("process_payment") as span:
    span.set_attribute("payment.id", payment_id)
    span.set_attribute("payment.amount", amount)
    
    try:
        result = process_payment(payment_id)
        span.set_attribute("payment.status", "success")
        return result
    except Exception as e:
        span.set_status(trace.Status(trace.StatusCode.ERROR))
        span.record_exception(e)
        raise
```

---

## 📖 Ressources

### Documentation Officielle

- [Grafana Tempo](https://grafana.com/docs/tempo/latest/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [OTLP Specification](https://opentelemetry.io/docs/specs/otlp/)

### Guides

- [Distributed Tracing Best Practices](https://opentelemetry.io/docs/concepts/signals/traces/)
- [Tempo Configuration](https://grafana.com/docs/tempo/latest/configuration/)
- [OpenTelemetry .NET](https://opentelemetry.io/docs/languages/net/)

### Outils

- [Jaeger](https://www.jaegertracing.io/) - Alternative à Tempo
- [Zipkin](https://zipkin.io/) - Autre solution de tracing
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)

---

## ✅ Checklist de Validation

Avant de passer au lab suivant, assurez-vous de :

- [ ] Tempo est configuré et fonctionnel
- [ ] L'application instrumentée envoie des traces
- [ ] Vous pouvez visualiser les traces dans Grafana
- [ ] Vous comprenez la structure d'une trace (spans)
- [ ] Vous savez corréler traces, logs et métriques
- [ ] Vous avez créé un dashboard APM
- [ ] Vous pouvez identifier les goulots d'étranglement

---

## 🔙 Navigation

- [⬅️ Retour au Jour 2](../README.md)
- [➡️ Lab suivant : Lab 2.3 - Alerting](../Lab-2.3-Alerting/)
- [🏠 Accueil Formation](../../README-MAIN.md)

---

## 🎓 Points Clés à Retenir

1. **Tracing** = Suivre une requête à travers plusieurs services
2. **OpenTelemetry** = Standard pour l'instrumentation
3. **Tempo** = Backend de stockage léger pour les traces
4. **Span** = Unité de travail dans une trace
5. **Corrélation** = Lier traces, logs et métriques pour troubleshooting
6. **Service Map** = Visualiser les dépendances entre services
7. **Golden Signals** = Rate, Errors, Duration (RED)

---

**🎉 Félicitations !** Vous maîtrisez maintenant le distributed tracing avec Tempo !

Passez au [Lab 2.3 - Alerting](../Lab-2.3-Alerting/) pour configurer des alertes avancées.
