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
 
CREATE OR ALTER PROCEDURE dbo.CallWebService_New_GET
    @url NVARCHAR(MAX) = 'https://api.publicapis.org/entries'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @response NVARCHAR(MAX);
    DECLARE @retcode INT;
    
    -- Make the API call - it's this simple!
    EXEC @retcode = sp_invoke_external_rest_endpoint
        @url = @url,
        @method = 'GET',
        @response = @response OUTPUT;
    
    -- Parse the response
    SELECT 
        JSON_VALUE(@response, '$.response.status.http.code') AS StatusCode,
        JSON_VALUE(@response, '$.response.status.http.description') AS StatusDescription,
        JSON_QUERY(@response, '$.result') AS ResponseBody;
    
    -- Extract specific data from JSON response
    SELECT 
        JSON_VALUE(value, '$.API') AS APIName,
        JSON_VALUE(value, '$.Description') AS Description,
        JSON_VALUE(value, '$.Category') AS Category
    FROM OPENJSON(JSON_QUERY(@response, '$.result.entries'));
    
    RETURN @retcode;
END;
GO
