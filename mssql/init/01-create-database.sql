-- =============================================
-- E-Banking Financial Observability Database
-- Institution: Medium-sized Financial Institution
-- Scale: 500,000+ daily transactions, 25,000 active clients
-- Purpose: Real-time fraud detection and business analytics
-- =============================================

USE master;
GO

-- Create E-Banking Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EBankingDB')
BEGIN
    CREATE DATABASE EBankingDB;
    PRINT 'Database EBankingDB created successfully.';
END
GO

USE EBankingDB;
GO

-- =============================================
-- CORE TABLES
-- =============================================

-- Clients Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Clients')
BEGIN
    CREATE TABLE Clients (
        ClientID INT IDENTITY(1,1) PRIMARY KEY,
        ClientCode NVARCHAR(20) UNIQUE NOT NULL,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NOT NULL,
        PhoneNumber NVARCHAR(20),
        AccountType NVARCHAR(50) NOT NULL, -- Individual, Business, Premium
        AccountStatus NVARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Suspended, Closed
        RiskScore DECIMAL(5,2) DEFAULT 0.00, -- 0-100 fraud risk score
        KYCStatus NVARCHAR(20) NOT NULL DEFAULT 'Verified', -- Verified, Pending, Failed
        RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
        LastLoginDate DATETIME,
        Country NVARCHAR(100) DEFAULT 'Tunisia',
        City NVARCHAR(100),
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        INDEX IX_Clients_Status (AccountStatus),
        INDEX IX_Clients_RiskScore (RiskScore),
        INDEX IX_Clients_Email (Email)
    );
    PRINT 'Table Clients created successfully.';
END
GO

-- Merchants Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Merchants')
BEGIN
    CREATE TABLE Merchants (
        MerchantID INT IDENTITY(1,1) PRIMARY KEY,
        MerchantCode NVARCHAR(20) UNIQUE NOT NULL,
        MerchantName NVARCHAR(200) NOT NULL,
        Category NVARCHAR(100) NOT NULL, -- Retail, Food, Travel, Entertainment, etc.
        Country NVARCHAR(100) DEFAULT 'Tunisia',
        City NVARCHAR(100),
        RiskLevel NVARCHAR(20) DEFAULT 'Low', -- Low, Medium, High
        IsActive BIT DEFAULT 1,
        RegistrationDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        INDEX IX_Merchants_Category (Category),
        INDEX IX_Merchants_RiskLevel (RiskLevel)
    );
    PRINT 'Table Merchants created successfully.';
END
GO

-- Field Agents Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FieldAgents')
BEGIN
    CREATE TABLE FieldAgents (
        AgentID INT IDENTITY(1,1) PRIMARY KEY,
        AgentCode NVARCHAR(20) UNIQUE NOT NULL,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(255) NOT NULL,
        PhoneNumber NVARCHAR(20),
        Region NVARCHAR(100),
        IsActive BIT DEFAULT 1,
        HireDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        INDEX IX_FieldAgents_Region (Region)
    );
    PRINT 'Table FieldAgents created successfully.';
END
GO

-- Transactions Table (Main transactional data)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Transactions')
BEGIN
    CREATE TABLE Transactions (
        TransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
        TransactionCode NVARCHAR(50) UNIQUE NOT NULL,
        ClientID INT NOT NULL,
        MerchantID INT NULL,
        AgentID INT NULL,
        TransactionType NVARCHAR(50) NOT NULL, -- Transfer, Payment, Withdrawal, Deposit, Purchase
        Amount DECIMAL(18,2) NOT NULL,
        Currency NVARCHAR(10) DEFAULT 'TND',
        Status NVARCHAR(20) NOT NULL, -- Pending, Completed, Failed, Cancelled, Flagged
        Channel NVARCHAR(50) NOT NULL, -- Mobile, Web, ATM, POS, Agent
        DeviceID NVARCHAR(100),
        IPAddress NVARCHAR(50),
        Location NVARCHAR(200),
        Latitude DECIMAL(10,8),
        Longitude DECIMAL(11,8),
        FraudScore DECIMAL(5,2) DEFAULT 0.00, -- 0-100
        IsFraudulent BIT DEFAULT 0,
        FraudReason NVARCHAR(500),
        ProcessingTime INT, -- milliseconds
        TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_Transactions_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
        CONSTRAINT FK_Transactions_Merchants FOREIGN KEY (MerchantID) REFERENCES Merchants(MerchantID),
        CONSTRAINT FK_Transactions_Agents FOREIGN KEY (AgentID) REFERENCES FieldAgents(AgentID),
        INDEX IX_Transactions_ClientID (ClientID),
        INDEX IX_Transactions_Status (Status),
        INDEX IX_Transactions_Date (TransactionDate),
        INDEX IX_Transactions_FraudScore (FraudScore),
        INDEX IX_Transactions_IsFraudulent (IsFraudulent),
        INDEX IX_Transactions_Type (TransactionType),
        INDEX IX_Transactions_Channel (Channel)
    );
    PRINT 'Table Transactions created successfully.';
END
GO

-- Fraud Alerts Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FraudAlerts')
BEGIN
    CREATE TABLE FraudAlerts (
        AlertID BIGINT IDENTITY(1,1) PRIMARY KEY,
        TransactionID BIGINT NOT NULL,
        ClientID INT NOT NULL,
        AlertType NVARCHAR(100) NOT NULL, -- Velocity, Location, Amount, Pattern, Device
        Severity NVARCHAR(20) NOT NULL, -- Low, Medium, High, Critical
        AlertMessage NVARCHAR(1000) NOT NULL,
        RiskScore DECIMAL(5,2) NOT NULL,
        Status NVARCHAR(20) NOT NULL DEFAULT 'Open', -- Open, Investigating, Resolved, False Positive
        AssignedTo NVARCHAR(100),
        ResolutionNotes NVARCHAR(2000),
        DetectedAt DATETIME NOT NULL DEFAULT GETDATE(),
        ResolvedAt DATETIME,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_FraudAlerts_Transactions FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
        CONSTRAINT FK_FraudAlerts_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
        INDEX IX_FraudAlerts_Status (Status),
        INDEX IX_FraudAlerts_Severity (Severity),
        INDEX IX_FraudAlerts_DetectedAt (DetectedAt)
    );
    PRINT 'Table FraudAlerts created successfully.';
END
GO

-- Account Balances Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AccountBalances')
BEGIN
    CREATE TABLE AccountBalances (
        BalanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
        ClientID INT NOT NULL,
        AccountNumber NVARCHAR(50) NOT NULL,
        AccountType NVARCHAR(50) NOT NULL, -- Checking, Savings, Investment
        Balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        AvailableBalance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        Currency NVARCHAR(10) DEFAULT 'TND',
        LastTransactionDate DATETIME,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_AccountBalances_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
        INDEX IX_AccountBalances_ClientID (ClientID),
        INDEX IX_AccountBalances_AccountNumber (AccountNumber)
    );
    PRINT 'Table AccountBalances created successfully.';
END
GO

-- System Metrics Table (for operational monitoring)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemMetrics')
BEGIN
    CREATE TABLE SystemMetrics (
        MetricID BIGINT IDENTITY(1,1) PRIMARY KEY,
        MetricName NVARCHAR(100) NOT NULL,
        MetricValue DECIMAL(18,4) NOT NULL,
        MetricUnit NVARCHAR(50),
        Category NVARCHAR(100) NOT NULL, -- Performance, Availability, Throughput, Error
        Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
        INDEX IX_SystemMetrics_Name (MetricName),
        INDEX IX_SystemMetrics_Timestamp (Timestamp),
        INDEX IX_SystemMetrics_Category (Category)
    );
    PRINT 'Table SystemMetrics created successfully.';
END
GO

-- Audit Log Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLog')
BEGIN
    CREATE TABLE AuditLog (
        AuditID BIGINT IDENTITY(1,1) PRIMARY KEY,
        EntityType NVARCHAR(100) NOT NULL, -- Transaction, Client, Merchant, etc.
        EntityID BIGINT NOT NULL,
        Action NVARCHAR(50) NOT NULL, -- Create, Update, Delete, Flag
        PerformedBy NVARCHAR(100) NOT NULL,
        OldValue NVARCHAR(MAX),
        NewValue NVARCHAR(MAX),
        Timestamp DATETIME NOT NULL DEFAULT GETDATE(),
        INDEX IX_AuditLog_EntityType (EntityType),
        INDEX IX_AuditLog_Timestamp (Timestamp)
    );
    PRINT 'Table AuditLog created successfully.';
END
GO

PRINT 'E-Banking database schema created successfully!';
GO
