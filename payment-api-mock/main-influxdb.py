from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import random
import time
import os
from dotenv import load_dotenv
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
from prometheus_fastapi_instrumentator import Instrumentator
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

# Initialize InfluxDB client
influx_client = InfluxDBClient(
    url=INFLUX_CONFIG["url"],
    token=INFLUX_CONFIG["token"],
    org=INFLUX_CONFIG["org"],
    verify_ssl=False,
    ssl=False
)
write_api = influx_client.write_api(write_options=SYNCHRONOUS)

# Helper functions for realistic data generation
def generate_realistic_amount() -> float:
    """Distribution réaliste: 80% < 200€, 15% 200-1000€, 5% > 1000€"""
    rand = random.random()
    if rand < 0.80:
        return round(random.gauss(75, 45), 2)
    elif rand < 0.95:
        return round(random.gauss(500, 250), 2)
    else:
        return round(random.gauss(2000, 1000), 2)

def generate_processing_time(status: str) -> float:
    """Temps réaliste selon statut"""
    if status == "success":
        return max(0.05, round(random.gauss(0.24, 0.10), 3))
    else:
        return max(0.1, round(random.gauss(0.80, 0.35), 3))

# Models
class PaymentRequest(BaseModel):
    amount: float = 0.0  # If 0, will use realistic amount generator
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

# Metrics and monitoring
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.requests import Request
from starlette.responses import Response

# Prometheus metrics
REQUEST_COUNT = Counter(
    'payment_requests_total',
    'Total number of payment requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'payment_request_duration_seconds',
    'Time spent processing payment requests',
    ['method', 'endpoint']
)

# Middleware for metrics
@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    method = request.method
    endpoint = request.url.path
    
    try:
        response = await call_next(request)
        status_code = response.status_code
        
        REQUEST_COUNT.labels(method, endpoint, status_code).inc()
        REQUEST_LATENCY.labels(method, endpoint).observe(time.time() - start_time)
        
        return response
    except Exception as e:
        status_code = 500
        REQUEST_COUNT.labels(method, endpoint, status_code).inc()
        raise e

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# Metrics endpoint for Prometheus
@app.get("/metrics")
async def metrics():
    return Response(
        content=generate_latest(),
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
    
    # Create payment record
    payment_id = f"pay_{int(time.time() * 1000)}_{random.randint(1000, 9999)}"
    timestamp = datetime.utcnow().isoformat()
    
    # Write comprehensive data to InfluxDB
    try:
        point = Point("payment")
        
        # Tags
        point.tag("status", status)
        point.tag("currency", payment.currency)
        point.tag("customer_id", payment.customer_id)
        point.tag("merchant_id", f"merch_{random.randint(1, 500):04d}")
        point.tag("payment_method", random.choice(["card", "bank_transfer", "wallet", "crypto"]))
        point.tag("region", random.choice(["EU", "US", "ASIA", "LATAM"]))
        point.tag("card_brand", random.choice(["VISA", "MASTERCARD", "AMEX", "DISCOVER"]))
        point.tag("risk_level", random.choices(
            ["low", "medium", "high", "critical"],
            weights=[0.80, 0.15, 0.04, 0.01]
        )[0])
        
        # Fields
        point.field("amount", float(amount))
        point.field("processing_time", processing_time)
        point.field("network_latency", network_latency)
        point.field("gateway_latency", gateway_latency)
        point.field("error_code", 0 if is_success else random.randint(5001, 5010))
        point.field("retry_count", 0 if is_success else random.randint(1, 3))
        point.field("fraud_score", round(random.uniform(0, 0.05), 3) if is_success 
                    else round(random.uniform(0.70, 1.0), 3))
        point.field("response_time", processing_time * 1000)
        point.field("fee", round(amount * 0.029 + 0.30, 2))  # 2.9% + 0.30€
        point.field("success", 1 if is_success else 0)
        
        point.time(datetime.utcnow())
            
        write_api.write(
            bucket=INFLUX_CONFIG["bucket"],
            org=INFLUX_CONFIG["org"],
            record=point
        )
        logger.info(f"Payment {payment_id} written to InfluxDB: {status}")
    except Exception as e:
        logger.error(f"Failed to write to InfluxDB: {str(e)}")
    
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
    try:
        # This is a simplified example - you'd typically query InfluxDB here
        return {
            "total_payments": 0,  # Replace with actual query
            "success_rate": 1.0,   # Replace with actual calculation
            "avg_processing_time": 0.0  # Replace with actual calculation
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

# Initialize Prometheus instrumentation
instrumentator = Instrumentator()
instrumentator.instrument(app).expose(app, include_in_schema=False)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
