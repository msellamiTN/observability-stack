# Payment API Mock

A mock payment processing service that simulates real-time banking transactions and exposes Prometheus metrics.

## Features

- RESTful API for processing payments
- Real-time transaction simulation
- Comprehensive Prometheus metrics
- Health check endpoint
- Request logging

## API Endpoints

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics
- `POST /api/payments` - Process payment

## Running the Simulation

1. Make the simulation script executable:
   ```bash
   chmod +x simulate.sh
   ```

2. Run the simulation (default: 100 requests with random delays up to 2 seconds):
   ```bash
   ./simulate.sh
   ```

### Customizing the Simulation

You can customize the simulation by setting environment variables:

```bash
# Run 500 requests with up to 1 second delay between them
NUM_REQUESTS=500 MAX_DELAY=1 ./simulate.sh

# Target a different API endpoint
API_URL="http://production-api:8080/api/payments" ./simulate.sh
```

## Metrics

The service exposes the following Prometheus metrics:

- `payment_requests_total` - Total payment requests (with status and type labels)
- `payment_amount` - Histogram of payment amounts by currency
- `payment_duration_seconds` - Processing time histogram
- `active_payments` - Gauge of currently processing payments

## Development

### Prerequisites

- Node.js 14+
- Docker (for containerized deployment)

### Running Locally

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the service:
   ```bash
   npm start
   # or with nodemon for development
   npm run dev
   ```

### Building the Docker Image

```bash
docker build -t payment-api-mock .
```

## License

MIT
