-- =============================================
-- Sample Data Generation for E-Banking System
-- Realistic data for 25,000 clients, 100 merchants, 50 agents
-- =============================================

USE EBankingDB;
GO

PRINT 'Starting data seeding...';
GO

-- =============================================
-- Seed Merchants (100 merchants)
-- =============================================
PRINT 'Seeding Merchants...';
GO

DECLARE @MerchantCounter INT = 1;
DECLARE @Categories TABLE (Category NVARCHAR(100));
INSERT INTO @Categories VALUES 
    ('Retail'), ('Food & Beverage'), ('Travel'), ('Entertainment'), 
    ('Healthcare'), ('Education'), ('Utilities'), ('Telecom'),
    ('E-commerce'), ('Gas Station'), ('Pharmacy'), ('Supermarket');

WHILE @MerchantCounter <= 100
BEGIN
    DECLARE @Category NVARCHAR(100);
    DECLARE @RiskLevel NVARCHAR(20);
    
    SELECT TOP 1 @Category = Category FROM @Categories ORDER BY NEWID();
    
    SET @RiskLevel = CASE 
        WHEN @MerchantCounter % 10 = 0 THEN 'High'
        WHEN @MerchantCounter % 5 = 0 THEN 'Medium'
        ELSE 'Low'
    END;
    
    INSERT INTO Merchants (MerchantCode, MerchantName, Category, Country, City, RiskLevel, IsActive)
    VALUES (
        CONCAT('MER', RIGHT('00000' + CAST(@MerchantCounter AS VARCHAR), 5)),
        CONCAT(@Category, ' Store #', @MerchantCounter),
        @Category,
        'Tunisia',
        CASE (@MerchantCounter % 5)
            WHEN 0 THEN 'Tunis'
            WHEN 1 THEN 'Sfax'
            WHEN 2 THEN 'Sousse'
            WHEN 3 THEN 'Bizerte'
            ELSE 'Gabes'
        END,
        @RiskLevel,
        1
    );
    
    SET @MerchantCounter = @MerchantCounter + 1;
END

PRINT 'Merchants seeded: 100';
GO

-- =============================================
-- Seed Field Agents (50 agents)
-- =============================================
PRINT 'Seeding Field Agents...';
GO

DECLARE @AgentCounter INT = 1;
DECLARE @FirstNames TABLE (Name NVARCHAR(100));
DECLARE @LastNames TABLE (Name NVARCHAR(100));

INSERT INTO @FirstNames VALUES ('Mohamed'), ('Ahmed'), ('Fatima'), ('Aisha'), ('Ali'), ('Sara'), ('Youssef'), ('Leila'), ('Omar'), ('Nour');
INSERT INTO @LastNames VALUES ('Ben Ali'), ('Trabelsi'), ('Jebali'), ('Hamdi'), ('Karoui'), ('Mejri'), ('Gharbi'), ('Sassi'), ('Cherni'), ('Bouazizi');

WHILE @AgentCounter <= 50
BEGIN
    DECLARE @FirstName NVARCHAR(100);
    DECLARE @LastName NVARCHAR(100);
    
    SELECT TOP 1 @FirstName = Name FROM @FirstNames ORDER BY NEWID();
    SELECT TOP 1 @LastName = Name FROM @LastNames ORDER BY NEWID();
    
    INSERT INTO FieldAgents (AgentCode, FirstName, LastName, Email, PhoneNumber, Region, IsActive)
    VALUES (
        CONCAT('AGT', RIGHT('00000' + CAST(@AgentCounter AS VARCHAR), 5)),
        @FirstName,
        @LastName,
        CONCAT(LOWER(@FirstName), '.', LOWER(@LastName), '@ebanking.tn'),
        CONCAT('+216', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR), 8)),
        CASE (@AgentCounter % 5)
            WHEN 0 THEN 'North'
            WHEN 1 THEN 'South'
            WHEN 2 THEN 'Center'
            WHEN 3 THEN 'East'
            ELSE 'West'
        END,
        1
    );
    
    SET @AgentCounter = @AgentCounter + 1;
END

PRINT 'Field Agents seeded: 50';
GO

-- =============================================
-- Seed Clients (Sample of 1000 for demo - scale to 25,000 as needed)
-- =============================================
PRINT 'Seeding Clients (1000 sample)...';
GO

DECLARE @ClientCounter INT = 1;

WHILE @ClientCounter <= 1000
BEGIN
    DECLARE @ClientFirstName NVARCHAR(100);
    DECLARE @ClientLastName NVARCHAR(100);
    DECLARE @AccountType NVARCHAR(50);
    DECLARE @RiskScore DECIMAL(5,2);
    
    SELECT TOP 1 @ClientFirstName = Name FROM @FirstNames ORDER BY NEWID();
    SELECT TOP 1 @ClientLastName = Name FROM @LastNames ORDER BY NEWID();
    
    SET @AccountType = CASE (@ClientCounter % 10)
        WHEN 0 THEN 'Premium'
        WHEN 1 THEN 'Business'
        ELSE 'Individual'
    END;
    
    -- Most clients have low risk, some medium, few high
    SET @RiskScore = CASE 
        WHEN @ClientCounter % 100 = 0 THEN CAST((RAND() * 30 + 70) AS DECIMAL(5,2)) -- High risk
        WHEN @ClientCounter % 20 = 0 THEN CAST((RAND() * 30 + 40) AS DECIMAL(5,2)) -- Medium risk
        ELSE CAST((RAND() * 30) AS DECIMAL(5,2)) -- Low risk
    END;
    
    INSERT INTO Clients (
        ClientCode, FirstName, LastName, Email, PhoneNumber,
        AccountType, AccountStatus, RiskScore, KYCStatus,
        RegistrationDate, Country, City
    )
    VALUES (
        CONCAT('CLI', RIGHT('00000' + CAST(@ClientCounter AS VARCHAR), 5)),
        @ClientFirstName,
        @ClientLastName,
        CONCAT(LOWER(@ClientFirstName), '.', LOWER(@ClientLastName), @ClientCounter, '@email.tn'),
        CONCAT('+216', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR), 8)),
        @AccountType,
        CASE WHEN @ClientCounter % 50 = 0 THEN 'Suspended' ELSE 'Active' END,
        @RiskScore,
        'Verified',
        DATEADD(DAY, -CAST((RAND() * 730) AS INT), GETDATE()), -- Random date within last 2 years
        'Tunisia',
        CASE (@ClientCounter % 5)
            WHEN 0 THEN 'Tunis'
            WHEN 1 THEN 'Sfax'
            WHEN 2 THEN 'Sousse'
            WHEN 3 THEN 'Bizerte'
            ELSE 'Gabes'
        END
    );
    
    SET @ClientCounter = @ClientCounter + 1;
END

PRINT 'Clients seeded: 1000';
GO

-- =============================================
-- Create Account Balances for all clients
-- =============================================
PRINT 'Creating Account Balances...';
GO

INSERT INTO AccountBalances (ClientID, AccountNumber, AccountType, Balance, AvailableBalance, Currency)
SELECT 
    ClientID,
    CONCAT('ACC', RIGHT('0000000000' + CAST(ClientID AS VARCHAR), 10)),
    CASE 
        WHEN AccountType = 'Premium' THEN 'Investment'
        WHEN AccountType = 'Business' THEN 'Checking'
        ELSE 'Savings'
    END,
    CAST((RAND(CHECKSUM(NEWID())) * 50000 + 1000) AS DECIMAL(18,2)), -- Random balance 1000-51000
    CAST((RAND(CHECKSUM(NEWID())) * 50000 + 1000) AS DECIMAL(18,2)),
    'TND'
FROM Clients;

PRINT 'Account Balances created for all clients';
GO

-- =============================================
-- Seed Sample Transactions (Last 7 days)
-- =============================================
PRINT 'Seeding Sample Transactions...';
GO

DECLARE @TxnCounter INT = 1;
DECLARE @DaysBack INT;
DECLARE @TxnClientID INT;
DECLARE @TxnMerchantID INT;
DECLARE @TxnAgentID INT;
DECLARE @TxnType NVARCHAR(50);
DECLARE @TxnAmount DECIMAL(18,2);
DECLARE @TxnChannel NVARCHAR(50);
DECLARE @TxnStatus NVARCHAR(20);
DECLARE @TxnDate DATETIME;

WHILE @TxnCounter <= 5000 -- 5000 sample transactions
BEGIN
    SET @DaysBack = CAST((RAND() * 7) AS INT); -- Last 7 days
    SET @TxnDate = DATEADD(MINUTE, -CAST((RAND() * @DaysBack * 1440) AS INT), GETDATE());
    
    -- Random client
    SELECT TOP 1 @TxnClientID = ClientID FROM Clients ORDER BY NEWID();
    
    -- Random merchant (70% of transactions)
    IF RAND() < 0.7
        SELECT TOP 1 @TxnMerchantID = MerchantID FROM Merchants ORDER BY NEWID();
    ELSE
        SET @TxnMerchantID = NULL;
    
    -- Random agent (20% of transactions)
    IF RAND() < 0.2
        SELECT TOP 1 @TxnAgentID = AgentID FROM FieldAgents ORDER BY NEWID();
    ELSE
        SET @TxnAgentID = NULL;
    
    -- Transaction type
    SET @TxnType = CASE CAST((RAND() * 5) AS INT)
        WHEN 0 THEN 'Transfer'
        WHEN 1 THEN 'Payment'
        WHEN 2 THEN 'Withdrawal'
        WHEN 3 THEN 'Deposit'
        ELSE 'Purchase'
    END;
    
    -- Amount (most small, some large)
    SET @TxnAmount = CASE 
        WHEN RAND() < 0.8 THEN CAST((RAND() * 500 + 10) AS DECIMAL(18,2)) -- Small: 10-510
        WHEN RAND() < 0.95 THEN CAST((RAND() * 2000 + 500) AS DECIMAL(18,2)) -- Medium: 500-2500
        ELSE CAST((RAND() * 10000 + 2500) AS DECIMAL(18,2)) -- Large: 2500-12500
    END;
    
    -- Channel
    SET @TxnChannel = CASE CAST((RAND() * 5) AS INT)
        WHEN 0 THEN 'Mobile'
        WHEN 1 THEN 'Web'
        WHEN 2 THEN 'ATM'
        WHEN 3 THEN 'POS'
        ELSE 'Agent'
    END;
    
    -- Status (95% completed, 3% failed, 2% flagged)
    SET @TxnStatus = CASE 
        WHEN RAND() < 0.95 THEN 'Completed'
        WHEN RAND() < 0.98 THEN 'Failed'
        ELSE 'Flagged'
    END;
    
    INSERT INTO Transactions (
        TransactionCode, ClientID, MerchantID, AgentID, TransactionType,
        Amount, Currency, Status, Channel, 
        DeviceID, IPAddress, Location,
        Latitude, Longitude,
        FraudScore, IsFraudulent, ProcessingTime, TransactionDate
    )
    VALUES (
        CONCAT('TXN', FORMAT(@TxnDate, 'yyyyMMddHHmmss'), RIGHT('00000' + CAST(@TxnCounter AS VARCHAR), 5)),
        @TxnClientID,
        @TxnMerchantID,
        @TxnAgentID,
        @TxnType,
        @TxnAmount,
        'TND',
        @TxnStatus,
        @TxnChannel,
        CONCAT('DEV', RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 100000000 AS VARCHAR), 8)),
        CONCAT('192.168.', CAST((RAND() * 255) AS INT), '.', CAST((RAND() * 255) AS INT)),
        'Tunis, Tunisia',
        CAST((36.8 + (RAND() * 0.2)) AS DECIMAL(10,8)), -- Latitude around Tunis
        CAST((10.1 + (RAND() * 0.2)) AS DECIMAL(11,8)), -- Longitude around Tunis
        CASE WHEN @TxnStatus = 'Flagged' THEN CAST((RAND() * 30 + 70) AS DECIMAL(5,2)) ELSE CAST((RAND() * 30) AS DECIMAL(5,2)) END,
        CASE WHEN @TxnStatus = 'Flagged' THEN 1 ELSE 0 END,
        CAST((RAND() * 500 + 50) AS INT), -- Processing time 50-550ms
        @TxnDate
    );
    
    SET @TxnCounter = @TxnCounter + 1;
END

PRINT 'Sample Transactions seeded: 5000';
GO

-- =============================================
-- Create Fraud Alerts for flagged transactions
-- =============================================
PRINT 'Creating Fraud Alerts...';
GO

INSERT INTO FraudAlerts (TransactionID, ClientID, AlertType, Severity, AlertMessage, RiskScore, Status, DetectedAt)
SELECT 
    t.TransactionID,
    t.ClientID,
    CASE CAST((RAND(CHECKSUM(NEWID())) * 4) AS INT)
        WHEN 0 THEN 'Velocity'
        WHEN 1 THEN 'Location'
        WHEN 2 THEN 'Amount'
        ELSE 'Pattern'
    END,
    CASE 
        WHEN t.FraudScore >= 90 THEN 'Critical'
        WHEN t.FraudScore >= 70 THEN 'High'
        WHEN t.FraudScore >= 50 THEN 'Medium'
        ELSE 'Low'
    END,
    CONCAT('Suspicious transaction detected: ', t.TransactionType, ' of ', FORMAT(t.Amount, 'N2'), ' TND'),
    t.FraudScore,
    CASE WHEN RAND(CHECKSUM(NEWID())) < 0.3 THEN 'Resolved' ELSE 'Open' END,
    t.TransactionDate
FROM Transactions t
WHERE t.IsFraudulent = 1;

PRINT 'Fraud Alerts created for flagged transactions';
GO

-- =============================================
-- Add System Metrics (Last 24 hours)
-- =============================================
PRINT 'Adding System Metrics...';
GO

DECLARE @MetricTime DATETIME = DATEADD(HOUR, -24, GETDATE());
DECLARE @MetricCounter INT = 0;

WHILE @MetricCounter < 96 -- Every 15 minutes for 24 hours
BEGIN
    -- Transaction throughput
    INSERT INTO SystemMetrics (MetricName, MetricValue, MetricUnit, Category, Timestamp)
    VALUES ('transaction_throughput', CAST((RAND() * 100 + 50) AS DECIMAL(18,4)), 'tps', 'Performance', @MetricTime);
    
    -- API response time
    INSERT INTO SystemMetrics (MetricName, MetricValue, MetricUnit, Category, Timestamp)
    VALUES ('api_response_time', CAST((RAND() * 200 + 100) AS DECIMAL(18,4)), 'ms', 'Performance', @MetricTime);
    
    -- System availability
    INSERT INTO SystemMetrics (MetricName, MetricValue, MetricUnit, Category, Timestamp)
    VALUES ('system_availability', CAST((RAND() * 5 + 95) AS DECIMAL(18,4)), 'percent', 'Availability', @MetricTime);
    
    -- Error rate
    INSERT INTO SystemMetrics (MetricName, MetricValue, MetricUnit, Category, Timestamp)
    VALUES ('error_rate', CAST((RAND() * 2) AS DECIMAL(18,4)), 'percent', 'Error', @MetricTime);
    
    SET @MetricTime = DATEADD(MINUTE, 15, @MetricTime);
    SET @MetricCounter = @MetricCounter + 1;
END

PRINT 'System Metrics added for last 24 hours';
GO

PRINT '========================================';
PRINT 'Data seeding completed successfully!';
PRINT 'Summary:';
PRINT '- Merchants: 100';
PRINT '- Field Agents: 50';
PRINT '- Clients: 1000';
PRINT '- Account Balances: 1000';
PRINT '- Transactions: 5000';
PRINT '- Fraud Alerts: Variable (based on flagged transactions)';
PRINT '- System Metrics: 96 time points (24 hours)';
PRINT '========================================';
GO
