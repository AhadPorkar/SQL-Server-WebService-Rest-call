-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO


-- Create PowerShell script as a SQL Agent Job Step
USE msdb;
GO

-- First, let's create a table to store API results
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'APICallResults')
BEGIN
    CREATE TABLE dbo.APICallResults (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        JobName NVARCHAR(128),
        APIUrl NVARCHAR(500),
        StatusCode INT,
        ResponseData NVARCHAR(MAX),
        ExecutedAt DATETIME2 DEFAULT GETDATE(),
        Success BIT
    );
END;
GO

-- Create the SQL Agent Job
DECLARE @jobId BINARY(16);
DECLARE @ReturnCode INT = 0;

-- Check if job already exists
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'DailyAPIDataFetch')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'DailyAPIDataFetch';
END;

-- Create new job
EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name = N'DailyAPIDataFetch',
    @enabled = 1,
    @description = N'Fetches data from external API using PowerShell',
    @category_name = N'Data Collector',
    @job_id = @jobId OUTPUT;

-- Add PowerShell job step
EXEC msdb.dbo.sp_add_jobstep 
    @job_id = @jobId,
    @step_name = N'Fetch API Data',
    @step_id = 1,
    @subsystem = N'PowerShell',
    @command = N'
# PowerShell script to call API and store results
$apiUrl = "https://api.publicapis.org/random"

try {
    # Call the API
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 30
    $responseJson = $response | ConvertTo-Json -Depth 10
    
    # Store in SQL Server
    $connectionString = "Server=localhost;Database=YourDatabase;Integrated Security=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = @"
        INSERT INTO APICallResults (JobName, APIUrl, StatusCode, ResponseData, Success)
        VALUES (@JobName, @APIUrl, @StatusCode, @ResponseData, @Success)
"@
    
    $command.Parameters.AddWithValue("@JobName", "DailyAPIDataFetch")
    $command.Parameters.AddWithValue("@APIUrl", $apiUrl)
    $command.Parameters.AddWithValue("@StatusCode", 200)
    $command.Parameters.AddWithValue("@ResponseData", $responseJson)
    $command.Parameters.AddWithValue("@Success", 1)
    
    $command.ExecuteNonQuery()
    $connection.Close()
    
    Write-Output "Success: API data fetched and stored"
}
catch {
    Write-Error "Failed to fetch API data: $($_.Exception.Message)"
    throw
}',
    @database_name = N'master',
    @on_success_action = 1,
    @on_fail_action = 2;

-- Add schedule (daily at 2 AM)
EXEC msdb.dbo.sp_add_jobschedule 
    @job_id = @jobId,
    @name = N'Daily at 2 AM',
    @enabled = 1,
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 20000;  -- 2:00 AM

-- Add job server
EXEC msdb.dbo.sp_add_jobserver 
    @job_id = @jobId,
    @server_name = N'(local)';

PRINT 'SQL Agent job created successfully';
GO
