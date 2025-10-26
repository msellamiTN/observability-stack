-- =============================================
-- Stored Procedures for E-Banking Fraud Detection
-- Real-time fraud detection and analytics
-- =============================================

USE EBankingDB;
GO

-- =============================================
-- SP: Detect Velocity-Based Fraud
-- Detects multiple transactions in short time
-- =============================================
CREATE OR ALTER PROCEDURE sp_DetectVelocityFraud
    @ClientID INT,
    @TimeWindowMinutes INT = 5,
    @MaxTransactions INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TransactionCount INT;
    DECLARE @TotalAmount DECIMAL(18,2);
    
    -- Count transactions in time window
    SELECT 
        @TransactionCount = COUNT(*),
        @TotalAmount = SUM(Amount)
    FROM Transactions
    WHERE ClientID = @ClientID
        AND TransactionDate >= DATEADD(MINUTE, -@TimeWindowMinutes, GETDATE())
        AND Status IN ('Completed', 'Pending');
    
    -- If velocity threshold exceeded
    IF @TransactionCount >= @MaxTransactions
    BEGIN
        -- Get the latest transaction
        DECLARE @LatestTransactionID BIGINT;
        SELECT TOP 1 @LatestTransactionID = TransactionID
        FROM Transactions
        WHERE ClientID = @ClientID
        ORDER BY TransactionDate DESC;
        
        -- Create fraud alert
        INSERT INTO FraudAlerts (TransactionID, ClientID, AlertType, Severity, AlertMessage, RiskScore, Status)
        VALUES (
            @LatestTransactionID,
            @ClientID,
            'Velocity',
            'High',
            CONCAT('Client performed ', @TransactionCount, ' transactions (', FORMAT(@TotalAmount, 'N2'), ' TND) in ', @TimeWindowMinutes, ' minutes'),
            75.0,
            'Open'
        );
        
        -- Update client risk score
        UPDATE Clients
        SET RiskScore = CASE WHEN RiskScore + 15 > 100 THEN 100 ELSE RiskScore + 15 END,
            UpdatedAt = GETDATE()
        WHERE ClientID = @ClientID;
        
        RETURN 1; -- Fraud detected
    END
    
    RETURN 0; -- No fraud
END
GO

-- =============================================
-- SP: Detect Location-Based Fraud
-- Detects impossible travel patterns
-- =============================================
CREATE OR ALTER PROCEDURE sp_DetectLocationFraud
    @TransactionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ClientID INT;
    DECLARE @CurrentLat DECIMAL(10,8);
    DECLARE @CurrentLon DECIMAL(11,8);
    DECLARE @CurrentDate DATETIME;
    DECLARE @PreviousLat DECIMAL(10,8);
    DECLARE @PreviousLon DECIMAL(11,8);
    DECLARE @PreviousDate DATETIME;
    DECLARE @DistanceKm DECIMAL(10,2);
    DECLARE @TimeDiffMinutes INT;
    
    -- Get current transaction details
    SELECT 
        @ClientID = ClientID,
        @CurrentLat = Latitude,
        @CurrentLon = Longitude,
        @CurrentDate = TransactionDate
    FROM Transactions
    WHERE TransactionID = @TransactionID;
    
    -- Get previous transaction location
    SELECT TOP 1
        @PreviousLat = Latitude,
        @PreviousLon = Longitude,
        @PreviousDate = TransactionDate
    FROM Transactions
    WHERE ClientID = @ClientID
        AND TransactionID < @TransactionID
        AND Latitude IS NOT NULL
        AND Longitude IS NOT NULL
    ORDER BY TransactionDate DESC;
    
    IF @PreviousLat IS NOT NULL AND @CurrentLat IS NOT NULL
    BEGIN
        -- Calculate approximate distance (simplified Haversine)
        SET @DistanceKm = 
            6371 * 2 * ASIN(SQRT(
                POWER(SIN(RADIANS(@CurrentLat - @PreviousLat) / 2), 2) +
                COS(RADIANS(@PreviousLat)) * COS(RADIANS(@CurrentLat)) *
                POWER(SIN(RADIANS(@CurrentLon - @PreviousLon) / 2), 2)
            ));
        
        SET @TimeDiffMinutes = DATEDIFF(MINUTE, @PreviousDate, @CurrentDate);
        
        -- Impossible travel: >500km in <60 minutes
        IF @DistanceKm > 500 AND @TimeDiffMinutes < 60
        BEGIN
            INSERT INTO FraudAlerts (TransactionID, ClientID, AlertType, Severity, AlertMessage, RiskScore, Status)
            VALUES (
                @TransactionID,
                @ClientID,
                'Location',
                'Critical',
                CONCAT('Impossible travel detected: ', FORMAT(@DistanceKm, 'N2'), ' km in ', @TimeDiffMinutes, ' minutes'),
                95.0,
                'Open'
            );
            
            -- Flag transaction
            UPDATE Transactions
            SET IsFraudulent = 1,
                FraudScore = 95.0,
                FraudReason = 'Impossible travel pattern',
                Status = 'Flagged',
                UpdatedAt = GETDATE()
            WHERE TransactionID = @TransactionID;
            
            RETURN 1; -- Fraud detected
        END
    END
    
    RETURN 0; -- No fraud
END
GO

-- =============================================
-- SP: Detect Amount-Based Fraud
-- Detects unusual transaction amounts
-- =============================================
CREATE OR ALTER PROCEDURE sp_DetectAmountFraud
    @TransactionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ClientID INT;
    DECLARE @Amount DECIMAL(18,2);
    DECLARE @AvgAmount DECIMAL(18,2);
    DECLARE @StdDev DECIMAL(18,2);
    DECLARE @Threshold DECIMAL(18,2);
    
    -- Get transaction details
    SELECT @ClientID = ClientID, @Amount = Amount
    FROM Transactions
    WHERE TransactionID = @TransactionID;
    
    -- Calculate client's average and standard deviation
    SELECT 
        @AvgAmount = AVG(Amount),
        @StdDev = STDEV(Amount)
    FROM Transactions
    WHERE ClientID = @ClientID
        AND Status = 'Completed'
        AND TransactionDate >= DATEADD(DAY, -30, GETDATE());
    
    -- Set threshold at 3 standard deviations
    SET @Threshold = @AvgAmount + (3 * ISNULL(@StdDev, 0));
    
    -- Check if amount is abnormal
    IF @Amount > @Threshold AND @Amount > 1000
    BEGIN
        INSERT INTO FraudAlerts (TransactionID, ClientID, AlertType, Severity, AlertMessage, RiskScore, Status)
        VALUES (
            @TransactionID,
            @ClientID,
            'Amount',
            'High',
            CONCAT('Unusual amount: ', FORMAT(@Amount, 'N2'), ' TND (avg: ', FORMAT(@AvgAmount, 'N2'), ' TND)'),
            80.0,
            'Open'
        );
        
        UPDATE Transactions
        SET FraudScore = 80.0,
            FraudReason = 'Unusual transaction amount',
            UpdatedAt = GETDATE()
        WHERE TransactionID = @TransactionID;
        
        RETURN 1; -- Fraud detected
    END
    
    RETURN 0; -- No fraud
END
GO

-- =============================================
-- SP: Process Transaction with Fraud Check
-- Main procedure to process and validate transactions
-- =============================================
CREATE OR ALTER PROCEDURE sp_ProcessTransaction
    @ClientID INT,
    @MerchantID INT = NULL,
    @AgentID INT = NULL,
    @TransactionType NVARCHAR(50),
    @Amount DECIMAL(18,2),
    @Channel NVARCHAR(50),
    @DeviceID NVARCHAR(100) = NULL,
    @IPAddress NVARCHAR(50) = NULL,
    @Location NVARCHAR(200) = NULL,
    @Latitude DECIMAL(10,8) = NULL,
    @Longitude DECIMAL(11,8) = NULL,
    @TransactionID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @TransactionCode NVARCHAR(50);
        DECLARE @ProcessingStartTime DATETIME = GETDATE();
        DECLARE @ProcessingTime INT;
        
        -- Generate unique transaction code
        SET @TransactionCode = CONCAT('TXN', FORMAT(GETDATE(), 'yyyyMMddHHmmss'), RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR), 5));
        
        -- Insert transaction
        INSERT INTO Transactions (
            TransactionCode, ClientID, MerchantID, AgentID, TransactionType,
            Amount, Status, Channel, DeviceID, IPAddress, Location,
            Latitude, Longitude, TransactionDate
        )
        VALUES (
            @TransactionCode, @ClientID, @MerchantID, @AgentID, @TransactionType,
            @Amount, 'Pending', @Channel, @DeviceID, @IPAddress, @Location,
            @Latitude, @Longitude, GETDATE()
        );
        
        SET @TransactionID = SCOPE_IDENTITY();
        
        -- Run fraud detection checks
        DECLARE @VelocityFraud BIT = 0;
        DECLARE @LocationFraud BIT = 0;
        DECLARE @AmountFraud BIT = 0;
        
        EXEC @VelocityFraud = sp_DetectVelocityFraud @ClientID, 5, 5;
        EXEC @LocationFraud = sp_DetectLocationFraud @TransactionID;
        EXEC @AmountFraud = sp_DetectAmountFraud @TransactionID;
        
        -- Calculate processing time
        SET @ProcessingTime = DATEDIFF(MILLISECOND, @ProcessingStartTime, GETDATE());
        
        -- Update transaction with processing time
        UPDATE Transactions
        SET ProcessingTime = @ProcessingTime,
            Status = CASE 
                WHEN IsFraudulent = 1 THEN 'Flagged'
                WHEN FraudScore > 70 THEN 'Pending'
                ELSE 'Completed'
            END,
            UpdatedAt = GETDATE()
        WHERE TransactionID = @TransactionID;
        
        -- Update account balance if completed
        IF NOT EXISTS (SELECT 1 FROM Transactions WHERE TransactionID = @TransactionID AND Status = 'Flagged')
        BEGIN
            UPDATE AccountBalances
            SET Balance = Balance - @Amount,
                AvailableBalance = AvailableBalance - @Amount,
                LastTransactionDate = GETDATE(),
                UpdatedAt = GETDATE()
            WHERE ClientID = @ClientID;
        END
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        
        -- Log error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN 1; -- Error
    END CATCH
END
GO

-- =============================================
-- SP: Get Real-Time Dashboard Metrics
-- Returns key metrics for Grafana dashboard
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetDashboardMetrics
    @TimeRangeMinutes INT = 60
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = DATEADD(MINUTE, -@TimeRangeMinutes, GETDATE());
    
    -- Transaction metrics
    SELECT 
        'Transactions' AS MetricCategory,
        COUNT(*) AS TotalCount,
        SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS CompletedCount,
        SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) AS FailedCount,
        SUM(CASE WHEN Status = 'Flagged' THEN 1 ELSE 0 END) AS FlaggedCount,
        SUM(Amount) AS TotalAmount,
        AVG(Amount) AS AvgAmount,
        AVG(ProcessingTime) AS AvgProcessingTime,
        AVG(FraudScore) AS AvgFraudScore
    FROM Transactions
    WHERE TransactionDate >= @StartTime;
    
    -- Fraud alerts
    SELECT 
        'FraudAlerts' AS MetricCategory,
        COUNT(*) AS TotalAlerts,
        SUM(CASE WHEN Severity = 'Critical' THEN 1 ELSE 0 END) AS CriticalAlerts,
        SUM(CASE WHEN Severity = 'High' THEN 1 ELSE 0 END) AS HighAlerts,
        SUM(CASE WHEN Status = 'Open' THEN 1 ELSE 0 END) AS OpenAlerts,
        AVG(RiskScore) AS AvgRiskScore
    FROM FraudAlerts
    WHERE DetectedAt >= @StartTime;
    
    -- Channel distribution
    SELECT 
        'ChannelDistribution' AS MetricCategory,
        Channel,
        COUNT(*) AS TransactionCount,
        SUM(Amount) AS TotalAmount
    FROM Transactions
    WHERE TransactionDate >= @StartTime
    GROUP BY Channel;
    
    -- Top risky clients
    SELECT TOP 10
        'RiskyClients' AS MetricCategory,
        c.ClientID,
        c.ClientCode,
        c.FirstName + ' ' + c.LastName AS ClientName,
        c.RiskScore,
        COUNT(t.TransactionID) AS RecentTransactions,
        SUM(t.Amount) AS TotalAmount
    FROM Clients c
    LEFT JOIN Transactions t ON c.ClientID = t.ClientID AND t.TransactionDate >= @StartTime
    WHERE c.RiskScore > 50
    GROUP BY c.ClientID, c.ClientCode, c.FirstName, c.LastName, c.RiskScore
    ORDER BY c.RiskScore DESC;
END
GO

-- =============================================
-- SP: Get Transaction Trends
-- Time-series data for Grafana charts
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetTransactionTrends
    @TimeRangeHours INT = 24,
    @IntervalMinutes INT = 15
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = DATEADD(HOUR, -@TimeRangeHours, GETDATE());
    
    ;WITH TimeSlots AS (
        SELECT 
            DATEADD(MINUTE, @IntervalMinutes * number, @StartTime) AS TimeSlot
        FROM master..spt_values
        WHERE type = 'P' 
            AND DATEADD(MINUTE, @IntervalMinutes * number, @StartTime) <= GETDATE()
    )
    SELECT 
        ts.TimeSlot,
        COUNT(t.TransactionID) AS TransactionCount,
        ISNULL(SUM(t.Amount), 0) AS TotalAmount,
        ISNULL(AVG(t.Amount), 0) AS AvgAmount,
        ISNULL(AVG(t.ProcessingTime), 0) AS AvgProcessingTime,
        ISNULL(AVG(t.FraudScore), 0) AS AvgFraudScore,
        SUM(CASE WHEN t.IsFraudulent = 1 THEN 1 ELSE 0 END) AS FraudulentCount
    FROM TimeSlots ts
    LEFT JOIN Transactions t ON t.TransactionDate >= ts.TimeSlot 
        AND t.TransactionDate < DATEADD(MINUTE, @IntervalMinutes, ts.TimeSlot)
    GROUP BY ts.TimeSlot
    ORDER BY ts.TimeSlot;
END
GO

PRINT 'Stored procedures created successfully!';
GO
