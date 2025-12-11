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

CREATE OR ALTER PROCEDURE dbo.CallWebService_New_POST
    @url NVARCHAR(MAX),
    @jsonPayload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @response NVARCHAR(MAX);
    DECLARE @headers NVARCHAR(MAX);
    DECLARE @retcode INT;
    
    -- Set custom headers
    SET @headers = JSON_OBJECT('Content-Type': 'application/json', 'Accept': 'application/json');
    
    -- Make the POST request
    EXEC @retcode = sp_invoke_external_rest_endpoint
        @url = @url,
        @method = 'POST',
        @payload = @jsonPayload,
        @headers = @headers,
        @timeout = 30,  -- Timeout in seconds
        @response = @response OUTPUT;
    
    -- Parse response
    DECLARE @statusCode INT = JSON_VALUE(@response, '$.response.status.http.code');
    DECLARE @responseBody NVARCHAR(MAX) = JSON_QUERY(@response, '$.result');
    
    SELECT 
        @statusCode AS StatusCode,
        CASE 
            WHEN @statusCode BETWEEN 200 AND 299 THEN 'Success'
            WHEN @statusCode BETWEEN 400 AND 499 THEN 'Client Error'
            WHEN @statusCode BETWEEN 500 AND 599 THEN 'Server Error'
            ELSE 'Unknown'
        END AS StatusCategory,
        @responseBody AS ResponseBody;
    
    RETURN @retcode;
END;
GO
