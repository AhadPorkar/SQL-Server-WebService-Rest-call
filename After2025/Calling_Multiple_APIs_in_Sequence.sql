/*------------------------------------------------------------------------------
  Enable the feature (SQL Server 2025)
  Note: This is already enabled by default in Azure SQL Database
------------------------------------------------------------------------------*/

-- Enable REST endpoint feature (requires ALTER SETTINGS permission)
EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- Grant permission to user/role
-- GRANT EXECUTE ANY EXTERNAL ENDPOINT TO [YourUser];
GO


CREATE OR ALTER PROCEDURE dbo.ChainedAPIRequests
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @response1 NVARCHAR(MAX);
    DECLARE @response2 NVARCHAR(MAX);
    DECLARE @retcode INT;
    
    -- First API call
    EXEC @retcode = sp_invoke_external_rest_endpoint
        @url = 'https://api.publicapis.org/random',
        @method = 'GET',
        @response = @response1 OUTPUT;
    
    -- Extract data from first response
    DECLARE @firstAPILink NVARCHAR(500) = JSON_VALUE(@response1, '$.result.entries[0].Link');
    
    PRINT 'First API returned link: ' + ISNULL(@firstAPILink, 'NULL');
    
    -- Use data from first API in second call (if valid)
    IF @firstAPILink IS NOT NULL AND LEFT(@firstAPILink, 5) = 'https'
    BEGIN
        EXEC @retcode = sp_invoke_external_rest_endpoint
            @url = @firstAPILink,
            @method = 'GET',
            @timeout = 10,
            @response = @response2 OUTPUT;
        
        SELECT 
            JSON_QUERY(@response1, '$.result') AS FirstAPIResponse,
            JSON_VALUE(@response2, '$.response.status.http.code') AS SecondAPIStatus;
    END
END;
GO
