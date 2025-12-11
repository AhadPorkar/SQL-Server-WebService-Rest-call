-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallAPI_PowerShell_POST
    @url NVARCHAR(MAX),
    @jsonBody NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Escape single quotes in JSON
    SET @jsonBody = REPLACE(@jsonBody, '''', '''''');
    
    -- Build PowerShell command
    SET @powershell = N'powershell -Command "' +
        N'$headers = @{''Content-Type''=''application/json''}; ' +
        N'$body = ''' + @jsonBody + '''; ' +
        N'$response = Invoke-RestMethod -Uri ''' + @url + ''' -Method Post -Headers $headers -Body $body; ' +
        N'$response | ConvertTo-Json -Depth 10"';
    
    -- Execute PowerShell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return results
    SELECT STRING_AGG(line, '') AS JsonResponse
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
