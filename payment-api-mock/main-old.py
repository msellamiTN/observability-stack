from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import random
import time
import os
from dotenv import load_dotenv
import logging

# Prometheus metrics
from prometheus_client import (
    Counter, Histogram, Gauge, Summary,
    generate_latest, CONTENT_TYPE_LATEST, CollectorRegistry
)

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Payment API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus Registry
registry = CollectorRegistry()

# ============================================
# PROMETHEUS METRICS DEFINITIONS
# ============================================

# Payment amount metrics
payment_amount_total = Counter(
    'payment_amount_total',
    'Total payment amount in EUR',
    ['status', 'currency', 'payment_method', 'region', 'card_brand'],
    registry=registry
)

# Payment count metrics
payment_count_total = Counter(
    'payment_count_total',
    'Total number of payments',
    ['status', 'currency', 'payment_method', 'region', 'card_brand', 'risk_level'],
    registry=registry
)

# Processing time histogram
payment_processing_time_seconds = Histogram(
    'payment_processing_time_seconds',
    'Payment processing time in seconds',
    ['status', 'payment_method'],
    buckets=[0.05, 0.1, 0.2, 0.3, 0.5, 0.8, 1.0, 1.5, 2.0, 3.0, 5.0],
    registry=registry
)

# Latency metrics
payment_network_latency_ms = Histogram(
    'payment_network_latency_ms',
    'Network latency in milliseconds',
    ['region'],
    buckets=[5, 10, 20, 30, 50, 75, 100, 150, 200],
    registry=registry
)

payment_gateway_latency_ms = Histogram(
    'payment_gateway_latency_ms',
    'Gateway latency in milliseconds',
    ['payment_method'],
    buckets=[10, 25, 50, 75, 100, 150, 200, 300, 500],
    registry=registry
)

# Fraud score summary
payment_fraud_score = Summary(
    'payment_fraud_score',
    'Payment fraud score',
    ['status', 'risk_level'],
    registry=registry
)

# Fee metrics
payment_fee_total = Counter(
    'payment_fee_total',
    'Total payment processing fees',
    ['currency'],
    registry=registry
)

# Error metrics
payment_errors_total = Counter(
    'payment_errors_total',
    'Total payment errors',
    ['error_code', 'payment_method'],
    registry=registry
)

# Retry metrics
payment_retries_total = Counter(
    'payment_retries_total',
    'Total payment retries',
    ['status'],
    registry=registry
)

# Current gauges for real-time monitoring
payment_success_rate = Gauge(
    'payment_success_rate',
    'Current success rate percentage',
    registry=registry
)

# Helper functions
def generate_realistic_amount() -> float:
    """Realistic distribution: 80% < 200€, 15% 200-1000€, 5% > 1000€"""
    rand = random.random()
    if rand < 0.80:
        return round(random.gauss(75, 45), 2)
    elif rand < 0.95:
        return round(random.gauss(500, 250), 2)
    else:
        return round(random.gauss(2000, 1000), 2)

def generate_processing_time(status: str) -> float:
    """Realistic processing time based on status"""
    if status == "success":
        return max(0.05, round(random.gauss(0.24, 0.10), 3))
    else:
        return max(0.1, round(random.gauss(0.80, 0.35), 3))

# Models
class PaymentRequest(BaseModel):
    amount: float = 0.0
    currency: str = "EUR"
    customer_id: str = "anonymous"
    description: str = None

class PaymentResponse(BaseModel):
    payment_id: str
    status: str
    amount: float
    currency: str
    timestamp: str
    processing_time_ms: float

# Success rate tracker (simple moving average)
success_count = 0
total_count = 0

def update_success_rate(is_success: bool):
    global success_count, total_count
    total_count += 1
    if is_success:
        success_count += 1
    
    if total_count > 0:
        rate = (success_count / total_count) * 100
        payment_success_rate.set(rate)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# Metrics endpoint for Prometheus scraping
@app.get("/metrics")
async def metrics():
    return Response(
        content=generate_latest(registry),
        media_type=CONTENT_TYPE_LATEST
    )

# Process payment
@app.post("/api/payments", response_model=PaymentResponse)
async def process_payment(payment: PaymentRequest):
    start_time = time.time()
    
    # Determine status (97% success, 2% failed, 1% pending)
    status_rand = random.random()
    if status_rand < 0.97:
        status = "success"
    elif status_rand < 0.99:
        status = "failed"
    else:
        status = "pending"
    
    is_success = status == "success"
    
    # Use realistic amount if not provided
    amount = payment.amount if payment.amount > 0 else generate_realistic_amount()
    
    # Generate realistic processing time
    processing_time = generate_processing_time(status)
    time.sleep(processing_time)
    
    # Generate additional metrics
    network_latency = round(random.uniform(5, 50), 1)
    gateway_latency = round(random.uniform(10, 100), 1)
    
    # Generate labels
    payment_method = random.choice(["card", "bank_transfer", "wallet", "crypto"])
    region = random.choice(["EU", "US", "ASIA", "LATAM"])
    card_brand = random.choice(["VISA", "MASTERCARD", "AMEX", "DISCOVER"])
    risk_level = random.choices(
        ["low", "medium", "high", "critical"],
        weights=[0.80, 0.15, 0.04, 0.01]
    )[0]
    
    fraud_score = (round(random.uniform(0, 0.05), 3) if is_success 
                   else round(random.uniform(0.70, 1.0), 3))
    fee = round(amount * 0.029 + 0.30, 2)
    error_code = 0 if is_success else random.randint(5001, 5010)
    retry_count = 0 if is_success else random.randint(1, 3)
    
    # Create payment ID
    payment_id = f"pay_{int(time.time() * 1000)}_{random.randint(1000, 9999)}"
    timestamp = datetime.utcnow().isoformat()
    
    # ============================================
    # RECORD METRICS TO PROMETHEUS
    # ============================================
    
    # Payment amount
    payment_amount_total.labels(
        status=status,
        currency=payment.currency,
        payment_method=payment_method,
        region=region,
        card_brand=card_brand
    ).inc(amount)
    
    # Payment count
    payment_count_total.labels(
        status=status,
        currency=payment.currency,
        payment_method=payment_method,
        region=region,
        card_brand=card_brand,
        risk_level=risk_level
    ).inc()
    
    # Processing time
    payment_processing_time_seconds.labels(
        status=status,
        payment_method=payment_method
    ).observe(processing_time)
    
    # Latency
    payment_network_latency_ms.labels(region=region).observe(network_latency)
    payment_gateway_latency_ms.labels(payment_method=payment_method).observe(gateway_latency)
    
    # Fraud score
    payment_fraud_score.labels(
        status=status,
        risk_level=risk_level
    ).observe(fraud_score)
    
    # Fee
    payment_fee_total.labels(currency=payment.currency).inc(fee)
    
    # Errors
    if not is_success:
        payment_errors_total.labels(
            error_code=str(error_code),
            payment_method=payment_method
        ).inc()
        
        payment_retries_total.labels(status=status).inc(retry_count)
    
    # Update success rate
    update_success_rate(is_success)
    
    logger.info(f"Payment {payment_id} processed: {status}")
    
    # Prepare response
    if is_success:
        return {
            "payment_id": payment_id,
            "status": "completed",
            "amount": amount,
            "currency": payment.currency,
            "timestamp": timestamp,
            "processing_time_ms": round(processing_time * 1000, 2)
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Payment processing failed"
        )

# Get payment statistics
@app.get("/api/payments/stats")
async def get_payment_stats():
    return {
        "total_payments": total_count,
        "success_rate": (success_count / total_count * 100) if total_count > 0 else 0,
        "message": "Check /metrics endpoint for detailed Prometheus metrics"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)