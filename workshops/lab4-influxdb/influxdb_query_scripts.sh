#!/bin/bash
# =========================================================
# InfluxDB Analytic Query Scripts
# Author: Data2AI Engineering
# Description: Run common analytic queries directly inside
#              an InfluxDB container using InfluxQL or Flux.
# =========================================================

# CONFIGURATION
INFLUX_HOST="http://localhost:8086"
INFLUX_ORG="myorg"
INFLUX_BUCKET="payments"
INFLUX_TOKEN="my-super-secret-auth-token"
INFLUX_CMD="influx query --org $INFLUX_ORG --host $INFLUX_HOST --token $INFLUX_TOKEN"

# =========================================================
# 1. List all buckets
# =========================================================
echo "Listing all buckets..."
$INFLUX_CMD 'buckets()' | tee results_buckets.txt

# =========================================================
# 2. Total payment count (last 24h)
# =========================================================
echo "Counting total payments in the last 24h..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -24h)
  |> count()' | tee results_payment_count.txt

# =========================================================
# 3. Average processing time per hour
# =========================================================
echo "Calculating average processing time per hour..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "payment")
  |> filter(fn: (r) => r._field == "processing_time")
  |> aggregateWindow(every: 1h, fn: mean)
  |> yield(name: "avg_processing_time")' | tee results_avg_processing_time.txt

# =========================================================
# 4. Success vs Failure Count
# =========================================================
echo "Calculating success vs failure rates..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "payment")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["status"])
  |> count()' | tee results_success_rate.txt

# =========================================================
# 5. Total payments per currency
# =========================================================
echo "Counting payments per currency..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "payment")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["currency"])
  |> sum()' | tee results_currency_sum.txt

# =========================================================
# 6. Daily payment volume trend
# =========================================================
echo "Generating daily payment volume trend..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "payment")
  |> filter(fn: (r) => r._field == "amount")
  |> aggregateWindow(every: 1d, fn: sum)
  |> yield(name: "daily_volume")' | tee results_daily_volume.txt

# =========================================================
# 7. Top 10 customers by payment volume
# =========================================================
echo "Getting top 10 customers by total payment volume..."
$INFLUX_CMD 'from(bucket:"payments")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "payment")
  |> filter(fn: (r) => r._field == "amount")
  |> group(columns: ["customer_id"])
  |> sum()
  |> sort(columns:["_value"], desc: true)
  |> limit(n:10)' | tee results_top_customers.txt

# =========================================================
# 8. Payment failure rate percentage
# =========================================================
echo "Calculating payment failure rate percentage..."
$INFLUX_CMD 'import "math"
success = from(bucket:"payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r.status == "success")
  |> count()
failures = from(bucket:"payments")
  |> range(start: -7d)
  |> filter(fn: (r) => r.status == "failed")
  |> count()
join(tables: {success: success, failures: failures}, on: ["_time"])
  |> map(fn: (r) => ({r with failure_rate: float(v: r.failures._value) / float(v: (r.success._value + r.failures._value)) * 100.0 }))' | tee results_failure_rate.txt

# =========================================================
# Done
# =========================================================
echo "All analytic queries executed successfully. Results saved as text files."
