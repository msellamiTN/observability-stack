using System.Diagnostics;
using System.Diagnostics.Metrics;
using PaymentApi.Models;

namespace PaymentApi.Services;

public class PaymentService
{
    private readonly ILogger<PaymentService> _logger;
    private readonly Meter _meter;
    private readonly Counter<long> _paymentCounter;
    private readonly Counter<double> _paymentAmountCounter;
    private readonly Histogram<double> _paymentProcessingTime;
    private readonly Counter<long> _httpRequestsTotal;
    private readonly Random _random = new();

    public PaymentService(ILogger<PaymentService> logger, IMeterFactory meterFactory)
    {
        _logger = logger;
        _meter = meterFactory.Create("PaymentApi");

        // Metrics matching Grafana dashboard requirements
        _paymentCounter = _meter.CreateCounter<long>(
            "payment_count_total",
            description: "Total number of payment transactions");

        _paymentAmountCounter = _meter.CreateCounter<double>(
            "payment_amount_total",
            unit: "EUR",
            description: "Total payment amount in EUR");

        _paymentProcessingTime = _meter.CreateHistogram<double>(
            "payment_processing_time_seconds",
            unit: "s",
            description: "Payment processing time in seconds");

        _httpRequestsTotal = _meter.CreateCounter<long>(
            "http_requests_total",
            description: "Total HTTP requests");
    }

    public async Task<PaymentResponse> ProcessPaymentAsync(PaymentRequest request)
    {
        var sw = Stopwatch.StartNew();
        var transactionId = Guid.NewGuid().ToString("N")[..16];
        
        // Get trace context
        var activity = Activity.Current;
        var traceId = activity?.TraceId.ToString() ?? string.Empty;
        var spanId = activity?.SpanId.ToString() ?? string.Empty;

        try
        {
            // Simulate payment processing with realistic delays and failure scenarios
            var processingResult = await SimulatePaymentProcessingAsync(request);
            
            sw.Stop();
            var processingTimeMs = sw.ElapsedMilliseconds;
            var processingTimeSec = processingTimeMs / 1000.0;

            // Record metrics with proper labels
            var tags = new TagList
            {
                { "status", processingResult.Status },
                { "payment_method", request.PaymentMethod },
                { "currency", request.Currency },
                { "region", request.Region ?? "EU_WEST" }
            };

            if (!string.IsNullOrEmpty(request.CardBrand))
            {
                tags.Add("card_brand", request.CardBrand);
            }

            // Increment counters
            _paymentCounter.Add(1, tags);
            
            if (processingResult.Status == "success")
            {
                _paymentAmountCounter.Add((double)request.Amount, tags);
            }

            // Record processing time histogram
            _paymentProcessingTime.Record(processingTimeSec, tags);

            // HTTP request counter
            var httpTags = new TagList
            {
                { "job", "payment-api" },
                { "status", processingResult.Status == "success" ? "200" : "500" },
                { "method", "POST" },
                { "endpoint", "/api/payments" }
            };
            _httpRequestsTotal.Add(1, httpTags);

            // Structured logging with trace context
            _logger.LogInformation(
                "Payment processed: TransactionId={TransactionId}, Status={Status}, Amount={Amount}, " +
                "Currency={Currency}, PaymentMethod={PaymentMethod}, CardBrand={CardBrand}, " +
                "ProcessingTimeMs={ProcessingTimeMs}, TraceId={TraceId}, SpanId={SpanId}, UserId={UserId}",
                transactionId, processingResult.Status, request.Amount, request.Currency,
                request.PaymentMethod, request.CardBrand, processingTimeMs, traceId, spanId, request.UserId);

            return new PaymentResponse
            {
                TransactionId = transactionId,
                Status = processingResult.Status,
                Amount = request.Amount,
                Currency = request.Currency,
                PaymentMethod = request.PaymentMethod,
                CardBrand = request.CardBrand,
                ProcessingTimeMs = processingTimeMs,
                ErrorCode = processingResult.ErrorCode,
                ErrorMessage = processingResult.ErrorMessage,
                TraceId = traceId,
                SpanId = spanId
            };
        }
        catch (Exception ex)
        {
            sw.Stop();
            
            _logger.LogError(ex,
                "Payment processing failed: TransactionId={TransactionId}, TraceId={TraceId}, SpanId={SpanId}",
                transactionId, traceId, spanId);

            // Record failed metrics
            var failedTags = new TagList
            {
                { "status", "failed" },
                { "payment_method", request.PaymentMethod },
                { "currency", request.Currency },
                { "region", request.Region ?? "EU_WEST" }
            };
            _paymentCounter.Add(1, failedTags);

            throw;
        }
    }

    private async Task<(string Status, string? ErrorCode, string? ErrorMessage)> SimulatePaymentProcessingAsync(PaymentRequest request)
    {
        // Simulate realistic processing delays
        var baseDelay = _random.Next(50, 200);
        
        // Add extra delay for certain payment methods
        if (request.PaymentMethod == "bank_transfer")
            baseDelay += _random.Next(100, 300);
        
        // Simulate occasional slow transactions (for latency spikes)
        if (_random.Next(100) < 5) // 5% chance
            baseDelay += _random.Next(500, 2000);

        await Task.Delay(baseDelay);

        // Simulate failure scenarios (realistic failure rate ~2-5%)
        var failureChance = _random.Next(100);
        
        if (failureChance < 2) // 2% fraud detection
        {
            return ("failed", "FRAUD_DETECTED", "Transaction flagged by fraud detection system");
        }
        
        if (failureChance < 4) // Additional 2% insufficient funds
        {
            return ("failed", "INSUFFICIENT_FUNDS", "Insufficient funds in account");
        }
        
        if (failureChance < 5) // Additional 1% network timeout
        {
            return ("failed", "NETWORK_TIMEOUT", "Payment gateway timeout");
        }

        // Validate amount
        if (request.Amount <= 0)
        {
            return ("failed", "INVALID_AMOUNT", "Amount must be greater than zero");
        }

        if (request.Amount > 10000)
        {
            return ("failed", "AMOUNT_LIMIT_EXCEEDED", "Transaction amount exceeds limit");
        }

        return ("success", null, null);
    }

    public PaymentMetrics GetMetrics()
    {
        // This would typically query from a metrics store
        // For now, return dummy data for health check
        return new PaymentMetrics
        {
            TotalPayments = 0,
            SuccessfulPayments = 0,
            FailedPayments = 0,
            SuccessRate = 0,
            TotalRevenue = 0,
            AverageLatencyMs = 0
        };
    }
}
