# 🔍 Payment API - Enhanced OpenTelemetry Instrumentation

> **Version:** 2.0.0  
> **Last Updated:** October 26, 2025  
> **OpenTelemetry:** v1.10.0

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Instrumentation Details](#instrumentation-details)
- [Logging Strategy](#logging-strategy)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This Payment API is fully instrumented with **OpenTelemetry** for comprehensive observability across the three pillars:

- **📊 Metrics** - Prometheus metrics for monitoring
- **📝 Logs** - Structured JSON logs for Loki
- **🔍 Traces** - Distributed tracing with Tempo

### Key Enhancements

✅ **Auto-detection** - Container, host, and process resource detectors  
✅ **Shared Volumes** - Logs written to `/var/log/payment-api` for Loki/Promtail  
✅ **Rich Context** - Kubernetes/OpenShift metadata injection  
✅ **Advanced Tracing** - Exception tracking, custom enrichment  
✅ **Optimized Metrics** - Custom histogram buckets for latency  
✅ **Async Logging** - Non-blocking file writes with Serilog.Async

---

## 🚀 Features

### OpenTelemetry Instrumentation

| Component | Status | Description |
|-----------|--------|-------------|
| **ASP.NET Core** | ✅ | HTTP request/response tracing |
| **HTTP Client** | ✅ | Outbound HTTP calls tracing |
| **SQL Client** | ✅ | Database query tracing |
| **gRPC** | ✅ | gRPC client instrumentation |
| **Entity Framework Core** | ✅ | EF Core query tracing |
| **Runtime Metrics** | ✅ | .NET runtime metrics |
| **Process Metrics** | ✅ | Process CPU, memory metrics |

### Resource Detectors

| Detector | Purpose |
|----------|---------|
| **ContainerResourceDetector** | Auto-detects container ID, name |
| **HostDetector** | Auto-detects host name, architecture |
| **ProcessDetector** | Auto-detects process ID, command |

### Logging Sinks

| Sink | Format | Destination |
|------|--------|-------------|
| **Console** | Compact JSON | stdout (Promtail) |
| **File** | Compact JSON | `/var/log/payment-api/*.log` (Loki) |
| **Async** | Buffered | Non-blocking writes |

---

## 🏗️ Architecture

### Observability Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PAYMENT API POD                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Application Code                                     │  │
│  │  • Controllers                                        │  │
│  │  • Services                                           │  │
│  │  • Business Logic                                     │  │
│  └───────┬──────────────────────────────────────────────┘  │
│          │                                                  │
│  ┌───────▼──────────────────────────────────────────────┐  │
│  │  OpenTelemetry SDK                                    │  │
│  │  • Resource Detectors (Container, Host, Process)     │  │
│  │  • Instrumentation (ASP.NET, HTTP, SQL, gRPC, EF)    │  │
│  │  • Batch Processors                                   │  │
│  └───┬──────────────┬──────────────┬───────────────────┘  │
│      │              │              │                       │
│  ┌───▼────┐    ┌───▼────┐    ┌───▼────┐                  │
│  │ Traces │    │Metrics │    │  Logs  │                  │
│  │  OTLP  │    │Prom    │    │Serilog │                  │
│  └───┬────┘    └───┬────┘    └───┬────┘                  │
│      │             │              │                       │
│      │             │         ┌────▼──────┐               │
│      │             │         │  Console  │               │
│      │             │         │  (stdout) │               │
│      │             │         └────┬──────┘               │
│      │             │              │                       │
│      │             │         ┌────▼──────────────┐       │
│      │             │         │  File (Async)     │       │
│      │             │         │  /var/log/        │       │
│      │             │         │  payment-api/     │       │
│      │             │         └────┬──────────────┘       │
│      │             │              │                       │
└──────┼─────────────┼──────────────┼───────────────────────┘
       │             │              │
       │             │         ┌────▼──────────────┐
       │             │         │   Shared Volume   │
       │             │         │   (emptyDir)      │
       │             │         └────┬──────────────┘
       │             │              │
   ┌───▼────┐    ┌──▼───┐     ┌───▼────────┐
   │ TEMPO  │    │PROM  │     │  PROMTAIL  │
   │ :4317  │    │:9090 │     │  (sidecar) │
   └────────┘    └──────┘     └─────┬──────┘
                                     │
                                 ┌───▼────┐
                                 │  LOKI  │
                                 │  :3100 │
                                 └────────┘
```

---

## 🔧 Instrumentation Details

### 1. Traces Configuration

**Endpoint:** `http://tempo:4317` (OTLP gRPC)

**Features:**
- ✅ Always-on sampling (100% traces captured)
- ✅ Batch export (512 spans per batch)
- ✅ Exception recording with stack traces
- ✅ HTTP request/response enrichment
- ✅ Client IP and User-Agent tracking
- ✅ SQL statement capture
- ✅ Error status on exceptions

**Custom Enrichment:**

```csharp
// HTTP Request
activity.SetTag("http.request.body.size", httpRequest.ContentLength);
activity.SetTag("http.request.headers.user_agent", userAgent);
activity.SetTag("http.client_ip", clientIp);

// HTTP Response
activity.SetTag("http.response.body.size", httpResponse.ContentLength);

// Exceptions
activity.SetTag("exception.type", exception.GetType().Name);
activity.SetTag("exception.message", exception.Message);
activity.SetTag("exception.stacktrace", exception.StackTrace);
```

**Batch Processor Settings:**

```yaml
MaxQueueSize: 2048
ScheduledDelayMilliseconds: 5000
ExporterTimeoutMilliseconds: 30000
MaxExportBatchSize: 512
```

### 2. Metrics Configuration

**Endpoint:** `/metrics` (Prometheus scrape)

**Metrics Collected:**

**ASP.NET Core:**
- `http.server.request.duration` - Request duration histogram
- `http.server.active_requests` - Active requests gauge
- `http.server.request.count` - Total requests counter

**HTTP Client:**
- `http.client.request.duration` - Outbound request duration
- `http.client.request.count` - Outbound request count

**Runtime:**
- `process.runtime.dotnet.gc.collections.count` - GC collections
- `process.runtime.dotnet.gc.heap.size` - Heap size
- `process.runtime.dotnet.thread_pool.threads.count` - Thread pool

**Process:**
- `process.cpu.time` - CPU time
- `process.memory.usage` - Memory usage
- `process.memory.virtual` - Virtual memory

**Custom Histogram Buckets:**

```csharp
Boundaries: [0, 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]
// Optimized for API latency (milliseconds to seconds)
```

### 3. Resource Attributes

**Auto-Detected:**
- `container.id` - Container ID
- `container.name` - Container name
- `host.name` - Host name
- `host.arch` - Architecture (x64, arm64)
- `process.pid` - Process ID
- `process.executable.name` - Executable name
- `process.runtime.name` - Runtime (.NET)
- `process.runtime.version` - Runtime version (8.0.x)

**Custom Attributes:**

```yaml
# Service
service.name: payment-api-instrumented
service.version: 1.0.0
service.namespace: ebanking.observability
service.instance.id: <pod-name>

# Kubernetes/OpenShift
k8s.pod.name: <pod-name>
k8s.pod.namespace: <namespace>
k8s.node.name: <node-name>
k8s.deployment.name: payment-api
k8s.container.name: payment-api

# Deployment
deployment.environment: production
deployment.environment.type: openshift

# Cloud
cloud.platform: openshift
cloud.provider: redhat

# Application
app.team: platform-engineering
app.owner: observability-team
app.tier: backend
app.type: instrumented-demo
app.purpose: observability-testing
```

---

## 📝 Logging Strategy

### Dual-Sink Architecture

**1. Console Sink (stdout)**
- **Format:** Compact JSON
- **Destination:** stdout → Promtail (DaemonSet)
- **Purpose:** Real-time log streaming
- **Always Enabled:** Yes

**2. File Sink (Shared Volume)**
- **Format:** Compact JSON
- **Destination:** `/var/log/payment-api/payment-api-YYYYMMDD.log`
- **Purpose:** Persistent logs for Loki
- **Enabled:** Via `ENABLE_FILE_LOGGING=true`
- **Async:** Yes (non-blocking)

### Log Enrichment

**Standard Fields:**
```json
{
  "@t": "2025-10-26T16:30:00.123Z",
  "@mt": "Payment {PaymentId} created successfully",
  "@l": "Information",
  "PaymentId": "pay_123",
  "ServiceName": "payment-api-instrumented",
  "ServiceVersion": "1.0.0",
  "ServiceNamespace": "ebanking.observability",
  "DeploymentEnvironment": "Production",
  "ContainerId": "payment-api-7d8f9b-xyz",
  "HostType": "container",
  "PodName": "payment-api-7d8f9b-xyz",
  "PodNamespace": "your-namespace",
  "NodeName": "worker-node-1",
  "MachineName": "payment-api-7d8f9b-xyz",
  "EnvironmentName": "Production",
  "ThreadId": 42,
  "ThreadName": ".NET ThreadPool Worker"
}
```

### File Rotation

```yaml
Rolling Interval: Daily
Retained Files: 7 days
File Size Limit: 100 MB
Roll on Size Limit: Yes
Shared: Yes (multi-process safe)
Flush Interval: 1 second
```

### Log Levels

```yaml
Default: Information
Microsoft: Warning
Microsoft.AspNetCore: Warning
Microsoft.AspNetCore.Hosting.Diagnostics: Warning
System.Net.Http.HttpClient: Warning
OpenTelemetry: Debug (for troubleshooting)
```

---

## 🚀 Deployment

### Environment Variables

**Required:**

```yaml
# OpenTelemetry
OTEL_SERVICE_NAME: payment-api-instrumented
OTEL_EXPORTER_OTLP_ENDPOINT: http://tempo:4317

# Application
ASPNETCORE_URLS: http://+:8888
ASPNETCORE_ENVIRONMENT: Production
```

**Optional (Logging):**

```yaml
# Enable file logging to shared volume
ENABLE_FILE_LOGGING: "true"
LOG_DIRECTORY: /var/log/payment-api
```

**Optional (Kubernetes Metadata):**

```yaml
# Injected via Downward API
POD_NAME: $(metadata.name)
POD_NAMESPACE: $(metadata.namespace)
NODE_NAME: $(spec.nodeName)
```

### Kubernetes Manifest Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  template:
    spec:
      containers:
      - name: payment-api
        image: payment-api-instrumented:2.0.0
        env:
        - name: ENABLE_FILE_LOGGING
          value: "true"
        - name: LOG_DIRECTORY
          value: /var/log/payment-api
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: logs
          mountPath: /var/log/payment-api
          
      # Promtail sidecar for log collection
      - name: promtail
        image: grafana/promtail:2.9.0
        args:
        - -config.file=/etc/promtail/promtail.yaml
        volumeMounts:
        - name: logs
          mountPath: /var/log/payment-api
          readOnly: true
        - name: promtail-config
          mountPath: /etc/promtail
          
      volumes:
      - name: logs
        emptyDir: {}
      - name: promtail-config
        configMap:
          name: promtail-config
```

### Promtail Configuration

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
      grpc_listen_port: 0
    
    positions:
      filename: /tmp/positions.yaml
    
    clients:
      - url: http://loki:3100/loki/api/v1/push
    
    scrape_configs:
      - job_name: payment-api-logs
        static_configs:
          - targets:
              - localhost
            labels:
              job: payment-api
              app: payment-api-instrumented
              __path__: /var/log/payment-api/*.log
        
        pipeline_stages:
          # Parse JSON logs
          - json:
              expressions:
                timestamp: "@t"
                level: "@l"
                message: "@mt"
                service_name: ServiceName
                pod_name: PodName
                pod_namespace: PodNamespace
                
          # Extract timestamp
          - timestamp:
              source: timestamp
              format: RFC3339Nano
              
          # Set labels
          - labels:
              level:
              service_name:
              pod_name:
              pod_namespace:
```

---

## 📊 Monitoring

### Grafana Dashboards

**1. Application Overview**
- Request rate, error rate, latency (RED metrics)
- Active requests
- HTTP status codes distribution

**2. Traces**
- Trace search by service, operation
- Trace timeline visualization
- Span details with tags

**3. Logs**
- Log search with LogQL
- Log correlation with traces
- Error logs filtering

**4. Runtime Metrics**
- GC collections, heap size
- Thread pool threads
- CPU and memory usage

### Example Queries

**PromQL (Metrics):**

```promql
# Request rate
rate(http_server_request_count_total[5m])

# Error rate
rate(http_server_request_count_total{http_status_code=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))
```

**LogQL (Logs):**

```logql
# All logs from payment-api
{app="payment-api-instrumented"}

# Error logs only
{app="payment-api-instrumented"} |= "Error"

# Logs for specific payment
{app="payment-api-instrumented"} | json | PaymentId="pay_123"
```

**TraceQL (Traces):**

```traceql
# Find traces with errors
{ status = error }

# Find slow traces
{ duration > 1s }

# Find traces for specific endpoint
{ http.route = "/api/payments" }
```

---

## 🐛 Troubleshooting

### Logs Not Appearing in Loki

**Check 1: File logging enabled?**

```bash
oc exec deployment/payment-api -- env | grep ENABLE_FILE_LOGGING
# Should return: ENABLE_FILE_LOGGING=true
```

**Check 2: Log files created?**

```bash
oc exec deployment/payment-api -- ls -la /var/log/payment-api/
# Should show: payment-api-YYYYMMDD.log
```

**Check 3: Promtail running?**

```bash
oc get pods -l app=payment-api
# Should show 2/2 containers running
```

**Check 4: Promtail logs**

```bash
oc logs deployment/payment-api -c promtail
# Check for errors
```

### Traces Not Appearing in Tempo

**Check 1: OTLP endpoint configured?**

```bash
oc logs deployment/payment-api | grep "OTLP Trace Exporter"
# Should show: OTLP Trace Exporter configured with endpoint: http://tempo:4317
```

**Check 2: Tempo reachable?**

```bash
oc exec deployment/payment-api -- curl -v http://tempo:4317
```

**Check 3: Traces being created?**

```bash
oc logs deployment/payment-api | grep "Activity"
# Should show trace activity logs
```

### Metrics Not Scraped by Prometheus

**Check 1: /metrics endpoint accessible?**

```bash
curl http://$(oc get route payment-api -o jsonpath='{.spec.host}')/metrics
# Should return Prometheus metrics
```

**Check 2: Prometheus scrape config?**

```bash
oc get cm prometheus-config -o yaml | grep payment-api
```

---

## 📚 References

- [OpenTelemetry .NET](https://github.com/open-telemetry/opentelemetry-dotnet)
- [OpenTelemetry .NET Auto-Instrumentation](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation)
- [Serilog](https://serilog.net/)
- [Grafana Loki](https://grafana.com/docs/loki/)
- [Grafana Tempo](https://grafana.com/docs/tempo/)
- [Prometheus](https://prometheus.io/docs/)

---

**🎉 Happy Observing! 📊📝🔍**
