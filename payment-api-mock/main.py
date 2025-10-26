from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import random
import time
import os
from dotenv import load_dotenv
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# InfluxDB configuration
INFLUX_CONFIG = {
    "url": os.getenv("INFLUXDB_URL", "http://influxdb:8086"),
    "token": os.getenv("INFLUXDB_TOKEN", "my-super-secret-auth-token"),
    "org": os.getenv("INFLUXDB_ORG", "myorg"),
    "bucket": os.getenv("INFLUXDB_BUCKET", "payments")
}

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

# Initialize InfluxDB client (optional)
influx_client = InfluxDBClient(
    url=INFLUX_CONFIG["url"],
    token=INFLUX_CONFIG["token"],
    org=INFLUX_CONFIG["org"],
    verify_ssl=False,
    ssl=False
)
write_api = influx_client.write_api(write_options=SYNCHRONOUS)

# ========================
# PROMETHEUS METRICS
# ========================

# Counter: total amount by status + dimensions (includes currency)
PAYMENT_AMOUNT = Counter(
    'payment_amount_sum',
    'Total successful/failed payment amount',
    ['status', 'currency', 'payment_method', 'region', 'card_brand']
)

# Counter: transaction count by status + dimensions (includes currency)
PAYMENT_COUNT = Counter(
    'payment_count_total',
    'Total number of payment transactions',
    ['status', 'currency', 'payment_method', 'region', 'card_brand']
)

# Histogram: processing time (NO currency — matches dashboard logic)
PAYMENT_PROCESSING_DURATION = Histogram(
    'payment_processing_duration_seconds',
    'Processing time per transaction',
    ['status', 'payment_method', 'region', 'card_brand'],
    buckets=[0.05, 0.1, 0.2, 0.3, 0.5, 0.8, 1.0, 2.0, 5.0]
)

# Optional: generic HTTP metrics
from prometheus_client import Counter as GenCounter, Histogram as GenHistogram
REQUEST_COUNT = GenCounter(
    'payment_requests_total',
    'HTTP requests to payment endpoints',
    ['method', 'endpoint', 'status']
)
REQUEST_LATENCY = GenHistogram(
    'payment_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

# ========================
# HELPERS
# ========================

def generate_realistic_amount() -> float:
    rand = random.random()
    if rand < 0.80:
        return max(0.01, round(random.gauss(75, 45), 2))
    elif rand < 0.95:
        return max(0.01, round(random.gauss(500, 250), 2))
    else:
        return max(0.01, round(random.gauss(2000, 1000), 2))

def generate_processing_time(status: str) -> float:
    if status == "success":
        return max(0.05, round(random.gauss(0.24, 0.10), 3))
    else:
        return max(0.1, round(random.gauss(0.80, 0.35), 3))

# ========================
# MODELS
# ========================

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

# ========================
# MIDDLEWARE
# ========================

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start = time.time()
    method = request.method
    endpoint = request.url.path
    try:
        response = await call_next(request)
        REQUEST_COUNT.labels(method, endpoint, response.status_code).inc()
        REQUEST_LATENCY.labels(method, endpoint).observe(time.time() - start)
        return response
    except Exception as e:
        REQUEST_COUNT.labels(method, endpoint, 500).inc()
        raise e

# ========================
# ENDPOINTS
# ========================

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/api/payments", response_model=PaymentResponse)
async def process_payment(payment: PaymentRequest, request: Request):
    start_time = time.time()

    # Get custom rates from headers (if provided)
    success_rate = float(request.headers.get("X-Success-Rate", "84")) / 100
    failure_rate = float(request.headers.get("X-Failure-Rate", "1")) / 100
    pending_rate = float(request.headers.get("X-Pending-Rate", "15")) / 100
    
    # Normalize rates to ensure they sum to 1.0
    total = success_rate + failure_rate + pending_rate
    if total > 0:
        success_rate /= total
        failure_rate /= total
        pending_rate /= total
    
    # Determine status based on custom or default rates
    r = random.random()
    if r < success_rate:
        status = "success"
    elif r < success_rate + failure_rate:
        status = "failed"
    else:
        status = "pending"

    is_success = (status == "success")
    amount = payment.amount if payment.amount > 0 else generate_realistic_amount()
    processing_time = generate_processing_time(status)
    time.sleep(processing_time)

    # Generate dimensions
    payment_method = random.choice(["card", "bank_transfer", "wallet", "crypto"])
    region = random.choice(["EU", "US", "ASIA", "LATAM"])
    card_brand = random.choice(["VISA", "MASTERCARD", "AMEX", "DISCOVER"])

    # ------------------------
    # ✅ PROMETHEUS METRICS
    # ------------------------
    counter_labels = {
        "status": status,
        "currency": payment.currency,
        "payment_method": payment_method,
        "region": region,
        "card_brand": card_brand
    }

    histogram_labels = {
        "status": status,
        "payment_method": payment_method,
        "region": region,
        "card_brand": card_brand
    }

    PAYMENT_COUNT.labels(**counter_labels).inc()
    if status in ("success", "failed"):
        PAYMENT_AMOUNT.labels(**counter_labels).inc(amount)
    PAYMENT_PROCESSING_DURATION.labels(**histogram_labels).observe(processing_time)

    # ------------------------
    # 📦 InfluxDB (optional)
    # ------------------------
    try:
        point = Point("payment")
        for k, v in counter_labels.items():
            point.tag(k, v)
        point.tag("risk_level", random.choices(["low","medium","high","critical"], weights=[0.80,0.15,0.04,0.01])[0])
        point.field("amount", float(amount))
        point.field("processing_time", processing_time)
        point.field("success", 1 if is_success else 0)
        point.time(datetime.utcnow())
        write_api.write(bucket=INFLUX_CONFIG["bucket"], org=INFLUX_CONFIG["org"], record=point)
    except Exception as e:
        logger.error(f"InfluxDB write failed: {e}")

    # ------------------------
    # 📤 Response
    # ------------------------
    payment_id = f"pay_{int(time.time() * 1000)}_{random.randint(1000, 9999)}"
    if is_success:
        return PaymentResponse(
            payment_id=payment_id,
            status="completed",
            amount=amount,
            currency=payment.currency,
            timestamp=datetime.utcnow().isoformat(),
            processing_time_ms=round(processing_time * 1000, 2)
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Payment processing failed"
        )

@app.get("/api/payments/stats")
async def get_payment_stats():
    return {"info": "Use /metrics for Prometheus data"}

# Optional: auto-instrumentation
from prometheus_fastapi_instrumentator import Instrumentator
Instrumentator().instrument(app).expose(app, include_in_schema=False, endpoint="/metrics-auto")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)