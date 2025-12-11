-- Create table to store API responses
CREATE TABLE IF NOT EXISTS dbo.APIResponseLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    APIUrl NVARCHAR(500),
    RequestMethod NVARCHAR(10),
    StatusCode INT,
    ResponseData NVARCHAR(MAX),
    RequestTimestamp DATETIME2 DEFAULT GETDATE(),
    ProcessedFlag BIT DEFAULT 0
);
GO

CREATE OR ALTER PROCEDURE dbo.FetchAndStoreAPIData_OldMethod
    @apiUrl NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Object INT;
    DECLARE @ResponseText NVARCHAR(MAX);
    DECLARE @StatusCode INT;
    DECLARE @Result INT;
    
    BEGIN TRY
        -- Create HTTP object
        EXEC @Result = sp_OACreate 'MSXML2.ServerXMLHTTP', @Object OUT;
        
        -- Configure and send request
        EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @apiUrl, false;
        EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Accept', 'application/json';
        EXEC sp_OAMethod @Object, 'send';
        
        -- Get response
        EXEC sp_OAGetProperty @Object, 'status', @StatusCode OUT;
        EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;
        
        -- Log the response
        INSERT INTO dbo.APIResponseLog (APIUrl, RequestMethod, StatusCode, ResponseData)
        VALUES (@apiUrl, 'GET', @StatusCode, @ResponseText);
        
        -- Clean up
        EXEC sp_OADestroy @Object;
        
        -- Process the response if successful
        IF @StatusCode = 200
        BEGIN
            PRINT 'API call successful. Data logged with ID: ' + CAST(SCOPE_IDENTITY() AS VARCHAR(10));
        END
        ELSE
        BEGIN
            PRINT 'API call failed with status: ' + CAST(@StatusCode AS VARCHAR(10));
        END
        
    END TRY
    BEGIN CATCH
        IF @Object IS NOT NULL
            EXEC sp_OADestroy @Object;
            
        THROW;
    END CATCH
END;
GO
