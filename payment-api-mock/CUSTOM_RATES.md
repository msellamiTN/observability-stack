# Custom Payment Success/Failure/Pending Rates

## Overview
The payment API and simulation script now support configurable success, failure, and pending rates via custom headers.

## How It Works

### API Changes (`main.py`)
The API now accepts three custom headers:
- `X-Success-Rate`: Percentage of successful payments (0-100)
- `X-Failure-Rate`: Percentage of failed payments (0-100)
- `X-Pending-Rate`: Percentage of pending payments (0-100)

**Default rates:**
- Success: 84%
- Failure: 1%
- Pending: 15%

The API automatically normalizes the rates to ensure they sum to 100%.

### Simulation Script Changes (`simulate.sh`)
The script now accepts custom rate parameters after the standard arguments.

## Usage Examples

### Example 1: Default Rates
```bash
./simulate.sh 100 normal 5
```
Uses default rates: 84% success, 1% failure, 15% pending

### Example 2: Your Requested Configuration
```bash
./simulate.sh 100 normal 5 success 70 failure 10 pending 20
```
Custom rates: 70% success, 10% failure, 20% pending

### Example 3: High Success Rate
```bash
./simulate.sh 500 peak 10 success 90 failure 5 pending 5
```
Peak mode with 90% success rate

### Example 4: High Failure Rate for Testing
```bash
./simulate.sh 200 burst 3 success 50 failure 30 pending 20
```
Burst mode with 50% success, 30% failure, 20% pending

### Example 5: Stress Test with Custom Rates
```bash
./simulate.sh 1000 stress 20 success 60 failure 25 pending 15
```
Stress test with 60% success, 25% failure, 15% pending

## Command Format
```
./simulate.sh [num_requests] [mode] [max_concurrent] [success N] [failure N] [pending N]
```

**Parameters:**
- `num_requests`: Number of payment requests to simulate (default: 100)
- `mode`: Simulation mode - normal, burst, peak, stress, realistic, failure (default: normal)
- `max_concurrent`: Maximum concurrent requests (default: 5)
- `success N`: Success rate percentage (optional, default: 84)
- `failure N`: Failure rate percentage (optional, default: 1)
- `pending N`: Pending rate percentage (optional, default: 15)

## Notes
- Rates are automatically normalized by the API if they don't sum to 100%
- You can specify any combination of success/failure/pending parameters
- Unspecified rates will use their default values
- The rates apply to all requests in the simulation
- Custom rates work with all simulation modes (normal, burst, peak, stress, realistic, failure)

## Testing the Feature

1. Start the payment API:
```bash
cd payment-api-mock
python main.py
```

2. Run a simulation with custom rates:
```bash
./simulate.sh 100 normal 5 success 70 failure 10 pending 20
```

3. Check the output banner to verify your custom rates are applied:
```
========================================
🚀 Payment API Simulation
========================================
API URL:          http://localhost:8080/api/payments
Requests:         100
Mode:             normal
Max Concurrent:   5
Success Rate:     70%
Failure Rate:     10%
Pending Rate:     20%
========================================
```

4. Review the final statistics to confirm the actual distribution matches your configuration.
