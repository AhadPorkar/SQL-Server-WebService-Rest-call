/*==============================================================================
  METHODS FOR CALLING WEB SERVICES FROM SQL SERVER
==============================================================================*/

/*******************************************************************************
  METHOD COMPARISON MATRIX
*******************************************************************************/

/*
┌──────────────────────┬──────────────┬────────────┬──────────────┬──────────────┬─────────────────┐
│ Method               │ SQL Version  │ Setup      │ Performance  │ Security     │ Recommended     │
│                      │ Required     │ Complexity │              │ Risk         │ Use Case        │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ OLE Automation       │ 2005+        │ Low        │ Poor         │ High         │ Legacy only     │
│ (sp_OACreate)        │              │            │              │              │                 │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ PowerShell           │ 2008+        │ Medium     │ Fair         │ Medium       │ Scheduled jobs  │
│ (xp_cmdshell)        │              │            │              │              │ Complex logic   │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ PowerShell           │ 2008+        │ Medium     │ Fair         │ Low          │ Recurring tasks │
│ (SQL Agent)          │              │            │              │              │ ETL workflows   │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ SQL CLR (C#)         │ 2005+        │ High       │ Excellent    │ Medium       │ High volume     │
│                      │ (Not Azure)  │            │              │              │ Complex logic   │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ External C# App      │ Any          │ High       │ Good         │ High         │ Microservices   │
│                      │              │            │              │              │ Decoupled arch  │
├──────────────────────┼──────────────┼────────────┼──────────────┼──────────────┼─────────────────┤
│ sp_invoke_external_  │ 2025+        │ Very Low   │ Excellent    │ Low          │ ** BEST CHOICE  │
│ rest_endpoint        │ (Azure SQL)  │            │              │              │ ** NEW PROJECTS │
└──────────────────────┴──────────────┴────────────┴──────────────┴──────────────┴─────────────────┘
*/

/*------------------------------------------------------------------------------
  METHOD 1: OLE AUTOMATION (sp_OACreate, sp_OAMethod)
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • Available since SQL Server 2005
--   • No external dependencies
--   • Works on older systems
--   • Simple for basic requests

-- ✗ CONS:
--   • Deprecated technology
--   • Poor error handling
--   • Verbose syntax
--   • Limited SSL/TLS support
--   • High security risk (requires sysadmin to enable)
--   • Poor performance
--   • Memory leaks if not cleaned up properly
--   • Limited to COM objects

--   PERFORMANCE: ★☆☆☆☆ (1/5)
--   SECURITY: ★☆☆☆☆ (1/5)
--   EASE OF USE: ★★☆☆☆ (2/5)

--   USE WHEN:
--   • Maintaining legacy systems (SQL 2000-2008)
--   • No other options available
--   • Upgrading is not feasible

--   EXAMPLE USE CASE:
--   • Old application on SQL Server 2005 that cannot be upgraded
--   • Simple one-time data migration

/*------------------------------------------------------------------------------
  METHOD 2: POWERSHELL VIA xp_cmdshell
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • Very flexible and powerful
--   • Native HTTP support
--   • Can handle complex scenarios
--   • Good error handling
--   • Can interact with file system
--   • Access to full PowerShell ecosystem

-- ✗ CONS:
--   • Requires xp_cmdshell (major security concern)
--   • Performance overhead (new process per call)
--   • Output parsing can be complex
--   • Requires proper execution policy
--   • String escaping challenges

--   PERFORMANCE: ★★☆☆☆ (2/5)
--   SECURITY: ★★☆☆☆ (2/5)
--   EASE OF USE: ★★★☆☆ (3/5)

--   USE WHEN:
--   • Need complex pre/post processing
--   • Interacting with multiple systems
--   • File operations required
--   • Quick prototyping
--   • Already using xp_cmdshell for other tasks

--   EXAMPLE USE CASE:
--   • Download file from API, process it, upload to FTP
--   • Complex authentication flows
--   • Calling APIs that require certificate authentication

/*------------------------------------------------------------------------------
  METHOD 3: POWERSHELL VIA SQL AGENT
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • No xp_cmdshell required
--   • Better security model
--   • Built-in scheduling
--   • Job history and logging
--   • Error notifications
--   • Retry logic built-in

-- ✗ CONS:
--   • Cannot be called on-demand from T-SQL
--   • Requires SQL Agent (not available in Express Edition)
--   • Setup more complex
--   • Debugging is harder

--   PERFORMANCE: ★★★☆☆ (3/5)
--   SECURITY: ★★★★☆ (4/5)
--   EASE OF USE: ★★★☆☆ (3/5)

--   USE WHEN:
--   • Scheduled/recurring API calls
--   • ETL processes
--   • Batch operations
--   • Night-time data synchronization
--   • Don't need real-time responses

--   EXAMPLE USE CASE:
--   • Nightly sync of product data from external API
--   • Hourly weather data updates
--   • Daily report generation from multiple API sources

/*------------------------------------------------------------------------------
  METHOD 4: SQL CLR (C# .NET Assembly)
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • Excellent performance (in-process)
--   • Full .NET Framework capabilities
--   • Type-safe and strongly typed
--   • Can create table-valued functions
--   • Reusable across databases
--   • Complex logic support
--   • Binary data handling
--   • Can use any NuGet package

-- ✗ CONS:
--   • Complex setup (compile, deploy, register)
--   • Requires CLR enabled (security review needed)
--   • Not fully supported in Azure SQL Database
--   • Debugging is challenging
--   • Version management overhead
--   • Requires .NET development skills
--   • Assembly signing required for production

--   PERFORMANCE: ★★★★★ (5/5)
--   SECURITY: ★★★☆☆ (3/5)
--   EASE OF USE: ★★☆☆☆ (2/5)

--   USE WHEN:
--   • High-volume API calls (thousands per minute)
--   • Complex data transformations
--   • Need to reuse functions across multiple databases
--   • Binary file processing
--   • Custom authentication mechanisms
--   • On-premises with full control

--   EXAMPLE USE CASE:
--   • Real-time stock price updates (high frequency)
--   • Image processing from external API
--   • Complex JSON parsing and transformation
--   • Custom encryption/decryption before API calls

/*------------------------------------------------------------------------------
  METHOD 5: EXTERNAL C# APPLICATION
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • Complete separation of concerns
--   • Independent deployment
--   • Easier debugging and testing
--   • Can use latest .NET versions
--   • Full async/await support
--   • Better logging infrastructure
--   • Can be containerized

-- ✗ CONS:
--   • Requires external application management
--   • More complex architecture
--   • Network latency between app and SQL
--   • Requires xp_cmdshell or SQL Agent to trigger
--   • Additional infrastructure

--   PERFORMANCE: ★★★★☆ (4/5)
--   SECURITY: ★★☆☆☆ (2/5) [if using xp_cmdshell]
--              ★★★★☆ (4/5) [if proper service]
--   EASE OF USE: ★★★☆☆ (3/5)

--   USE WHEN:
--   • Building microservices architecture
--   • Need modern .NET features (.NET 6+)
--   • Want independent scaling
--   • Require extensive logging/monitoring
--   • Complex business logic outside SQL
--   • Multiple systems need same API integration

--   EXAMPLE USE CASE:
--   • Microservice handling all external API integrations
--   • Message queue consumer that updates SQL
--   • RESTful API gateway for SQL Server
--   • Event-driven architecture with SQL as data store

/*------------------------------------------------------------------------------
  METHOD 6: sp_invoke_external_rest_endpoint (SQL Server 2025)
------------------------------------------------------------------------------*/
-- ✓ PROS:
--   • Native, built-in support
--   • Clean, simple syntax
--   • Secure credential management
--   • Built-in retry logic
--   • Excellent performance
--   • All HTTP methods supported
--   • Timeout configuration
--   • Managed Identity support
--   • No external dependencies
--   • Full JSON integration
--   • Works with HTTPS only (enforced security)

-- ✗ CONS:
--   • Requires SQL Server 2025+ (or Azure SQL)
--   • HTTPS only (no HTTP)
--   • Must be explicitly enabled
--   • Response size limited to 100MB
--   • Rate limiting considerations

--   PERFORMANCE: ★★★★★ (5/5)
--   SECURITY: ★★★★★ (5/5)
--   EASE OF USE: ★★★★★ (5/5)

--   USE WHEN:
--   • SQL Server 2025 or Azure SQL available
--   • ANY REST API integration needed
--   • Starting new projects
--   • Modernizing existing solutions
--   • Need enterprise-grade security

--   EXAMPLE USE CASE:
--   • Any REST API integration in SQL Server 2025
--   • Real-time data enrichment
--   • Calling Azure services from SQL
--   • Webhook handling
--   • Integration with third-party services

/*******************************************************************************
  DECISION TREE
*******************************************************************************/

/*
START: Need to call web service from SQL Server?
│
├─ SQL Server 2025+ or Azure SQL available?
│  │
│  ├─ YES → Use sp_invoke_external_rest_endpoint ✓ (BEST CHOICE)
│  │
│  └─ NO → Continue to next question
│
├─ Need high-performance, many calls per minute?
│  │
│  ├─ YES → Consider SQL CLR (C#) if:
│  │         • On-premises SQL Server
│  │         • CLR can be enabled
│  │         • Have C# development resources
│  │
│  └─ NO → Continue to next question
│
├─ Need scheduled/recurring calls?
│  │
│  ├─ YES → Use SQL Agent with PowerShell ✓
│  │
│  └─ NO → Continue to next question
│
├─ Need complex logic, file operations, or multi-system integration?
│  │
│  ├─ YES → PowerShell via xp_cmdshell
│  │         (Enable only if necessary, disable after use)
│  │
│  └─ NO → Continue to next question
│
├─ Building modern, scalable architecture?
│  │
│  ├─ YES → External C# application/microservice ✓
│  │
│  └─ NO → Continue to next question
│
└─ Last resort only:
   • Stuck on very old SQL Server (2005-2008)
   • Cannot upgrade
   • Simple, infrequent calls
   → Use OLE Automation (not recommended)
*/

/*******************************************************************************
  REAL-WORLD SCENARIOS AND RECOMMENDATIONS
*******************************************************************************/

-- SCENARIO 1: E-commerce Order Processing
-- ─────────────────────────────────────────
-- Need: Call shipping provider API when order is placed
-- Volume: 100-500 calls per day
-- RECOMMENDED: SQL Server 2025: sp_invoke_external_rest_endpoint
--              Alternative: SQL CLR if on older version

-- SCENARIO 2: Weather Data Integration
-- ─────────────────────────────────────
-- Need: Fetch weather data every hour for 50 locations
-- Volume: 1,200 calls per day
-- RECOMMENDED: SQL Agent with PowerShell

-- SCENARIO 3: Real-time Stock Prices
-- ───────────────────────────────────
-- Need: Update stock prices continuously
-- Volume: 10,000+ calls per minute
-- RECOMMENDED: SQL CLR (C#) with async operations
--              OR: External C# microservice with SQL updates

-- SCENARIO 4: Payment Gateway Integration
-- ────────────────────────────────────────
-- Need: Process payments when invoice is finalized
-- Volume: 50-200 calls per day
-- Security: Critical - PCI compliance required
-- RECOMMENDED: External C# application with proper security
--              SQL Server 2025 with Managed Identity second choice

-- SCENARIO 5: Geocoding Addresses
-- ────────────────────────────────
-- Need: Convert addresses to lat/long coordinates
-- Volume: Batch processing, 10,000 addresses monthly
-- RECOMMENDED: SQL Agent PowerShell job (nightly batch)
--              OR: SQL Server 2025 triggered by table changes

-- SCENARIO 6: Social Media Integration
-- ─────────────────────────────────────
-- Need: Post updates to Twitter/LinkedIn when product launches
-- Volume: 10-20 calls per month
-- RECOMMENDED: PowerShell via xp_cmdshell (simplicity over security for low volume)
--              OR: SQL Server 2025 if available

-- SCENARIO 7: AI/ML Model Inference
-- ──────────────────────────────────
-- Need: Send data to Azure OpenAI or custom ML endpoint
-- Volume: Variable, potentially high
-- RECOMMENDED: SQL Server 2025 (built for this scenario!)
--              Alternative: SQL CLR for on-premises ML models

-- SCENARIO 8: ETL from External REST API
-- ───────────────────────────────────────
-- Need: Daily extraction of data from partner API
-- Volume: Once per day, thousands of records
-- RECOMMENDED: SQL Agent PowerShell job with robust error handling

/*******************************************************************************
  SECURITY BEST PRACTICES (ALL METHODS)
*******************************************************************************/

-- 1. CREDENTIAL MANAGEMENT
-- ─────────────────────────
-- ✓ DO:
--   • Store API keys in database credentials (SQL 2025)
--   • Use Windows Credential Manager for PowerShell
--   • Implement key rotation policies
--   • Use Managed Identity when possible (Azure)
--   • Encrypt stored credentials

-- ✗ DON'T:
--   • Hard-code API keys in scripts
--   • Store credentials in plain text
--   • Share credentials across environments
--   • Log credential values

-- Example: Secure credential storage
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrongPassword!123';
GO

CREATE DATABASE SCOPED CREDENTIAL APICredential
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"Authorization": "Bearer YOUR_TOKEN"}';
GO

-- 2. LEAST PRIVILEGE PRINCIPLE
-- ─────────────────────────────
-- Grant only necessary permissions:
GRANT EXECUTE ANY EXTERNAL ENDPOINT TO [APICallerUser];
-- Don't grant sysadmin unless absolutely necessary

-- 3. NETWORK SECURITY
-- ────────────────────
-- ✓ Always use HTTPS (TLS 1.2+)
-- ✓ Implement firewall rules
-- ✓ Use VPN for sensitive data
-- ✓ Whitelist IP addresses when possible

-- 4. INPUT VALIDATION
-- ───────────────────
CREATE OR ALTER PROCEDURE dbo.CallAPISecure
    @url NVARCHAR(MAX)
AS
BEGIN
    -- Validate URL
    IF @url NOT LIKE 'https://%'
    BEGIN
        RAISERROR('Only HTTPS URLs are allowed', 16, 1);
        RETURN;
    END
    
    -- Whitelist domains
    IF @url NOT LIKE 'https://api.trusted-domain.com/%'
       AND @url NOT LIKE 'https://api.partner-domain.com/%'
    BEGIN
        RAISERROR('URL domain not in whitelist', 16, 1);
        RETURN;
    END
    
    -- Proceed with API call...
END;
GO

-- 5. AUDITING AND LOGGING
-- ────────────────────────
CREATE TABLE dbo.APICallAuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    CalledBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    APIUrl NVARCHAR(500),
    Method NVARCHAR(10),
    StatusCode INT,
    Success BIT,
    CalledAt DATETIME2 DEFAULT GETDATE(),
    ErrorMessage NVARCHAR(MAX)
);
GO

-- Log every API call
CREATE OR ALTER PROCEDURE dbo.CallAPIWithAudit
    @url NVARCHAR(MAX)
AS
BEGIN
    DECLARE @success BIT = 0;
    DECLARE @statusCode INT;
    DECLARE @error NVARCHAR(MAX);
    
    BEGIN TRY
        -- Make API call (SQL 2025 example)
        DECLARE @response NVARCHAR(MAX);
        EXEC sp_invoke_external_rest_endpoint
            @url = @url,
            @response = @response OUTPUT;
        
        SET @statusCode = JSON_VALUE(@response, '$.response.status.http.code');
        SET @success = CASE WHEN @statusCode = 200 THEN 1 ELSE 0 END;
    END TRY
    BEGIN CATCH
        SET @error = ERROR_MESSAGE();
        SET @success = 0;
    END CATCH
    
    -- Always log
    INSERT INTO dbo.APICallAuditLog (APIUrl, Method, StatusCode, Success, ErrorMessage)
    VALUES (@url, 'GET', @statusCode, @success, @error);
END;
GO

/*******************************************************************************
  PERFORMANCE OPTIMIZATION TIPS
*******************************************************************************/

-- 1. CACHING
-- ──────────
CREATE TABLE dbo.APIResponseCache (
    CacheKey NVARCHAR(500) PRIMARY KEY,
    Response NVARCHAR(MAX),
    CachedAt DATETIME2 DEFAULT GETDATE(),
    ExpiresAt DATETIME2
);
GO

CREATE OR ALTER PROCEDURE dbo.CallAPIWithCache
    @url NVARCHAR(MAX),
    @cacheDurationMinutes INT = 60
AS
BEGIN
    DECLARE @cachedResponse NVARCHAR(MAX);
    
    -- Check cache
    SELECT @cachedResponse = Response
    FROM dbo.APIResponseCache
    WHERE CacheKey = @url
      AND ExpiresAt > GETDATE();
    
    IF @cachedResponse IS NOT NULL
    BEGIN
        -- Return cached response
        SELECT @cachedResponse AS Response, 'CACHED' AS Source;
        RETURN;
    END
    
    -- Call API and cache response
    DECLARE @response NVARCHAR(MAX);
    -- [API call code here]
    
    -- Store in cache
    MERGE dbo.APIResponseCache AS target
    USING (SELECT @url AS CacheKey) AS source
    ON target.CacheKey = source.CacheKey
    WHEN MATCHED THEN
        UPDATE SET Response = @response,
                   CachedAt = GETDATE(),
                   ExpiresAt = DATEADD(MINUTE, @cacheDurationMinutes, GETDATE())
    WHEN NOT MATCHED THEN
        INSERT (CacheKey, Response, ExpiresAt)
        VALUES (@url, @response, DATEADD(MINUTE, @cacheDurationMinutes, GETDATE()));
    
    SELECT @response AS Response, 'FRESH' AS Source;
END;
GO

-- 2. BATCHING
-- ───────────
-- Instead of calling API for each row, batch requests:
CREATE OR ALTER PROCEDURE dbo.BatchAPICall
AS
BEGIN
    -- Collect all pending items
    DECLARE @items NVARCHAR(MAX) = (
        SELECT ItemID, ItemData
        FROM PendingAPIItems
        FOR JSON PATH
    );
    
    -- Make single API call with batch
    DECLARE @response NVARCHAR(MAX);
    EXEC sp_invoke_external_rest_endpoint
        @url = 'https://api.example.com/batch',
        @method = 'POST',
        @payload = @items,
        @response = @response OUTPUT;
    
    -- Process batch response
    -- [Update individual items based on response]
END;
GO

-- 3. ASYNC PATTERN (For high volume)
-- ───────────────────────────────────
-- Queue API calls, process asynchronously:
CREATE TABLE dbo.APICallQueue (
    QueueID INT IDENTITY(1,1) PRIMARY KEY,
    APIUrl NVARCHAR(500),
    Payload NVARCHAR(MAX),
    Status NVARCHAR(20) DEFAULT 'PENDING', -- PENDING, PROCESSING, COMPLETED, FAILED
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ProcessedAt DATETIME2 NULL
);
GO

-- SQL Agent job processes queue every minute
-- This decouples API calls from main transaction

/*******************************************************************************
  MIGRATION GUIDE
*******************************************************************************/

-- From OLE Automation to SQL Server 2025
-- ───────────────────────────────────────

-- BEFORE (OLE Automation):
/*
DECLARE @obj INT, @response VARCHAR(MAX);
EXEC sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
EXEC sp_OAMethod @obj, 'open', NULL, 'GET', 'https://api.example.com/data', false;
EXEC sp_OAMethod @obj, 'send';
EXEC sp_OAGetProperty @obj, 'responseText', @response OUT;
EXEC sp_OADestroy @obj;
*/

-- AFTER (SQL Server 2025):
DECLARE @response NVARCHAR(MAX);
EXEC sp_invoke_external_rest_endpoint
    @url = 'https://api.example.com/data',
    @method = 'GET',
    @response = @response OUTPUT;

-- From PowerShell to SQL Server 2025
-- ───────────────────────────────────

-- BEFORE (PowerShell):
/*
DECLARE @ps NVARCHAR(MAX) = 
    'powershell -Command "Invoke-RestMethod -Uri ''https://api.example.com/data'' -Method Get | ConvertTo-Json"';
EXEC xp_cmdshell @ps;
*/

-- AFTER (SQL Server 2025):
DECLARE @response NVARCHAR(MAX);
EXEC sp_invoke_external_rest_endpoint
    @url = 'https://api.example.com/data',
    @method = 'GET',
    @response = @response OUTPUT;

/*******************************************************************************
  SUMMARY AND FINAL RECOMMENDATIONS
*******************************************************************************/

/*
  TIER 1 (BEST CHOICES):
────────────────────────
1. SQL Server 2025: sp_invoke_external_rest_endpoint
   → Use this for ALL new projects if available
   → Migrate existing solutions to this when possible

2. SQL Agent with PowerShell
   → Best for scheduled/recurring tasks
   → Good security model
   → Reliable and maintainable

  TIER 2 (GOOD CHOICES):
────────────────────────
3. SQL CLR (C#)
   → For high-performance scenarios
   → When you need .NET libraries
   → On-premises only

4. External C# Application
   → For microservices architecture
   → When building modern systems
   → Complex business logic

  TIER 3 (USE WITH CAUTION):
─────────────────────────────
5. PowerShell via xp_cmdshell
   → Quick prototyping only
   → Disable immediately after use
   → Not for production if alternatives exist

  TIER 4 (AVOID IF POSSIBLE):
──────────────────────────────
6. OLE Automation
   → Legacy systems only
   → Plan migration ASAP
   → High security risk

═══════════════════════════════════════════════════════════════

THE GOLDEN RULE:
If you have SQL Server 2025 or Azure SQL → Use sp_invoke_external_rest_endpoint
If you don't → Consider upgrading, seriously!

═══════════════════════════════════════════════════════════════
*/
