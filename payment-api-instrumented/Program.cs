using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.ResourceDetectors.Container;
using OpenTelemetry.ResourceDetectors.Host;
using OpenTelemetry.ResourceDetectors.Process;
using PaymentApi.Services;
using Serilog;
using Serilog.Events;
using Serilog.Formatting.Compact;
using OpenTelemetry.Instrumentation.Runtime;

var builder = WebApplication.CreateBuilder(args);

// Configure log directory (shared volume for Loki)
var logDirectory = Environment.GetEnvironmentVariable("LOG_DIRECTORY") ?? "/var/log/payment-api";
var enableFileLogging = Environment.GetEnvironmentVariable("ENABLE_FILE_LOGGING")?.ToLower() == "true";

// Ensure log directory exists
if (enableFileLogging && !Directory.Exists(logDirectory))
{
    try
    {
        Directory.CreateDirectory(logDirectory);
        Console.WriteLine($"[Serilog] Created log directory: {logDirectory}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Serilog] Failed to create log directory: {ex.Message}");
        enableFileLogging = false;
    }
}

// Configure Serilog for structured logging with trace context
var loggerConfig = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .Enrich.WithEnvironmentName()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .Enrich.WithThreadName()
    .Enrich.WithProperty("ServiceName", "payment-api-instrumented")
    .Enrich.WithProperty("ServiceVersion", "1.0.0")
    .Enrich.WithProperty("ServiceNamespace", "ebanking.observability")
    .Enrich.WithProperty("DeploymentEnvironment", Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production")
    .Enrich.WithProperty("ContainerId", Environment.GetEnvironmentVariable("HOSTNAME") ?? Environment.MachineName)
    .Enrich.WithProperty("HostType", "container")
    .Enrich.WithProperty("PodName", Environment.GetEnvironmentVariable("POD_NAME") ?? "unknown")
    .Enrich.WithProperty("PodNamespace", Environment.GetEnvironmentVariable("POD_NAMESPACE") ?? "unknown")
    .Enrich.WithProperty("NodeName", Environment.GetEnvironmentVariable("NODE_NAME") ?? "unknown")
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.AspNetCore.Hosting.Diagnostics", LogEventLevel.Warning)
    .MinimumLevel.Override("System.Net.Http.HttpClient", LogEventLevel.Warning)
    .WriteTo.Console(new CompactJsonFormatter());

// Add file logging to shared volume for Loki
if (enableFileLogging)
{
    loggerConfig.WriteTo.Async(a => a.File(
        new CompactJsonFormatter(),
        path: Path.Combine(logDirectory, "payment-api-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 7,
        fileSizeLimitBytes: 100_000_000, // 100MB
        rollOnFileSizeLimit: true,
        shared: true,
        flushToDiskInterval: TimeSpan.FromSeconds(1)
    ));
    Console.WriteLine($"[Serilog] File logging enabled: {logDirectory}/payment-api-.log");
}

Log.Logger = loggerConfig.CreateLogger();

builder.Host.UseSerilog();

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<PaymentService>();

// Configure OpenTelemetry with proper resource attributes
var serviceName = "payment-api-instrumented";
var serviceVersion = "1.0.0";
var serviceInstanceId = Environment.GetEnvironmentVariable("HOSTNAME") ?? Environment.MachineName;

// Register ActivitySource
var activitySource = new System.Diagnostics.ActivitySource(serviceName);

builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(
            serviceName: serviceName, 
            serviceVersion: serviceVersion,
            serviceInstanceId: serviceInstanceId)
        // Auto-detect container, host, and process information
        .AddDetector(new ContainerResourceDetector())
        .AddDetector(new HostDetector())
        .AddDetector(new ProcessDetector())
        .AddAttributes(new Dictionary<string, object>
        {
            // Deployment attributes
            ["deployment.environment"] = builder.Environment.EnvironmentName.ToLowerInvariant(),
            ["deployment.environment.type"] = "openshift",
            
            // Service attributes
            ["service.namespace"] = "ebanking.observability",
            ["service.instance.id"] = serviceInstanceId,
            
            // Kubernetes/OpenShift attributes
            ["k8s.pod.name"] = Environment.GetEnvironmentVariable("POD_NAME") ?? "unknown",
            ["k8s.pod.namespace"] = Environment.GetEnvironmentVariable("POD_NAMESPACE") ?? "unknown",
            ["k8s.node.name"] = Environment.GetEnvironmentVariable("NODE_NAME") ?? "unknown",
            ["k8s.deployment.name"] = "payment-api",
            ["k8s.container.name"] = "payment-api",
            
            // Cloud/Infrastructure attributes
            ["cloud.platform"] = "openshift",
            ["cloud.provider"] = "redhat",
            
            // Application metadata
            ["app.team"] = "platform-engineering",
            ["app.owner"] = "observability-team",
            ["app.tier"] = "backend",
            ["app.type"] = "instrumented-demo",
            ["app.purpose"] = "observability-testing"
        }))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation(options =>
        {
            options.RecordException = true;
            options.Filter = httpContext =>
                !httpContext.Request.Path.StartsWithSegments("/metrics") &&
                !httpContext.Request.Path.StartsWithSegments("/health");
            options.EnrichWithHttpRequest = (activity, httpRequest) =>
            {
                activity.SetTag("http.request.body.size", httpRequest.ContentLength);
                activity.SetTag("http.request.headers.user_agent", httpRequest.Headers.UserAgent.ToString());
                activity.SetTag("http.client_ip", httpRequest.HttpContext.Connection.RemoteIpAddress?.ToString());
            };
            options.EnrichWithHttpResponse = (activity, httpResponse) =>
            {
                activity.SetTag("http.response.body.size", httpResponse.ContentLength);
            };
            options.EnrichWithException = (activity, exception) =>
            {
                activity.SetTag("exception.type", exception.GetType().Name);
                activity.SetTag("exception.message", exception.Message);
                activity.SetTag("exception.stacktrace", exception.StackTrace);
            };
        })
        .AddHttpClientInstrumentation(options =>
        {
            options.RecordException = true;
            options.EnrichWithHttpRequestMessage = (activity, httpRequestMessage) =>
            {
                activity.SetTag("http.request.method", httpRequestMessage.Method.ToString());
            };
            options.EnrichWithHttpResponseMessage = (activity, httpResponseMessage) =>
            {
                activity.SetTag("http.response.status_code", (int)httpResponseMessage.StatusCode);
            };
        })
        .AddSqlClientInstrumentation(options =>
        {
            options.SetDbStatementForText = true;
            options.RecordException = true;
            options.EnableConnectionLevelAttributes = true;
        })
        .AddSource(serviceName)
        .SetSampler(new AlwaysOnSampler()) // Ensure all traces are sampled
        .SetErrorStatusOnException() // Mark spans as error when exceptions occur
        .AddConsoleExporter() // Debug: verify traces are being created
        .AddOtlpExporter(options =>
        {
            var endpoint = builder.Configuration["OpenTelemetry:OtlpEndpoint"] ?? "http://tempo:4317";
            options.Endpoint = new Uri(endpoint);
            options.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
            options.ExportProcessorType = OpenTelemetry.ExportProcessorType.Batch;
            options.BatchExportProcessorOptions = new OpenTelemetry.BatchExportProcessorOptions<System.Diagnostics.Activity>
            {
                MaxQueueSize = 2048,
                ScheduledDelayMilliseconds = 5000,
                ExporterTimeoutMilliseconds = 30000,
                MaxExportBatchSize = 512
            };
            
            // Log the endpoint for debugging
            Console.WriteLine($"[OpenTelemetry] OTLP Trace Exporter configured with endpoint: {endpoint}");
        }))
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddProcessInstrumentation()
        .AddMeter("PaymentApi")
        .AddView("http.server.request.duration", new ExplicitBucketHistogramConfiguration
        {
            Boundaries = new double[] { 0, 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10 }
        })
        .AddPrometheusExporter());

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseSerilogRequestLogging(options =>
{
    options.GetLevel = (httpContext, elapsed, ex) =>
    {
        var path = httpContext.Request.Path.Value;
        if (!string.IsNullOrEmpty(path) && (path.StartsWith("/metrics") || path.StartsWith("/health")))
        {
            return LogEventLevel.Debug;
        }
        return LogEventLevel.Information;
    };
});

// Prometheus metrics endpoint
app.MapPrometheusScrapingEndpoint();

app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new
{
    status = "healthy",
    service = serviceName,
    version = serviceVersion,
    timestamp = DateTime.UtcNow
}));

// Metrics endpoint (for debugging)
app.MapGet("/api/metrics", (PaymentService paymentService) =>
{
    return Results.Ok(paymentService.GetMetrics());
});

try
{
    Log.Information("Starting Payment API service");
    Log.Information("Service Name: {ServiceName}, Version: {ServiceVersion}", serviceName, serviceVersion);
    Log.Information("Instance ID: {InstanceId}", serviceInstanceId);
    Log.Information("Environment: {Environment}", builder.Environment.EnvironmentName);
    Log.Information("File Logging: {FileLogging}, Directory: {LogDirectory}", enableFileLogging, logDirectory);
    Log.Information("OTLP Endpoint: {OtlpEndpoint}", builder.Configuration["OpenTelemetry:OtlpEndpoint"] ?? "http://tempo:4317");
    
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.Information("Shutting down Payment API service");
    Log.CloseAndFlush();
    await Task.Delay(1000); // Give time for async sinks to flush
}
