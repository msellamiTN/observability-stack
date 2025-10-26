# ============================================
# Payment API - OpenShift Deployment Test
# ============================================
# Tests the enhanced Payment API with:
# - OpenTelemetry instrumentation
# - Shared volume logging for Loki
# - Promtail sidecar
# ============================================

param(
    [string]$Namespace = $env:NAMESPACE,
    [switch]$SkipBuild,
    [switch]$CleanFirst
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Header { Write-Host "`n=== $args ===" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Yellow }

Write-Header "Payment API - OpenShift Deployment Test"

# Check if logged in to OpenShift
Write-Info "Checking OpenShift connection..."
try {
    $currentProject = oc project -q 2>$null
    Write-Success "Connected to OpenShift. Current project: $currentProject"
    
    if ([string]::IsNullOrEmpty($Namespace)) {
        $Namespace = $currentProject
        Write-Info "Using current namespace: $Namespace"
    }
} catch {
    Write-Error "Not logged in to OpenShift. Please run: oc login"
    exit 1
}

# Set namespace
Write-Info "Setting namespace to: $Namespace"
oc project $Namespace

# Clean up existing resources if requested
if ($CleanFirst) {
    Write-Header "Cleaning up existing resources"
    
    Write-Info "Deleting existing deployment..."
    oc delete deployment payment-api --ignore-not-found=true
    
    Write-Info "Deleting existing service..."
    oc delete service payment-api --ignore-not-found=true
    
    Write-Info "Deleting existing route..."
    oc delete route payment-api --ignore-not-found=true
    
    Write-Info "Deleting existing configmap..."
    oc delete configmap promtail-config --ignore-not-found=true
    
    Write-Info "Waiting for cleanup to complete..."
    Start-Sleep -Seconds 5
    
    Write-Success "Cleanup completed"
}

# Build and push image (if not skipped)
if (-not $SkipBuild) {
    Write-Header "Building Docker Image"
    
    Write-Info "Building payment-api-instrumented:2.0.0..."
    docker build -t payment-api-instrumented:2.0.0 .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed"
        exit 1
    }
    
    Write-Success "Docker image built successfully"
    
    # Tag for OpenShift internal registry
    Write-Info "Tagging image for OpenShift registry..."
    $registryUrl = "image-registry.openshift-image-registry.svc:5000"
    $imageTag = "${registryUrl}/${Namespace}/payment-api-instrumented:2.0.0"
    
    docker tag payment-api-instrumented:2.0.0 $imageTag
    
    Write-Info "Logging in to OpenShift registry..."
    $token = oc whoami -t
    docker login -u $(oc whoami) -p $token $registryUrl
    
    Write-Info "Pushing image to OpenShift registry..."
    docker push $imageTag
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker push failed"
        exit 1
    }
    
    Write-Success "Image pushed to OpenShift registry"
} else {
    Write-Info "Skipping build (using existing image)"
}

# Create Promtail ConfigMap
Write-Header "Creating Promtail ConfigMap"

# Create temporary file for ConfigMap
$tempConfigMap = [System.IO.Path]::GetTempFileName()
$promtailConfigContent = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
  namespace: ${Namespace}
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
      grpc_listen_port: 0
    
    positions:
      filename: /tmp/positions.yaml
    
    clients:
      - url: http://loki:3100/loki/api/v1/push
        tenant_id: payment-api
    
    scrape_configs:
      - job_name: payment-api-logs
        static_configs:
          - targets:
              - localhost
            labels:
              job: payment-api
              app: payment-api-instrumented
              namespace: ${Namespace}
              __path__: /var/log/payment-api/*.log
        
        pipeline_stages:
          - json:
              expressions:
                timestamp: "@t"
                level: "@l"
                message: "@mt"
                service_name: ServiceName
                service_version: ServiceVersion
                pod_name: PodName
                pod_namespace: PodNamespace
                node_name: NodeName
                thread_id: ThreadId
          - timestamp:
              source: timestamp
              format: RFC3339Nano
          - labels:
              level:
              service_name:
              pod_name:
              pod_namespace:
          - static_labels:
              cluster: openshift
              environment: production
"@

Write-Info "Creating ConfigMap..."
$promtailConfigContent | Out-File -FilePath $tempConfigMap -Encoding UTF8
oc apply -f $tempConfigMap
Remove-Item $tempConfigMap -Force

Write-Success "Promtail ConfigMap created"

# Create Deployment
Write-Header "Creating Payment API Deployment"

# Create temporary file for Deployment
$tempDeployment = [System.IO.Path]::GetTempFileName()
$deploymentContent = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: ${Namespace}
  labels:
    app: payment-api
    version: 2.0.0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
        version: 2.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8888"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      # Payment API container
      - name: payment-api
        image: image-registry.openshift-image-registry.svc:5000/${Namespace}/payment-api-instrumented:2.0.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8888
          protocol: TCP
        env:
        # Application settings
        - name: ASPNETCORE_URLS
          value: "http://+:8888"
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
          
        # OpenTelemetry settings
        - name: OTEL_SERVICE_NAME
          value: "payment-api-instrumented"
        - name: OTEL_SERVICE_VERSION
          value: "2.0.0"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://tempo:4317"
        - name: OTEL_TRACES_SAMPLER
          value: "always_on"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.namespace=ebanking.observability,deployment.environment=production,cloud.platform=openshift"
          
        # Logging settings
        - name: ENABLE_FILE_LOGGING
          value: "true"
        - name: LOG_DIRECTORY
          value: "/var/log/payment-api"
          
        # Kubernetes metadata (Downward API)
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
              
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
            
        livenessProbe:
          httpGet:
            path: /health
            port: 8888
          initialDelaySeconds: 10
          periodSeconds: 30
          timeoutSeconds: 5
          
        readinessProbe:
          httpGet:
            path: /health
            port: 8888
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          
        volumeMounts:
        - name: logs
          mountPath: /var/log/payment-api
          
      # Promtail sidecar container
      - name: promtail
        image: grafana/promtail:2.9.0
        args:
        - -config.file=/etc/promtail/promtail.yaml
        - -config.expand-env=true
        ports:
        - name: http-metrics
          containerPort: 9080
          protocol: TCP
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
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
---
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: ${Namespace}
  labels:
    app: payment-api
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8888
    targetPort: 8888
    protocol: TCP
  - name: promtail-metrics
    port: 9080
    targetPort: 9080
    protocol: TCP
  selector:
    app: payment-api
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: payment-api
  namespace: ${Namespace}
  labels:
    app: payment-api
spec:
  to:
    kind: Service
    name: payment-api
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
"@

Write-Info "Creating deployment, service, and route..."
$deploymentContent | Out-File -FilePath $tempDeployment -Encoding UTF8
oc apply -f $tempDeployment
Remove-Item $tempDeployment -Force

Write-Success "Resources created"

# Wait for deployment to be ready
Write-Header "Waiting for Deployment"

Write-Info "Waiting for pods to be ready (timeout: 120s)..."
$timeout = 120
$elapsed = 0
$ready = $false

while ($elapsed -lt $timeout) {
    $podStatus = oc get pods -l app=payment-api -o jsonpath='{.items[0].status.phase}' 2>$null
    $readyContainers = oc get pods -l app=payment-api -o jsonpath='{.items[0].status.containerStatuses[*].ready}' 2>$null
    
    if ($podStatus -eq "Running" -and $readyContainers -match "true true") {
        $ready = $true
        break
    }
    
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
    $elapsed += 5
}

Write-Host ""

if (-not $ready) {
    Write-Error "Deployment did not become ready within timeout"
    Write-Info "Checking pod status..."
    oc get pods -l app=payment-api
    Write-Info "Checking pod events..."
    oc describe pods -l app=payment-api
    exit 1
}

Write-Success "Deployment is ready"

# Get pod name
$podName = oc get pods -l app=payment-api -o jsonpath='{.items[0].metadata.name}'
Write-Info "Pod name: $podName"

# Check pod status
Write-Header "Pod Status"
oc get pods -l app=payment-api -o wide

# Check logs
Write-Header "Application Logs (last 20 lines)"
Write-Info "Payment API container logs:"
oc logs $podName -c payment-api --tail=20

Write-Info "`nPromtail container logs:"
oc logs $podName -c promtail --tail=20

# Check log files
Write-Header "Log Files in Shared Volume"
Write-Info "Checking /var/log/payment-api directory..."
oc exec $podName -c payment-api -- ls -lh /var/log/payment-api/

# Get route URL
Write-Header "Service URLs"
$routeHost = oc get route payment-api -o jsonpath='{.spec.host}'
$apiUrl = "https://$routeHost"

Write-Success "Payment API URL: $apiUrl"
Write-Info "Metrics URL: $apiUrl/metrics"
Write-Info "Health URL: $apiUrl/health"
Write-Info "Swagger URL: $apiUrl/swagger"

# Test endpoints
Write-Header "Testing Endpoints"

Write-Info "Testing /health endpoint..."
try {
    $healthResponse = Invoke-RestMethod -Uri "$apiUrl/health" -Method Get -SkipCertificateCheck
    Write-Success "Health check passed: $($healthResponse.status)"
    Write-Host ($healthResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Error "Health check failed: $_"
}

Write-Info "`nTesting /metrics endpoint..."
try {
    $metricsResponse = Invoke-WebRequest -Uri "$apiUrl/metrics" -Method Get -SkipCertificateCheck
    $metricsLines = ($metricsResponse.Content -split "`n" | Where-Object { $_ -match "^[^#]" -and $_.Trim() -ne "" }).Count
    Write-Success "Metrics endpoint accessible ($metricsLines metrics)"
} catch {
    Write-Error "Metrics endpoint failed: $_"
}

Write-Info "`nTesting /api/payments endpoint..."
try {
    $payment = @{
        amount = 100.50
        currency = "USD"
        description = "Test payment from OpenShift"
    } | ConvertTo-Json

    $paymentResponse = Invoke-RestMethod -Uri "$apiUrl/api/payments" -Method Post -Body $payment -ContentType "application/json" -SkipCertificateCheck
    Write-Success "Payment created: $($paymentResponse.id)"
    Write-Host ($paymentResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Error "Payment creation failed: $_"
}

# Check OpenTelemetry traces
Write-Header "OpenTelemetry Verification"

Write-Info "Checking if traces are being exported..."
$traceLogs = oc logs $podName -c payment-api --tail=50 | Select-String "OTLP"
if ($traceLogs) {
    Write-Success "OTLP exporter is configured"
    $traceLogs | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Error "No OTLP exporter logs found"
}

# Check Promtail
Write-Header "Promtail Verification"

Write-Info "Checking Promtail status..."
$promtailLogs = oc logs $podName -c promtail --tail=50 | Select-String -Pattern "level=(info|error)"
if ($promtailLogs) {
    Write-Success "Promtail is running"
    $promtailLogs | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Error "No Promtail logs found"
}

# Summary
Write-Header "Deployment Summary"

Write-Host @"

✅ Deployment Status: READY
📦 Pod: $podName
🌐 API URL: $apiUrl
📊 Metrics: $apiUrl/metrics
🔍 Traces: Exported to Tempo (http://tempo:4317)
📝 Logs: 
   - Console → stdout → Promtail
   - File → /var/log/payment-api → Promtail → Loki

Next Steps:
1. View logs in Grafana: Explore → Loki → {app="payment-api-instrumented"}
2. View traces in Grafana: Explore → Tempo → Search
3. View metrics in Grafana: Explore → Prometheus → http_server_request_duration_seconds
4. Generate load: .\test-api.ps1 -BaseUrl $apiUrl -Requests 100

Useful Commands:
  oc logs $podName -c payment-api -f          # Follow app logs
  oc logs $podName -c promtail -f             # Follow Promtail logs
  oc exec $podName -c payment-api -- ls -lh /var/log/payment-api/  # Check log files
  oc port-forward $podName 8888:8888          # Port forward for local testing
  oc delete deployment payment-api            # Clean up

"@ -ForegroundColor Cyan

Write-Success "Test completed successfully! 🎉"
