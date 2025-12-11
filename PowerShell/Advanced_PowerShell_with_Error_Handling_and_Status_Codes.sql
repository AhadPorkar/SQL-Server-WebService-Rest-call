-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallAPI_PowerShell_Advanced
    @url NVARCHAR(MAX),
    @method NVARCHAR(10) = 'GET',
    @headers NVARCHAR(MAX) = NULL,
    @body NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Escape quotes
    SET @url = REPLACE(@url, '''', '''''');
    IF @body IS NOT NULL
        SET @body = REPLACE(@body, '''', '''''');
    
    -- Build comprehensive PowerShell script
    SET @powershell = N'powershell -Command "' +
        N'$ProgressPreference = ''SilentlyContinue''; ' +
        N'try { ' +
        N'  $params = @{ ' +
        N'    Uri = ''' + @url + '''; ' +
        N'    Method = ''' + @method + '''; ' +
        N'    UseBasicParsing = $true; ' +
        N'    TimeoutSec = 30 ' +
        N'  }; ';
    
    -- Add headers if provided
    IF @headers IS NOT NULL
    BEGIN
        SET @powershell = @powershell +
            N'  $params.Headers = ' + @headers + '; ';
    END
    
    -- Add body if provided
    IF @body IS NOT NULL
    BEGIN
        SET @powershell = @powershell +
            N'  $params.Body = ''' + @body + '''; ' +
            N'  $params.ContentType = ''application/json''; ';
    END
    
    SET @powershell = @powershell +
        N'  $response = Invoke-WebRequest @params; ' +
        N'  $result = @{ ' +
        N'    StatusCode = $response.StatusCode; ' +
        N'    StatusDescription = $response.StatusDescription; ' +
        N'    Content = $response.Content ' +
        N'  }; ' +
        N'  $result | ConvertTo-Json -Depth 10 ' +
        N'} catch { ' +
        N'  $errorResult = @{ ' +
        N'    StatusCode = $_.Exception.Response.StatusCode.value__; ' +
        N'    Error = $_.Exception.Message ' +
        N'  }; ' +
        N'  $errorResult | ConvertTo-Json ' +
        N'}"';
    
    -- Execute PowerShell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Parse and return structured results
    DECLARE @jsonResponse NVARCHAR(MAX) = (
        SELECT STRING_AGG(line, '')
        FROM @result
        WHERE line IS NOT NULL
    );
    
    SELECT 
        JSON_VALUE(@jsonResponse, '$.StatusCode') AS StatusCode,
        JSON_VALUE(@jsonResponse, '$.StatusDescription') AS StatusDescription,
        JSON_QUERY(@jsonResponse, '$.Content') AS ResponseContent,
        JSON_VALUE(@jsonResponse, '$.Error') AS ErrorMessage;
END;
GO
