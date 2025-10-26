#!/bin/sh
set -e

# Wait for InfluxDB to be ready
echo "⏳ Waiting for InfluxDB to start..."
until curl -s http://influxdb:8086/health | grep '"status":"pass"' > /dev/null; do
  echo "Waiting for InfluxDB to be ready..."
  sleep 5
done

echo "✅ InfluxDB is ready."

# Ensure all required env vars are set
: "${INFLUXDB_ORG:?Environment variable INFLUXDB_ORG not set}"
: "${INFLUXDB_TOKEN:?Environment variable INFLUXDB_TOKEN not set}"
: "${INFLUXDB_USER:?Environment variable INFLUXDB_USER not set}"
: "${INFLUXDB_PASSWORD:?Environment variable INFLUXDB_PASSWORD not set}"

# Check if bucket already exists
if influx bucket list --org "$INFLUXDB_ORG" --token "$INFLUXDB_TOKEN" | grep -q "payments"; then
  echo "🪣 Bucket 'payments' already exists."
else
  echo "🪣 Creating bucket 'payments'..."
  influx bucket create \
    --name payments \
    --org "$INFLUXDB_ORG" \
    --retention 1w \
    --token "$INFLUXDB_TOKEN"
fi

# Get the bucket ID dynamically
BUCKET_ID=$(influx bucket list --org "$INFLUXDB_ORG" --token "$INFLUXDB_TOKEN" | awk '/payments/ {print $1}' | head -n 1)

# Check if v1 auth already exists
if influx v1 auth list --org "$INFLUXDB_ORG" --token "$INFLUXDB_TOKEN" | grep -q "$INFLUXDB_USER"; then
  echo "🔐 V1 auth for user '$INFLUXDB_USER' already exists."
else
  echo "🔐 Creating V1 auth user '$INFLUXDB_USER'..."
  influx v1 auth create \
    --org "$INFLUXDB_ORG" \
    --username "$INFLUXDB_USER" \
    --password "$INFLUXDB_PASSWORD" \
    --read-bucket "$BUCKET_ID" \
    --write-bucket "$BUCKET_ID" \
    --token "$INFLUXDB_TOKEN"
fi

echo "🎯 InfluxDB initialization complete!"
