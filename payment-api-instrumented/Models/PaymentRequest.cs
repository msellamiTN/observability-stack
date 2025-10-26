namespace PaymentApi.Models;

public class PaymentRequest
{
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "EUR";
    public string PaymentMethod { get; set; } = "card"; // card, bank_transfer, paypal, apple_pay, google_pay
    public string? CardBrand { get; set; } // VISA, MASTERCARD, AMEX, DISCOVER
    public string? UserId { get; set; }
    public string? Region { get; set; } // EU_WEST, EU_CENTRAL, US_EAST, ASIA_PACIFIC
}

public class PaymentResponse
{
    public string TransactionId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty; // success, failed
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public string? CardBrand { get; set; }
    public long ProcessingTimeMs { get; set; }
    public string? ErrorCode { get; set; }
    public string? ErrorMessage { get; set; }
    public string TraceId { get; set; } = string.Empty;
    public string SpanId { get; set; } = string.Empty;
}

public class PaymentMetrics
{
    public long TotalPayments { get; set; }
    public long SuccessfulPayments { get; set; }
    public long FailedPayments { get; set; }
    public decimal SuccessRate { get; set; }
    public decimal TotalRevenue { get; set; }
    public double AverageLatencyMs { get; set; }
}
