#!/usr/bin/env python3
"""
Script to generate test payment data by calling the Payment API
Generates realistic payment traffic to populate InfluxDB
"""

import requests
import random
import time
from datetime import datetime

API_URL = "http://localhost:8080/api/payments"

# Sample customer IDs for realistic distribution
CUSTOMER_IDS = [f"cust_{i:05d}" for i in range(1, 5001)]

def generate_payment():
    """Generate a single payment request"""
    customer_id = random.choice(CUSTOMER_IDS)
    currency = random.choice(["EUR", "USD", "GBP", "CHF", "JPY"])
    
    # Let the API generate realistic amounts by passing 0
    payload = {
        "amount": 0.0,  # API will generate realistic amount
        "currency": currency,
        "customer_id": customer_id,
        "description": f"Test payment from {customer_id}"
    }
    
    return payload

def main():
    print("🚀 Starting payment generation...")
    print(f"📡 API URL: {API_URL}\n")
    
    total_payments = 0
    successful_payments = 0
    failed_payments = 0
    
    try:
        while True:
            try:
                payload = generate_payment()
                response = requests.post(API_URL, json=payload, timeout=5)
                
                if response.status_code == 200:
                    successful_payments += 1
                    data = response.json()
                    print(f"✅ Payment {data['payment_id']}: {data['amount']} {data['currency']} - {data['status']}")
                else:
                    failed_payments += 1
                    print(f"❌ Payment failed: HTTP {response.status_code}")
                
                total_payments += 1
                
                if total_payments % 10 == 0:
                    print(f"\n📊 Stats: Total={total_payments}, Success={successful_payments}, Failed={failed_payments}\n")
                
                # Random delay between 1-5 seconds to simulate realistic traffic
                time.sleep(random.uniform(1, 5))
                
            except requests.exceptions.RequestException as e:
                print(f"⚠️ Request error: {e}")
                time.sleep(5)
                
    except KeyboardInterrupt:
        print(f"\n\n🛑 Stopped by user")
        print(f"📊 Final Stats:")
        print(f"   Total Payments: {total_payments}")
        print(f"   Successful: {successful_payments}")
        print(f"   Failed: {failed_payments}")

if __name__ == "__main__":
    main()
