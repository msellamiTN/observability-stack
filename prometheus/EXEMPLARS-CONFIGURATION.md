# Configuration des Exemplars dans Prometheus

## Qu'est-ce qu'un Exemplar?

Un **exemplar** est un échantillon spécifique d'une métrique qui contient des métadonnées supplémentaires, notamment un **trace_id**. Cela permet de créer un lien direct entre les métriques et les traces distribuées.

### Exemple d'Exemplar

```
http_request_duration_seconds_bucket{le="0.5"} 145 # {trace_id="4bf92f3577b34da6a3ce929d0e0e4736"} 0.234
```

Dans cet exemple:
- La métrique: `http_request_duration_seconds_bucket`
- La valeur: `145` (nombre de requêtes)
- L'exemplar: `trace_id="4bf92f3577b34da6a3ce929d0e0e4736"` avec une durée de `0.234s`

## Configuration dans Prometheus

### 1. Configuration Globale

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'oddo-ebanking-prod'
    env: 'production'
  
  # Enable exemplar storage for trace correlation
  scrape_timeout: 10s
```

### 2. Scrape Job pour payment-api-instrumented

```yaml
- job_name: 'payment-api-instrumented'
  metrics_path: '/metrics'
  scrape_interval: 10s
  scrape_timeout: 5s
  # Enable exemplar collection for trace correlation
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: '.*'
      action: keep
  static_configs:
    - targets: ['payment-api_instrumented:8888']
      labels:
        service: 'payment-api-instrumented'
        namespace: 'ebanking.observability'
        environment: 'production'
        app_type: 'instrumented-demo'
```

**Points clés:**
- `scrape_interval: 10s` - Collecte fréquente pour capturer les exemplars
- Labels supplémentaires pour faciliter le filtrage dans Grafana
- Les exemplars sont automatiquement collectés si l'endpoint les expose

### 3. Scrape Job pour Tempo

```yaml
- job_name: 'tempo'
  metrics_path: '/metrics'
  scrape_interval: 15s
  scrape_timeout: 10s
  static_configs:
    - targets: ['tempo:3200']
      labels:
        service: 'tempo'
        component: 'tracing-backend'
```

Tempo génère des métriques avec exemplars via:
- **Service Graphs**: Métriques de relations entre services
- **Span Metrics**: Métriques dérivées des spans

## Configuration dans OpenTelemetry (.NET)

Le service `payment-api-instrumented` est configuré pour exporter des exemplars:

```csharp
.WithMetrics(metrics => metrics
    .AddAspNetCoreInstrumentation()
    .AddHttpClientInstrumentation()
    .AddRuntimeInstrumentation()
    .AddProcessInstrumentation()
    .AddMeter("PaymentApi")
    .AddPrometheusExporter());  // Exporte avec exemplars
```

L'exporteur Prometheus d'OpenTelemetry ajoute automatiquement les `trace_id` aux exemplars.

## Vérification des Exemplars

### 1. Vérifier l'endpoint Prometheus du service

```bash
curl http://localhost:8888/metrics | grep -A 2 "trace_id"
```

Vous devriez voir des lignes comme:
```
http_server_duration_seconds_bucket{...} 42 # {trace_id="abc123..."} 0.156
```

### 2. Dans Prometheus UI

1. Accéder à `http://localhost:9090`
2. Aller dans **Status > Targets**
3. Vérifier que `payment-api-instrumented` est **UP**
4. Exécuter une requête:
   ```promql
   rate(http_server_duration_seconds_count[5m])
   ```
5. Dans le graphique, cliquer sur un point de données
6. Si des exemplars sont disponibles, un bouton "Query with exemplar" apparaît

### 3. Dans Grafana

1. Créer un dashboard avec une requête Prometheus
2. Dans les options du panel, activer **"Exemplars"**
3. Configurer la datasource Tempo pour la corrélation
4. Les exemplars apparaîtront comme des points sur le graphique
5. Cliquer sur un exemplar ouvre la trace correspondante dans Tempo

## Configuration de la Datasource Grafana

Pour activer la corrélation metrics-to-traces dans Grafana:

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    jsonData:
      # Enable exemplar support
      exemplarTraceIdDestinations:
        - name: trace_id
          datasourceUid: tempo  # UID de la datasource Tempo
```

## Métriques avec Exemplars

### Métriques OpenTelemetry

Les métriques suivantes du service `payment-api-instrumented` incluent des exemplars:

1. **HTTP Server Metrics**
   ```promql
   http_server_duration_seconds_bucket
   http_server_duration_seconds_count
   http_server_duration_seconds_sum
   ```

2. **HTTP Client Metrics**
   ```promql
   http_client_duration_seconds_bucket
   http_client_duration_seconds_count
   ```

3. **Runtime Metrics** (sans exemplars)
   ```promql
   process_runtime_dotnet_gc_collections_count
   process_runtime_dotnet_gc_heap_size_bytes
   ```

### Métriques Tempo (Service Graphs)

Tempo génère des métriques avec exemplars via le remote_write:

1. **Service Graph Metrics**
   ```promql
   traces_service_graph_request_total
   traces_service_graph_request_failed_total
   traces_service_graph_request_server_seconds_bucket
   traces_service_graph_request_client_seconds_bucket
   ```

2. **Span Metrics**
   ```promql
   traces_spanmetrics_latency_bucket
   traces_spanmetrics_calls_total
   ```

## Requêtes PromQL avec Exemplars

### Exemple 1: Latence P95 avec exemplars

```promql
histogram_quantile(0.95,
  rate(http_server_duration_seconds_bucket{
    service="payment-api-instrumented"
  }[5m])
)
```

### Exemple 2: Taux d'erreur avec exemplars

```promql
rate(http_server_duration_seconds_count{
  service="payment-api-instrumented",
  http_status_code=~"5.."
}[5m])
```

### Exemple 3: Service Graph - Requêtes entre services

```promql
rate(traces_service_graph_request_total{
  client="payment-api-instrumented"
}[5m])
```

## Flux de Corrélation Metrics → Traces

```
┌─────────────────────────────────────────────────────────────┐
│  1. Application génère une trace avec trace_id             │
│     payment-api-instrumented: trace_id="abc123..."          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ├──────────────────┬─────────────────────┐
                     │                  │                     │
                     ▼                  ▼                     ▼
         ┌───────────────────┐  ┌──────────────┐  ┌─────────────────┐
         │  Trace → Tempo    │  │ Metrics →    │  │ Logs → Loki     │
         │  (OTLP gRPC)      │  │ Prometheus   │  │ (Promtail)      │
         │                   │  │ avec         │  │ avec trace_id   │
         │  Stocke la trace  │  │ exemplars    │  │ dans le context │
         └───────────────────┘  └──────┬───────┘  └─────────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │  Exemplar stocké:       │
                          │  {trace_id="abc123..."}  │
                          │  avec métrique          │
                          └────────────┬────────────┘
                                       │
                                       ▼
                          ┌─────────────────────────┐
                          │  Grafana Dashboard      │
                          │  - Affiche métrique     │
                          │  - Affiche exemplar     │
                          │  - Click → Ouvre trace  │
                          │    dans Tempo           │
                          └─────────────────────────┘
```

## Dépannage

### Problème: Pas d'exemplars visibles

**Causes possibles:**

1. **Le service n'exporte pas d'exemplars**
   ```bash
   # Vérifier l'endpoint metrics
   curl http://localhost:8888/metrics | grep trace_id
   ```
   Si aucun résultat, vérifier la configuration OpenTelemetry.

2. **Prometheus ne collecte pas les exemplars**
   - Vérifier que le scrape job est configuré
   - Vérifier les logs Prometheus: `docker logs prometheus`

3. **Grafana n'affiche pas les exemplars**
   - Vérifier la configuration de la datasource Prometheus
   - Activer "Exemplars" dans les options du panel
   - Vérifier que la datasource Tempo est configurée

4. **Pas de traces générées**
   - Générer du trafic vers l'API: `curl http://localhost:8888/health`
   - Vérifier que Tempo reçoit les traces

### Vérification de la configuration

```bash
# 1. Vérifier que Prometheus scrape le service
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="payment-api-instrumented")'

# 2. Vérifier les métriques dans Prometheus
curl 'http://localhost:9090/api/v1/query?query=http_server_duration_seconds_count{service="payment-api-instrumented"}'

# 3. Vérifier les traces dans Tempo
curl http://localhost:3200/api/search?tags=service.name=payment-api-instrumented
```

## Meilleures Pratiques

1. **Fréquence de scrape**: 10-15s pour capturer suffisamment d'exemplars
2. **Rétention**: Les exemplars sont stockés avec les métriques
3. **Cardinalité**: Les exemplars n'augmentent pas la cardinalité des métriques
4. **Sampling**: Prometheus stocke un nombre limité d'exemplars par série temporelle
5. **Labels**: Utiliser des labels cohérents entre métriques et traces

## Ressources

- [OpenTelemetry Exemplars Specification](https://opentelemetry.io/docs/specs/otel/metrics/data-model/#exemplars)
- [Prometheus Exemplars Documentation](https://prometheus.io/docs/prometheus/latest/feature_flags/#exemplars-storage)
- [Grafana Exemplars Guide](https://grafana.com/docs/grafana/latest/fundamentals/exemplars/)
