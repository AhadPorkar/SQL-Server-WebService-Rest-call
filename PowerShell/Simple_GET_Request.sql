-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallAPI_PowerShell_Simple
    @url NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Build PowerShell command
    SET @powershell = N'powershell -Command "' +
        N'$response = Invoke-RestMethod -Uri ''' + @url + ''' -Method Get; ' +
        N'$response | ConvertTo-Json -Depth 10"';
    
    -- Execute PowerShell via xp_cmdshell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return results (combine all lines)
    SELECT STRING_AGG(line, '') AS JsonResponse
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
