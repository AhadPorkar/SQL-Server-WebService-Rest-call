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


-- First, create a database scoped credential for authentication
CREATE DATABASE SCOPED CREDENTIAL [MyAPICredential]
WITH IDENTITY = 'HTTPEndpointHeaders',
SECRET = '{"Authorization": "Bearer YOUR_API_TOKEN_HERE"}';
GO

CREATE OR ALTER PROCEDURE dbo.CallWebService_New_Authenticated
    @url NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @response NVARCHAR(MAX);
    DECLARE @retcode INT;
    
    -- Make authenticated API call
    EXEC @retcode = sp_invoke_external_rest_endpoint
        @url = @url,
        @method = 'GET',
        @credential = 'MyAPICredential',  -- Use the credential we created
        @timeout = 30,
        @response = @response OUTPUT;
    
    -- Check for success
    DECLARE @statusCode INT = JSON_VALUE(@response, '$.response.status.http.code');
    
    IF @statusCode = 200
    BEGIN
        SELECT 'Success' AS Status, JSON_QUERY(@response, '$.result') AS Data;
    END
    ELSE
    BEGIN
        SELECT 
            'Error' AS Status,
            @statusCode AS StatusCode,
            JSON_VALUE(@response, '$.response.status.http.description') AS ErrorDescription;
    END
    
    RETURN @retcode;
END;
GO
