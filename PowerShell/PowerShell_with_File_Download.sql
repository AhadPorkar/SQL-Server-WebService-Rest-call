-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.DownloadFile_PowerShell
    @url NVARCHAR(MAX),
    @outputPath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Build PowerShell command to download file
    SET @powershell = N'powershell -Command "' +
        N'try { ' +
        N'  Invoke-WebRequest -Uri ''' + @url + ''' -OutFile ''' + @outputPath + '''; ' +
        N'  if (Test-Path ''' + @outputPath + ''') { ' +
        N'    $fileInfo = Get-Item ''' + @outputPath + '''; ' +
        N'    Write-Output \"Success: Downloaded $($fileInfo.Length) bytes to ' + @outputPath + '\" ' +
        N'  } ' +
        N'} catch { ' +
        N'  Write-Output \"Error: $($_.Exception.Message)\" ' +
        N'}"';
    
    -- Execute PowerShell
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return results
    SELECT line AS Result
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
