-- Enable xp_cmdshell (requires sysadmin privileges)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO


-- Save this as a .ps1 file and call it from SQL
-- File: C:\Scripts\CallAPI.ps1

/*
# CallAPI.ps1
param(
    [string]$ApiUrl,
    [string]$Method = "GET",
    [string]$Body = $null,
    [string]$ConnectionString = "Server=localhost;Database=YourDB;Integrated Security=True;"
)

try {
    Write-Host "Calling API: $ApiUrl"
    
    # Prepare request parameters
    $params = @{
        Uri = $ApiUrl
        Method = $Method
        ContentType = "application/json"
        UseBasicParsing = $true
        TimeoutSec = 30
    }
    
    if ($Body) {
        $params.Body = $Body
    }
    
    # Call API
    $response = Invoke-RestMethod @params
    $responseJson = $response | ConvertTo-Json -Depth 10 -Compress
    
    # Connect to SQL Server
    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $connection.Open()
    
    # Insert results
    $query = @"
        INSERT INTO APICallResults (JobName, APIUrl, StatusCode, ResponseData, Success)
        VALUES ('PowerShellScript', @ApiUrl, 200, @Response, 1)
"@
    
    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $command.Parameters.AddWithValue("@ApiUrl", $ApiUrl)
    $command.Parameters.AddWithValue("@Response", $responseJson)
    
    $rowsAffected = $command.ExecuteNonQuery()
    $connection.Close()
    
    Write-Host "Success: $rowsAffected row(s) inserted"
    return 0
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    
    # Log error to SQL
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $errorQuery = @"
            INSERT INTO APICallResults (JobName, APIUrl, StatusCode, ResponseData, Success)
            VALUES ('PowerShellScript', @ApiUrl, 500, @Error, 0)
"@
        
        $errorCommand = New-Object System.Data.SqlClient.SqlCommand($errorQuery, $connection)
        $errorCommand.Parameters.AddWithValue("@ApiUrl", $ApiUrl)
        $errorCommand.Parameters.AddWithValue("@Error", $_.Exception.Message)
        
        $errorCommand.ExecuteNonQuery()
        $connection.Close()
    }
    catch {
        Write-Error "Failed to log error to database"
    }
    
    return 1
}
*/

-- Call the PowerShell script from SQL Server
CREATE OR ALTER PROCEDURE dbo.CallAPI_PowerShellScript
    @apiUrl NVARCHAR(MAX),
    @method NVARCHAR(10) = 'GET',
    @body NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @powershell NVARCHAR(MAX);
    DECLARE @result TABLE (line NVARCHAR(MAX));
    
    -- Build command to execute external PowerShell script
    SET @powershell = N'powershell -ExecutionPolicy Bypass -File "C:\Scripts\CallAPI.ps1" ' +
        N'-ApiUrl "' + @apiUrl + '" ' +
        N'-Method "' + @method + '"';
    
    IF @body IS NOT NULL
    BEGIN
        SET @body = REPLACE(@body, '"', '\"');
        SET @powershell = @powershell + N' -Body "' + @body + '"';
    END;
    
    -- Execute PowerShell script
    INSERT INTO @result
    EXEC xp_cmdshell @powershell;
    
    -- Return results
    SELECT line AS Output
    FROM @result
    WHERE line IS NOT NULL;
END;
GO
