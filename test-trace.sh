#!/bin/bash
cd ~/Grafana-Stack/observability-stack

# Pull the latest changes
git pull

# Restart Tempo with new receiver configuration
sudo docker compose restart tempo

# Wait for Tempo to start
sleep 5

# Verify Tempo is listening on OTLP ports
sudo docker compose exec tempo ss -tlnp | grep -E '4317|4318'

# Recreate payment API with new environment variables
sudo docker compose up -d --force-recreate payment-api_instrumented

# Wait for service to be healthy
sleep 10

# Test connectivity from payment API to Tempo
sudo docker compose exec payment-api_instrumented bash -lc "timeout 2 bash -c '</dev/tcp/tempo/4317' && echo ok || echo fail"

# Run the trace verification script
sudo ./test-trace.sh
echo "=== Testing Payment API Trace Generation ==="
echo ""

# Generate a payment transaction
echo "1. Sending payment request..."
RESPONSE=$(curl -s -X POST http://localhost:8888/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.50,
    "currency": "EUR",
    "paymentMethod": "card",
    "cardBrand": "VISA",
    "userId": "U12345",
    "region": "EU_WEST"
  }')

echo "Response: $RESPONSE"
echo ""

# Extract trace ID from response
TRACE_ID=$(echo $RESPONSE | grep -o '"traceId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TRACE_ID" ]; then
  echo "❌ ERROR: No trace ID found in response"
  exit 1
fi

echo "✅ Trace ID: $TRACE_ID"
echo ""

# Wait for trace to be ingested
echo "2. Waiting 5 seconds for trace ingestion..."
sleep 5

# Query Tempo for the trace
echo "3. Querying Tempo for trace..."
TEMPO_RESPONSE=$(curl -s "http://localhost:3200/api/traces/$TRACE_ID")

if echo "$TEMPO_RESPONSE" | grep -q "batches"; then
  echo "✅ SUCCESS: Trace found in Tempo!"
  echo ""
  echo "Trace data:"
  echo "$TEMPO_RESPONSE" | jq '.' 2>/dev/null || echo "$TEMPO_RESPONSE"
else
  echo "❌ FAILED: Trace not found in Tempo"
  echo "Response: $TEMPO_RESPONSE"
  exit 1
fi
