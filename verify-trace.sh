#!/bin/bash

echo "=== Verifying Trace Export to Tempo ==="
echo ""

# Send payment request and capture full response
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

echo "Response:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Extract trace ID
TRACE_ID=$(echo "$RESPONSE" | grep -o '"traceId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TRACE_ID" ]; then
  echo "❌ ERROR: No trace ID in response"
  exit 1
fi

echo "✅ Trace ID: $TRACE_ID"
echo ""

# Wait for ingestion
echo "2. Waiting 5 seconds for trace ingestion..."
sleep 5

# Query Tempo
echo "3. Querying Tempo API..."
TEMPO_RESPONSE=$(curl -s "http://localhost:3200/api/traces/$TRACE_ID")

if echo "$TEMPO_RESPONSE" | grep -q "batches"; then
  echo "✅ SUCCESS: Trace found in Tempo!"
  echo ""
  echo "Trace contains $(echo "$TEMPO_RESPONSE" | jq '.batches[0].scopeSpans[0].spans | length' 2>/dev/null || echo '?') span(s)"
else
  echo "❌ FAILED: Trace not found"
  echo "Response: $TEMPO_RESPONSE"
  
  echo ""
  echo "Checking Tempo logs..."
  docker logs tempo --tail 20
fi
