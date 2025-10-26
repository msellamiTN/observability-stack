# MS SQL Server - E-Banking Financial Observability

## 📊 Overview

This MS SQL Server instance is configured for **real-time financial observability** and **fraud detection** in an e-banking environment.

### Business Context
- **Institution Type**: Medium-sized Financial Institution
- **Daily Transactions**: 500,000+
- **Active Clients**: 25,000
- **Merchants**: 100
- **Field Agents**: 50
- **Monitoring**: 24/7 operational health and fraud detection

## 🏗️ Database Schema

### Core Tables

#### 1. **Clients** (25,000 active users)
- Client profiles with KYC status
- Risk scoring (0-100)
- Account types: Individual, Business, Premium

#### 2. **Merchants** (100 merchants)
- Merchant profiles across 12 categories
- Risk levels: Low, Medium, High
- Geographic distribution

#### 3. **FieldAgents** (50 agents)
- Regional field agent network
- Agent performance tracking

#### 4. **Transactions** (500,000+ daily)
- Real-time transaction processing
- Multi-channel support: Mobile, Web, ATM, POS, Agent
- Fraud scoring and flagging
- Geographic tracking (lat/long)

#### 5. **FraudAlerts**
- Real-time fraud detection alerts
- Severity levels: Low, Medium, High, Critical
- Alert types: Velocity, Location, Amount, Pattern

#### 6. **AccountBalances**
- Real-time balance tracking
- Multiple account types

#### 7. **SystemMetrics**
- Performance monitoring
- Availability tracking
- Error rate monitoring

#### 8. **AuditLog**
- Complete audit trail
- Compliance tracking

## 🚨 Fraud Detection Scenarios

### Scenario 1: Real-Time Fraud Detection

The system implements multiple fraud detection mechanisms:

#### **Velocity-Based Detection** (`sp_DetectVelocityFraud`)
- Detects multiple transactions in short time windows
- Default: 5+ transactions in 5 minutes triggers alert
- Automatically increases client risk score

#### **Location-Based Detection** (`sp_DetectLocationFraud`)
- Detects impossible travel patterns
- Example: >500km distance in <60 minutes
- Uses Haversine formula for distance calculation

#### **Amount-Based Detection** (`sp_DetectAmountFraud`)
- Statistical anomaly detection
- Flags transactions >3 standard deviations from client average
- Considers 30-day transaction history

### Scenario 2: Transaction Processing

**Main Procedure**: `sp_ProcessTransaction`

Features:
- ✅ Atomic transaction processing
- ✅ Real-time fraud checks
- ✅ Performance tracking (processing time in ms)
- ✅ Automatic balance updates
- ✅ Transaction status management

## 📈 Grafana Dashboard Queries

### Key Metrics Stored Procedures

#### 1. **Dashboard Metrics** (`sp_GetDashboardMetrics`)
```sql
EXEC sp_GetDashboardMetrics @TimeRangeMinutes = 60;
```

Returns:
- Transaction counts (total, completed, failed, flagged)
- Total and average amounts
- Average processing time
- Fraud alert statistics
- Channel distribution
- Top risky clients

#### 2. **Transaction Trends** (`sp_GetTransactionTrends`)
```sql
EXEC sp_GetTransactionTrends @TimeRangeHours = 24, @IntervalMinutes = 15;
```

Returns time-series data:
- Transaction volume over time
- Amount trends
- Processing time trends
- Fraud score trends

## 🔧 Configuration

### Connection Details
- **Host**: `mssql` (Docker network) or `localhost:1433` (external)
- **Database**: `EBankingDB`
- **Username**: `sa`
- **Password**: `${MSSQL_SA_PASSWORD}` (default: `EBanking@Secure123!`)

### Environment Variables
```env
MSSQL_SA_PASSWORD=EBanking@Secure123!
```

## 🚀 Quick Start

### 1. Start the Stack
```bash
docker-compose up -d mssql
```

### 2. Verify Database Initialization
```bash
docker logs mssql_ebanking
```

### 3. Connect to SQL Server
```bash
docker exec -it mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!"
```

### 4. Test Queries
```sql
USE EBankingDB;
GO

-- Check data
SELECT COUNT(*) AS ClientCount FROM Clients;
SELECT COUNT(*) AS TransactionCount FROM Transactions;
SELECT COUNT(*) AS FraudAlertCount FROM FraudAlerts;

-- Get dashboard metrics
EXEC sp_GetDashboardMetrics @TimeRangeMinutes = 60;

-- Get transaction trends
EXEC sp_GetTransactionTrends @TimeRangeHours = 24, @IntervalMinutes = 15;
GO
```

## 📊 Sample Grafana Queries

### Transaction Volume by Channel
```sql
SELECT 
    Channel,
    COUNT(*) AS TransactionCount,
    SUM(Amount) AS TotalAmount
FROM Transactions
WHERE TransactionDate >= DATEADD(HOUR, -1, GETDATE())
GROUP BY Channel
ORDER BY TransactionCount DESC;
```

### Fraud Alert Timeline
```sql
SELECT 
    DATEADD(MINUTE, DATEDIFF(MINUTE, 0, DetectedAt) / 15 * 15, 0) AS TimeSlot,
    COUNT(*) AS AlertCount,
    AVG(RiskScore) AS AvgRiskScore
FROM FraudAlerts
WHERE DetectedAt >= DATEADD(HOUR, -24, GETDATE())
GROUP BY DATEADD(MINUTE, DATEDIFF(MINUTE, 0, DetectedAt) / 15 * 15, 0)
ORDER BY TimeSlot;
```

### Top Risky Clients
```sql
SELECT TOP 10
    c.ClientCode,
    c.FirstName + ' ' + c.LastName AS ClientName,
    c.RiskScore,
    COUNT(t.TransactionID) AS RecentTransactions,
    SUM(t.Amount) AS TotalAmount
FROM Clients c
LEFT JOIN Transactions t ON c.ClientID = t.ClientID 
    AND t.TransactionDate >= DATEADD(HOUR, -24, GETDATE())
WHERE c.RiskScore > 50
GROUP BY c.ClientCode, c.FirstName, c.LastName, c.RiskScore
ORDER BY c.RiskScore DESC;
```

### Transaction Success Rate
```sql
SELECT 
    CAST(TransactionDate AS DATE) AS Date,
    COUNT(*) AS TotalTransactions,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS Completed,
    SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) AS Failed,
    SUM(CASE WHEN Status = 'Flagged' THEN 1 ELSE 0 END) AS Flagged,
    CAST(SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SuccessRate
FROM Transactions
WHERE TransactionDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(TransactionDate AS DATE)
ORDER BY Date;
```

## 🔐 Security Considerations

1. **Change Default Password**: Update `MSSQL_SA_PASSWORD` in production
2. **Network Isolation**: Use Docker network for internal communication
3. **Encryption**: Enable TLS for production deployments
4. **Access Control**: Create specific users with limited permissions
5. **Audit Logging**: Enable SQL Server audit features

## 📝 Data Volume

### Initial Seed Data
- **Clients**: 1,000 (scalable to 25,000)
- **Merchants**: 100
- **Field Agents**: 50
- **Transactions**: 5,000 (last 7 days)
- **System Metrics**: 96 data points (24 hours)

### Production Scale
To scale to production volumes (25,000 clients, 500,000+ daily transactions), modify the seed script counters in `03-seed-data.sql`.

## 🛠️ Maintenance

### Backup Database
```bash
docker exec mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -Q "BACKUP DATABASE EBankingDB TO DISK = '/backup/EBankingDB.bak'"
```

### Restore Database
```bash
docker exec mssql_ebanking /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "EBanking@Secure123!" -Q "RESTORE DATABASE EBankingDB FROM DISK = '/backup/EBankingDB.bak' WITH REPLACE"
```

### Monitor Performance
```sql
-- Active connections
SELECT COUNT(*) AS ActiveConnections FROM sys.dm_exec_sessions WHERE is_user_process = 1;

-- Database size
EXEC sp_spaceused;

-- Top queries by execution time
SELECT TOP 10 
    total_elapsed_time / execution_count AS avg_time,
    execution_count,
    SUBSTRING(text, 1, 200) AS query_text
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
ORDER BY avg_time DESC;
```

## 📚 Additional Resources

- [SQL Server Documentation](https://docs.microsoft.com/en-us/sql/)
- [Grafana MS SQL Plugin](https://grafana.com/docs/grafana/latest/datasources/mssql/)
- [Fraud Detection Best Practices](https://www.microsoft.com/security)

## 🤝 Support

For issues or questions:
1. Check Docker logs: `docker logs mssql_ebanking`
2. Verify network connectivity: `docker network inspect observability_observability`
3. Test database connection from Grafana UI
