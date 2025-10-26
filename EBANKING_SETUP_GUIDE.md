# 🏦 E-Banking Financial Observability - Setup Guide

## 📋 Overview

This guide will help you set up a complete **E-Banking Financial Observability Stack** with **real-time fraud detection** capabilities using:

- **MS SQL Server 2022** - Financial transaction database
- **Grafana** - Visualization and dashboards
- **Prometheus** - Metrics collection
- **InfluxDB** - Time-series data
- **Loki** - Log aggregation

## 🎯 Business Scenario

**Institution Profile:**
- Medium-sized financial institution
- **500,000+** daily transactions
- **25,000** active clients
- **100** merchants
- **50** field agents
- **24/7** monitoring for fraud detection

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have installed:
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2.0+
- At least 8GB RAM available
- 20GB free disk space

### 2. Clone and Configure

```bash
# Navigate to the observability stack directory
cd "d:\Data2AI Academy\Grafana\observability-stack"

# Copy environment template
cp .env.example .env

# Edit .env file with your passwords (optional - defaults are provided)
notepad .env
```

### 3. Start the Stack

```bash
# Start all services
docker-compose up -d

# Or start MS SQL Server only
docker-compose up -d mssql

# Check service status
docker-compose ps
```

### 4. Wait for Initialization

The MS SQL Server container will automatically:
1. Start SQL Server (30 seconds)
2. Create the `EBankingDB` database
3. Create all tables and schemas
4. Create stored procedures for fraud detection
5. Seed sample data (1,000 clients, 5,000 transactions)

**Monitor initialization:**
```bash
docker logs -f mssql_ebanking
```

Wait for: `"Data seeding completed successfully!"`

### 5. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin / GrafanaSecure123!Change@Me |
| **MS SQL Server** | localhost:1433 | sa / EBanking@Secure123! |
| **Prometheus** | http://localhost:9090 | - |
| **InfluxDB** | http://localhost:8086 | admin / InfluxSecure123!Change@Me |

## 📊 Grafana Dashboard Setup

### Automatic Setup (Recommended)

The MS SQL Server datasource and E-Banking dashboard are **automatically provisioned** when Grafana starts.

1. Open Grafana: http://localhost:3000
2. Login with admin credentials
3. Navigate to **Dashboards** → **E-Banking** folder
4. Open **"E-Banking Fraud Detection Dashboard"**

### Manual Setup (If needed)

If automatic provisioning fails:

1. **Add Data Source:**
   - Go to Configuration → Data Sources → Add data source
   - Select **Microsoft SQL Server**
   - Configure:
     - **Name:** MS SQL Server - E-Banking
     - **Host:** mssql:1433
     - **Database:** EBankingDB
     - **User:** sa
     - **Password:** EBanking@Secure123!
     - **Encrypt:** false
   - Click **Save & Test**

2. **Import Dashboard:**
   - Go to Dashboards → Import
   - Upload: `grafana/provisioning/dashboards/ebanking-fraud-detection.json`
   - Select datasource: **MS SQL Server - E-Banking**
   - Click **Import**

## 🔍 Verify Installation

### Test Database Connection

```bash
# Connect to SQL Server
docker exec -it mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!"
```

```sql
-- Check database
USE EBankingDB;
GO

-- Verify data
SELECT COUNT(*) AS ClientCount FROM Clients;
SELECT COUNT(*) AS MerchantCount FROM Merchants;
SELECT COUNT(*) AS TransactionCount FROM Transactions;
SELECT COUNT(*) AS FraudAlertCount FROM FraudAlerts;

-- Test stored procedure
EXEC sp_GetDashboardMetrics @TimeRangeMinutes = 60;
GO

-- Exit
EXIT
```

Expected results:
- Clients: 1,000
- Merchants: 100
- Transactions: 5,000
- Fraud Alerts: Variable (based on flagged transactions)

## 🚨 Fraud Detection Features

### Real-Time Detection Mechanisms

#### 1. **Velocity-Based Fraud**
Detects rapid transaction patterns:
- **Trigger:** 5+ transactions in 5 minutes
- **Action:** Creates alert, increases client risk score
- **Severity:** High

#### 2. **Location-Based Fraud**
Detects impossible travel:
- **Trigger:** >500km distance in <60 minutes
- **Action:** Flags transaction, creates critical alert
- **Severity:** Critical

#### 3. **Amount-Based Fraud**
Detects unusual amounts:
- **Trigger:** Amount >3 standard deviations from client average
- **Action:** Creates alert, updates fraud score
- **Severity:** High

### Test Fraud Detection

```sql
USE EBankingDB;
GO

-- Simulate velocity fraud (multiple rapid transactions)
DECLARE @ClientID INT = 1;
DECLARE @Counter INT = 1;

WHILE @Counter <= 6
BEGIN
    DECLARE @TxnID BIGINT;
    EXEC sp_ProcessTransaction 
        @ClientID = @ClientID,
        @TransactionType = 'Transfer',
        @Amount = 100.00,
        @Channel = 'Mobile',
        @TransactionID = @TxnID OUTPUT;
    
    SET @Counter = @Counter + 1;
END

-- Check fraud alerts
SELECT * FROM FraudAlerts WHERE ClientID = @ClientID ORDER BY DetectedAt DESC;
GO
```

## 📈 Dashboard Panels

The E-Banking Fraud Detection Dashboard includes:

### **Real-Time Metrics**
1. **Transactions (Last Hour)** - Gauge showing transaction volume
2. **Open Fraud Alerts** - Active fraud cases requiring attention
3. **Transaction Volume (24h)** - Time-series trend

### **Distribution Analysis**
4. **Transactions by Channel** - Pie chart (Mobile, Web, ATM, POS, Agent)
5. **Transaction Status Distribution** - Completed, Failed, Flagged

### **Risk Management**
6. **Top Risky Clients** - Table with risk scores >50
7. **Fraud Alerts by Severity** - Time-series (Critical, High, Medium, Low)
8. **Recent Fraud Alerts** - Latest 20 alerts with details

### **Performance Monitoring**
9. **Average Processing Time** - Transaction processing latency
10. **Transaction Volume by Amount** - 7-day financial volume

## 🔧 Advanced Configuration

### Scale to Production Volumes

To generate 25,000 clients and more transactions:

1. Edit `mssql/init/03-seed-data.sql`
2. Change counters:
   ```sql
   WHILE @ClientCounter <= 25000  -- Change from 1000 to 25000
   WHILE @TxnCounter <= 50000     -- Change from 5000 to 50000
   ```
3. Rebuild container:
   ```bash
   docker-compose down mssql
   docker volume rm observability-stack_mssql_data
   docker-compose up -d mssql
   ```

### Custom Fraud Rules

Add custom fraud detection logic in `02-create-stored-procedures.sql`:

```sql
CREATE OR ALTER PROCEDURE sp_DetectCustomFraud
    @TransactionID BIGINT
AS
BEGIN
    -- Your custom fraud detection logic
    -- Example: Detect transactions from blacklisted IPs
    
    DECLARE @IPAddress NVARCHAR(50);
    SELECT @IPAddress = IPAddress FROM Transactions WHERE TransactionID = @TransactionID;
    
    IF @IPAddress IN ('192.168.1.100', '10.0.0.50') -- Blacklist
    BEGIN
        INSERT INTO FraudAlerts (...)
        VALUES (...);
    END
END
GO
```

### Performance Tuning

```sql
-- Add indexes for better query performance
CREATE INDEX IX_Transactions_ClientID_Date 
ON Transactions(ClientID, TransactionDate) 
INCLUDE (Amount, Status);

-- Update statistics
UPDATE STATISTICS Transactions;
UPDATE STATISTICS FraudAlerts;

-- Rebuild fragmented indexes
ALTER INDEX ALL ON Transactions REBUILD;
```

## 🛡️ Security Best Practices

### 1. Change Default Passwords

```bash
# Edit .env file
MSSQL_SA_PASSWORD=YourStrongPassword123!@#
```

### 2. Enable SQL Server Encryption

Edit `docker-compose.yml`:
```yaml
environment:
  - MSSQL_ENABLE_TLS=true
  - MSSQL_TLS_CERT=/path/to/cert.pem
  - MSSQL_TLS_KEY=/path/to/key.pem
```

### 3. Create Limited-Privilege Users

```sql
USE EBankingDB;
GO

-- Create read-only user for Grafana
CREATE LOGIN grafana_reader WITH PASSWORD = 'GrafanaReadOnly123!';
CREATE USER grafana_reader FOR LOGIN grafana_reader;
GRANT SELECT ON SCHEMA::dbo TO grafana_reader;
GRANT EXECUTE ON SCHEMA::dbo TO grafana_reader;
GO
```

Update Grafana datasource to use `grafana_reader` instead of `sa`.

### 4. Network Isolation

```yaml
# docker-compose.yml
services:
  mssql:
    networks:
      - backend  # Separate from public network
```

## 📊 Sample Queries for Custom Dashboards

### Transaction Success Rate
```sql
SELECT 
    CAST(TransactionDate AS DATE) AS Date,
    COUNT(*) AS Total,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
    CAST(SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SuccessRate
FROM Transactions
WHERE TransactionDate >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(TransactionDate AS DATE)
ORDER BY Date;
```

### Merchant Performance
```sql
SELECT TOP 10
    m.MerchantName,
    m.Category,
    COUNT(t.TransactionID) AS TransactionCount,
    SUM(t.Amount) AS Revenue,
    AVG(t.Amount) AS AvgTransactionAmount
FROM Merchants m
JOIN Transactions t ON m.MerchantID = t.MerchantID
WHERE t.TransactionDate >= DATEADD(DAY, -7, GETDATE())
    AND t.Status = 'Completed'
GROUP BY m.MerchantName, m.Category
ORDER BY Revenue DESC;
```

### Fraud Detection Effectiveness
```sql
SELECT 
    AlertType,
    COUNT(*) AS TotalAlerts,
    SUM(CASE WHEN Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved,
    SUM(CASE WHEN Status = 'Open' THEN 1 ELSE 0 END) AS Open,
    AVG(DATEDIFF(MINUTE, DetectedAt, ResolvedAt)) AS AvgResolutionTimeMinutes
FROM FraudAlerts
WHERE DetectedAt >= DATEADD(DAY, -30, GETDATE())
GROUP BY AlertType;
```

### Geographic Transaction Distribution
```sql
SELECT 
    Location,
    COUNT(*) AS TransactionCount,
    SUM(Amount) AS TotalAmount,
    AVG(FraudScore) AS AvgFraudScore
FROM Transactions
WHERE TransactionDate >= DATEADD(DAY, -7, GETDATE())
    AND Location IS NOT NULL
GROUP BY Location
ORDER BY TransactionCount DESC;
```

## 🔄 Backup and Restore

### Backup Database
```bash
# Create backup
docker exec mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -Q "BACKUP DATABASE EBankingDB TO DISK = '/backup/EBankingDB_$(date +%Y%m%d).bak'"

# Copy backup to host
docker cp mssql_ebanking:/backup/EBankingDB_20241021.bak ./backups/
```

### Restore Database
```bash
# Copy backup to container
docker cp ./backups/EBankingDB_20241021.bak mssql_ebanking:/backup/

# Restore
docker exec mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -Q "RESTORE DATABASE EBankingDB FROM DISK = '/backup/EBankingDB_20241021.bak' WITH REPLACE"
```

## 🐛 Troubleshooting

### Issue: SQL Server won't start

**Solution:**
```bash
# Check logs
docker logs mssql_ebanking

# Verify password meets complexity requirements
# Must contain: uppercase, lowercase, numbers, special chars
# Minimum 8 characters

# Restart container
docker-compose restart mssql
```

### Issue: Grafana can't connect to SQL Server

**Solution:**
```bash
# Test network connectivity
docker exec grafana ping mssql

# Verify SQL Server is listening
docker exec mssql_ebanking netstat -an | grep 1433

# Check datasource configuration in Grafana UI
# Ensure using 'mssql:1433' not 'localhost:1433'
```

### Issue: No data in dashboard

**Solution:**
```sql
-- Verify data exists
USE EBankingDB;
SELECT COUNT(*) FROM Transactions WHERE TransactionDate >= DATEADD(HOUR, -24, GETDATE());

-- If no recent data, generate some
EXEC sp_ProcessTransaction 
    @ClientID = 1,
    @TransactionType = 'Transfer',
    @Amount = 100.00,
    @Channel = 'Mobile',
    @TransactionID = @TxnID OUTPUT;
```

### Issue: Slow query performance

**Solution:**
```sql
-- Check index fragmentation
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30;

-- Rebuild indexes
ALTER INDEX ALL ON Transactions REBUILD;
```

## 📚 Additional Resources

- [MS SQL Server Documentation](https://docs.microsoft.com/en-us/sql/sql-server/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Fraud Detection Patterns](https://www.microsoft.com/security)

## 🤝 Support

For issues or questions:
1. Check logs: `docker logs mssql_ebanking`
2. Verify configuration: `docker-compose config`
3. Review README: `mssql/README.md`

## 📝 Next Steps

1. ✅ Start the stack
2. ✅ Verify database initialization
3. ✅ Access Grafana dashboard
4. ✅ Test fraud detection
5. 🔄 Customize alerts and thresholds
6. 🔄 Scale to production volumes
7. 🔄 Implement custom fraud rules
8. 🔄 Set up automated backups

---

**Happy Monitoring! 🎉**
