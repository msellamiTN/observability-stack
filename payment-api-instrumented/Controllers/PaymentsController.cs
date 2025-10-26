using Microsoft.AspNetCore.Mvc;
using PaymentApi.Models;
using PaymentApi.Services;
using System.Diagnostics;
using OpenTelemetry.Trace;

namespace PaymentApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PaymentsController : ControllerBase
{
    private readonly PaymentService _paymentService;
    private readonly ILogger<PaymentsController> _logger;
    private static readonly ActivitySource ActivitySource = new("payment-api-instrumented");

    public PaymentsController(PaymentService paymentService, ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// Process a payment transaction
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(PaymentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ProcessPayment([FromBody] PaymentRequest request)
    {
        using var activity = ActivitySource.StartActivity("ProcessPayment", ActivityKind.Server);
        
        // Add tags to the span
        activity?.SetTag("payment.amount", request.Amount);
        activity?.SetTag("payment.currency", request.Currency);
        activity?.SetTag("payment.method", request.PaymentMethod);
        activity?.SetTag("payment.region", request.Region);
        
        if (!string.IsNullOrEmpty(request.CardBrand))
        {
            activity?.SetTag("payment.card_brand", request.CardBrand);
        }

        try
        {
            // Validate request
            if (request.Amount <= 0)
            {
                _logger.LogWarning("Invalid payment amount: {Amount}", request.Amount);
                return BadRequest(new { error = "Amount must be greater than zero" });
            }

            if (string.IsNullOrEmpty(request.PaymentMethod))
            {
                _logger.LogWarning("Payment method is required");
                return BadRequest(new { error = "Payment method is required" });
            }

            // Process payment
            var response = await _paymentService.ProcessPaymentAsync(request);

            // Add response details to span
            activity?.SetTag("payment.transaction_id", response.TransactionId);
            activity?.SetTag("payment.status", response.Status);
            activity?.SetTag("payment.processing_time_ms", response.ProcessingTimeMs);

            if (response.Status == "failed")
            {
                activity?.SetStatus(ActivityStatusCode.Error, response.ErrorMessage);
                activity?.SetTag("payment.error_code", response.ErrorCode);
                
                return StatusCode(StatusCodes.Status500InternalServerError, response);
            }

            return Ok(response);
        }
        catch (Exception ex)
        {
            activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
            activity?.AddException(ex);
            
            _logger.LogError(ex, "Unexpected error processing payment");
            
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                error = "Internal server error",
                message = ex.Message
            });
        }
    }

    /// <summary>
    /// Get payment by transaction ID
    /// </summary>
    [HttpGet("{transactionId}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult GetPayment(string transactionId)
    {
        // This would typically query from a database
        _logger.LogInformation("Retrieving payment: {TransactionId}", transactionId);
        
        return Ok(new
        {
            transactionId,
            status = "success",
            message = "Payment retrieval endpoint (not implemented)"
        });
    }

    /// <summary>
    /// Simulate payment scenarios for testing
    /// </summary>
    [HttpPost("simulate")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> SimulatePayments([FromQuery] int count = 10)
    {
        var paymentMethods = new[] { "card", "bank_transfer", "paypal", "apple_pay", "google_pay" };
        var cardBrands = new[] { "VISA", "MASTERCARD", "AMEX", "DISCOVER" };
        var currencies = new[] { "EUR", "USD", "GBP", "CHF", "JPY" };
        var regions = new[] { "EU_WEST", "EU_CENTRAL", "US_EAST", "ASIA_PACIFIC" };
        var random = new Random();

        var results = new List<PaymentResponse>();

        for (int i = 0; i < count; i++)
        {
            var paymentMethod = paymentMethods[random.Next(paymentMethods.Length)];
            var request = new PaymentRequest
            {
                Amount = (decimal)(random.NextDouble() * 1000 + 10),
                Currency = currencies[random.Next(currencies.Length)],
                PaymentMethod = paymentMethod,
                CardBrand = paymentMethod == "card" ? cardBrands[random.Next(cardBrands.Length)] : null,
                UserId = $"U{random.Next(10000, 99999)}",
                Region = regions[random.Next(regions.Length)]
            };

            var response = await _paymentService.ProcessPaymentAsync(request);
            results.Add(response);

            // Small delay between simulated payments
            await Task.Delay(random.Next(10, 50));
        }

        var successCount = results.Count(r => r.Status == "success");
        var failureCount = results.Count(r => r.Status == "failed");

        return Ok(new
        {
            totalSimulated = count,
            successful = successCount,
            failed = failureCount,
            successRate = (double)successCount / count * 100,
            results
        });
    }
}
