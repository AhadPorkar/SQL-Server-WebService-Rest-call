-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallMultipleAPIs_Parallel
    @urls NVARCHAR(MAX)  -- Comma-separated list of URLs
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Escape quotes
    SET @urls = REPLACE(@urls, '''', '''''');
    
    -- Build PowerShell script with parallel execution
    SET @powershell = N'powershell -Command "' +
        N'$urls = ''' + @urls + ''' -split '',''; ' +
        N'$results = $urls | ForEach-Object -Parallel { ' +
        N'  try { ' +
        N'    $response = Invoke-RestMethod -Uri $_.Trim() -Method Get -TimeoutSec 10; ' +
        N'    @{ Url = $_.Trim(); Success = $true; Data = ($response | ConvertTo-Json -Compress) } ' +
        N'  } catch { ' +
        N'    @{ Url = $_.Trim(); Success = $false; Error = $_.Exception.Message } ' +
        N'  } ' +
        N'} -ThrottleLimit 5; ' +
        N'$results | ConvertTo-Json -Depth 10"';
    
    -- Execute PowerShell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return combined results
    SELECT STRING_AGG(line, '') AS JsonResults
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
