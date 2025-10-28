#!/usr/bin/env python3
"""
eBanking Metrics Exporter - Training Version
Prometheus metrics exporter for eBanking application simulation
Data2AI Academy

Best Practices:
- All metrics include 'environment' label for multi-environment support
- Enables dynamic alert routing based on environment
- Supports production, staging, development, and training environments
"""

import time
import random
import os
from prometheus_client import start_http_server, Counter, Gauge, Histogram, Info
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================
# Environment Configuration (Best Practice)
# ============================================
ENVIRONMENT = os.getenv('ENVIRONMENT', 'training')  # training, development, staging, production
SERVICE_NAME = os.getenv('SERVICE_NAME', 'ebanking-api')
REGION = os.getenv('REGION', 'eu-west-1')
CLUSTER = os.getenv('CLUSTER', 'training-cluster')
APP_VERSION = os.getenv('APP_VERSION', '1.0.0')

logger.info(f"Starting eBanking Exporter - Environment: {ENVIRONMENT}, Service: {SERVICE_NAME}, Version: {APP_VERSION}")

# Application info
app_info = Info('ebanking_app', 'eBanking Application Information')
app_info.info({
    'version': APP_VERSION,
    'environment': ENVIRONMENT,
    'service': SERVICE_NAME,
    'region': REGION,
    'cluster': CLUSTER,
    'organization': 'Data2AI Academy'
})

# ============================================
# Transaction Metrics (with environment label)
# ============================================
transactions_processed = Counter(
    'ebanking_transactions_processed_total',
    'Total number of processed transactions',
    ['transaction_type', 'status', 'channel', 'environment']
)

transaction_amount = Histogram(
    'ebanking_transaction_amount_eur',
    'Transaction amounts in EUR',
    ['transaction_type', 'environment'],
    buckets=[10, 50, 100, 500, 1000, 5000, 10000, 50000]
)

# ============================================
# Session Metrics (with environment label)
# ============================================
active_sessions = Gauge(
    'ebanking_active_sessions',
    'Current number of active user sessions',
    ['environment']
)

session_duration = Histogram(
    'ebanking_session_duration_seconds',
    'User session duration in seconds',
    ['environment'],
    buckets=[60, 300, 600, 1800, 3600, 7200]
)

# ============================================
# Account Metrics (with environment label)
# ============================================
account_balance = Gauge(
    'ebanking_account_balance_total',
    'Total account balance across all accounts',
    ['currency', 'account_type', 'environment']
)

active_accounts = Gauge(
    'ebanking_active_accounts_total',
    'Total number of active accounts',
    ['account_type', 'environment']
)

# ============================================
# API Performance Metrics (with environment label)
# ============================================
request_duration = Histogram(
    'ebanking_request_duration_seconds',
    'Time taken to process API requests',
    ['endpoint', 'method', 'environment'],
    buckets=[0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0]
)

api_requests = Counter(
    'ebanking_api_requests_total',
    'Total number of API requests',
    ['endpoint', 'method', 'status_code', 'environment']
)

# ============================================
# Authentication Metrics (with environment label)
# ============================================
login_attempts = Counter(
    'ebanking_login_attempts_total',
    'Total number of login attempts',
    ['status', 'method', 'environment']
)

failed_login_attempts = Counter(
    'ebanking_failed_login_attempts_total',
    'Total number of failed login attempts',
    ['reason', 'environment']
)

# ============================================
# Error Metrics (with environment label)
# ============================================
api_errors = Counter(
    'ebanking_api_errors_total',
    'Total number of API errors',
    ['error_type', 'severity', 'environment']
)

fraud_alerts = Counter(
    'ebanking_fraud_alerts_total',
    'Total number of fraud alerts',
    ['alert_type', 'severity', 'environment']
)

# ============================================
# Database Metrics (with environment label)
# ============================================
database_connections = Gauge(
    'ebanking_database_connections',
    'Current number of database connections',
    ['pool', 'environment']
)

database_query_duration = Histogram(
    'ebanking_database_query_duration_seconds',
    'Database query execution time',
    ['query_type', 'environment'],
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
)
  
# ============================================
# Business Metrics (with environment label)
# ============================================
daily_revenue = Gauge(
    'ebanking_daily_revenue_eur',
    'Daily revenue in EUR',
    ['environment']
)

customer_satisfaction = Gauge(
    'ebanking_customer_satisfaction_score',
    'Customer satisfaction score (0-100)',
    ['environment']
)


def simulate_realistic_metrics():
    """Simulate realistic eBanking metrics for training purposes with environment-specific behavior"""
    logger.info(f"Starting eBanking metrics simulation for {ENVIRONMENT} environment...")
    
    # Configuration
    transaction_types = ['transfer', 'payment', 'withdrawal', 'deposit', 'bill_payment']
    statuses = ['success', 'failed', 'pending', 'cancelled']
    channels = ['web', 'mobile', 'atm', 'branch']
    currencies = ['EUR', 'USD', 'GBP', 'CHF']
    account_types = ['checking', 'savings', 'business', 'investment']
    endpoints = [
        '/api/v1/transfer',
        '/api/v1/balance',
        '/api/v1/transactions',
        '/api/v1/login',
        '/api/v1/accounts',
        '/api/v1/cards',
        '/api/v1/statements'
    ]
    methods = ['GET', 'POST', 'PUT', 'DELETE']
    error_types = ['timeout', 'validation', 'authentication', 'network', 'database']
    fraud_types = ['suspicious_amount', 'unusual_location', 'velocity', 'pattern_anomaly']
    
    # ============================================
    # Environment-Specific Configuration
    # ============================================
    if ENVIRONMENT == 'production':
        # Production: High volume, low errors, strict SLAs
        transaction_multiplier = 5.0
        error_rate = 0.01  # 1% error rate
        fraud_rate = 0.005  # 0.5% fraud rate
        base_revenue = 250000
        base_sessions = 500
        success_rate_weights = [97, 2, 0.5, 0.5]  # 97% success
        logger.info("🏭 PRODUCTION mode: High volume, low errors, strict SLAs")
        
    elif ENVIRONMENT == 'staging':
        # Staging: Medium volume, slightly higher errors, pre-production testing
        transaction_multiplier = 3.0
        error_rate = 0.03  # 3% error rate
        fraud_rate = 0.01  # 1% fraud rate
        base_revenue = 150000
        base_sessions = 300
        success_rate_weights = [94, 4, 1, 1]  # 94% success
        logger.info("🧪 STAGING mode: Medium volume, testing scenarios")
        
    elif ENVIRONMENT == 'development':
        # Development: Low volume, higher errors, active development
        transaction_multiplier = 1.5
        error_rate = 0.08  # 8% error rate
        fraud_rate = 0.02  # 2% fraud rate
        base_revenue = 75000
        base_sessions = 150
        success_rate_weights = [88, 7, 3, 2]  # 88% success
        logger.info("💻 DEVELOPMENT mode: Low volume, higher error rates for testing")
        
    else:  # training
        # Training: Consistent volume, balanced for learning
        transaction_multiplier = 2.0
        error_rate = 0.05  # 5% error rate
        fraud_rate = 0.015  # 1.5% fraud rate
        base_revenue = 100000
        base_sessions = 200
        success_rate_weights = [90, 7, 2, 1]  # 90% success
        logger.info("🎓 TRAINING mode: Balanced metrics for learning")
    
    # Simulation state
    iteration = 0
    
    while True:
        try:
            iteration += 1
            
            # Simulate transaction processing (environment-specific volume)
            num_transactions = int(random.randint(2, 5) * transaction_multiplier)
            for _ in range(num_transactions):
                trans_type = random.choice(transaction_types)
                # Use environment-specific success rates
                status = random.choices(statuses, weights=success_rate_weights)[0]
                channel = random.choice(channels)
                
                transactions_processed.labels(
                    transaction_type=trans_type,
                    status=status,
                    channel=channel,
                    environment=ENVIRONMENT
                ).inc()
                
                # Transaction amount (realistic distribution)
                if trans_type == 'withdrawal':
                    amount = random.choice([20, 50, 100, 200, 500])
                elif trans_type == 'transfer':
                    amount = random.uniform(10, 10000)
                elif trans_type == 'bill_payment':
                    amount = random.uniform(20, 500)
                else:
                    amount = random.uniform(10, 5000)
                
                transaction_amount.labels(transaction_type=trans_type, environment=ENVIRONMENT).observe(amount)
            
            # Simulate active sessions (varies by time of day simulation, environment-specific)
            hour_factor = (iteration % 24) / 24.0
            sessions = base_sessions + int(base_sessions * abs(0.5 - hour_factor) * 2)  # Peak at noon
            active_sessions.labels(environment=ENVIRONMENT).set(sessions + random.randint(-20, 20))
            
            # Simulate session durations
            session_duration.labels(environment=ENVIRONMENT).observe(random.uniform(60, 3600))
            
            # Simulate account balances
            for currency in currencies:
                for acc_type in account_types:
                    balance = random.uniform(1000, 500000)
                    account_balance.labels(
                        currency=currency,
                        account_type=acc_type,
                        environment=ENVIRONMENT
                    ).set(balance)
            
            # Simulate active accounts
            for acc_type in account_types:
                count = random.randint(100, 1000)
                active_accounts.labels(account_type=acc_type, environment=ENVIRONMENT).set(count)
            
            # Simulate API requests (3-8 requests per iteration)
            num_requests = random.randint(3, 8)
            for _ in range(num_requests):
                endpoint = random.choice(endpoints)
                method = random.choice(methods)
                # 95% success (200), 3% client error (400), 2% server error (500)
                status_code = random.choices(['200', '400', '404', '500'], weights=[95, 2, 1, 2])[0]
                
                # Request duration (faster for GET, slower for POST)
                if method == 'GET':
                    duration = random.uniform(0.01, 0.5)
                else:
                    duration = random.uniform(0.1, 2.0)
                
                request_duration.labels(endpoint=endpoint, method=method, environment=ENVIRONMENT).observe(duration)
                api_requests.labels(
                    endpoint=endpoint,
                    method=method,
                    status_code=status_code,
                    environment=ENVIRONMENT
                ).inc()
            
            # Simulate login attempts
            login_status = random.choices(['success', 'failed'], weights=[97, 3])[0]
            login_method = random.choice(['password', 'biometric', 'otp', 'sso'])
            login_attempts.labels(status=login_status, method=login_method, environment=ENVIRONMENT).inc()
            
            if login_status == 'failed':
                reason = random.choice(['invalid_credentials', 'account_locked', 'expired_session'])
                failed_login_attempts.labels(reason=reason, environment=ENVIRONMENT).inc()
            
            # Simulate occasional errors (environment-specific rate)
            if random.random() < error_rate:
                error_type = random.choice(error_types)
                # Production has fewer critical errors
                if ENVIRONMENT == 'production':
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[50, 35, 13, 2])[0]
                elif ENVIRONMENT == 'staging':
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[40, 35, 20, 5])[0]
                else:  # development or training
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[30, 35, 25, 10])[0]
                api_errors.labels(error_type=error_type, severity=severity, environment=ENVIRONMENT).inc()
            
            # Simulate fraud alerts (environment-specific rate)
            if random.random() < fraud_rate:
                alert_type = random.choice(fraud_types)
                # Production has more critical fraud alerts
                if ENVIRONMENT == 'production':
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[20, 30, 35, 15])[0]
                elif ENVIRONMENT == 'staging':
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[30, 40, 25, 5])[0]
                else:  # development or training
                    severity = random.choices(['low', 'medium', 'high', 'critical'], weights=[40, 35, 20, 5])[0]
                fraud_alerts.labels(alert_type=alert_type, severity=severity, environment=ENVIRONMENT).inc()
            
            # Simulate database connections
            for pool in ['primary', 'replica', 'analytics']:
                connections = random.randint(5, 50)
                database_connections.labels(pool=pool, environment=ENVIRONMENT).set(connections)
            
            # Simulate database queries
            query_types = ['select', 'insert', 'update', 'delete']
            for query_type in query_types:
                duration = random.uniform(0.001, 0.5)
                database_query_duration.labels(query_type=query_type, environment=ENVIRONMENT).observe(duration)
            
            # Simulate business metrics (environment-specific)
            revenue_variation = random.uniform(0.9, 1.1)
            daily_revenue.labels(environment=ENVIRONMENT).set(base_revenue * revenue_variation)
            
            # Customer satisfaction (environment-specific ranges)
            if ENVIRONMENT == 'production':
                satisfaction = random.uniform(92, 98)  # Higher satisfaction in production
            elif ENVIRONMENT == 'staging':
                satisfaction = random.uniform(88, 96)  # Similar to production
            elif ENVIRONMENT == 'development':
                satisfaction = random.uniform(80, 92)  # Lower in development (testing)
            else:  # training
                satisfaction = random.uniform(85, 95)  # Balanced for training
            customer_satisfaction.labels(environment=ENVIRONMENT).set(satisfaction)
            
            # Log progress every 100 iterations
            if iteration % 100 == 0:
                logger.info(f"Metrics simulation running... (iteration {iteration})")
            
            # Wait before next iteration (0.5-2 seconds)
            time.sleep(random.uniform(0.5, 2.0))
            
        except Exception as e:
            logger.error(f"Error in metrics simulation: {e}")
            time.sleep(1)


if __name__ == '__main__':
    # Start Prometheus metrics server on port 9200
    port = 9200
    logger.info("=" * 60)
    logger.info("eBanking Metrics Exporter - Training Version")
    logger.info("Data2AI Academy")
    logger.info("=" * 60)
    logger.info(f"Starting metrics server on port {port}")
    
    start_http_server(port)
    logger.info(f"✓ Metrics available at http://0.0.0.0:{port}/metrics")
    logger.info("✓ Starting realistic eBanking metrics simulation...")
    logger.info("=" * 60)
    
    # Start metrics simulation
    simulate_realistic_metrics()
