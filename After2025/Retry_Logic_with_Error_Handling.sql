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


CREATE OR ALTER PROCEDURE dbo.CallAPIWithRetry
    @url NVARCHAR(MAX),
    @maxRetries INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @response NVARCHAR(MAX);
    DECLARE @retcode INT;
    DECLARE @attemptNumber INT = 1;
    DECLARE @success BIT = 0;
    
    WHILE @attemptNumber <= @maxRetries AND @success = 0
    BEGIN
        BEGIN TRY
            PRINT CONCAT('Attempt ', @attemptNumber, ' of ', @maxRetries);
            
            -- Make API call with built-in retry
            EXEC @retcode = sp_invoke_external_rest_endpoint
                @url = @url,
                @method = 'GET',
                @timeout = 30,
                @retry_count = 2,  -- Built-in retry mechanism!
                @response = @response OUTPUT;
            
            -- Check status
            DECLARE @statusCode INT = JSON_VALUE(@response, '$.response.status.http.code');
            
            IF @statusCode = 200
            BEGIN
                SET @success = 1;
                PRINT 'Success!';
                SELECT JSON_QUERY(@response, '$.result') AS Data;
            END
            ELSE
            BEGIN
                PRINT CONCAT('Failed with status: ', @statusCode);
                SET @attemptNumber = @attemptNumber + 1;
                WAITFOR DELAY '00:00:02';  -- Wait 2 seconds before retry
            END
            
        END TRY
        BEGIN CATCH
            PRINT 'Error: ' + ERROR_MESSAGE();
            SET @attemptNumber = @attemptNumber + 1;
            IF @attemptNumber <= @maxRetries
                WAITFOR DELAY '00:00:02';
        END CATCH
    END
    
    IF @success = 0
        RAISERROR('API call failed after all retry attempts', 16, 1);
END;
GO
