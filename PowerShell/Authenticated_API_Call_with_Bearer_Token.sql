-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallAPI_PowerShell_Authenticated
    @url NVARCHAR(MAX),
    @bearerToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Build PowerShell command with authentication
    SET @powershell = N'powershell -Command "' +
        N'$headers = @{ ' +
        N'  ''Authorization'' = ''Bearer ' + @bearerToken + '''; ' +
        N'  ''Accept'' = ''application/json'' ' +
        N'}; ' +
        N'try { ' +
        N'  $response = Invoke-RestMethod -Uri ''' + @url + ''' -Method Get -Headers $headers; ' +
        N'  $response | ConvertTo-Json -Depth 10 ' +
        N'} catch { ' +
        N'  Write-Output \"Error: $($_.Exception.Message)\" ' +
        N'}"';
    
    -- Execute PowerShell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return results
    SELECT STRING_AGG(line, '') AS JsonResponse
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
