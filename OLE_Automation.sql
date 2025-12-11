-- Enable OLE Automation Procedures (requires sysadmin)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO

/*------------------------------------------------------------------------------
  Example 1: Simple GET Request (Pre-2025)
  Calling a public REST API to get weather data
------------------------------------------------------------------------------*/
CREATE OR ALTER PROCEDURE dbo.CallWebService_OldMethod_GET
    @url NVARCHAR(MAX) = 'https://api.publicapis.org/entries'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Object INT;
    DECLARE @ResponseText VARCHAR(MAX);
    DECLARE @Result INT;
    DECLARE @StatusCode INT;
    
    -- Create HTTP object
    EXEC @Result = sp_OACreate 'MSXML2.ServerXMLHTTP', @Object OUT;
    IF @Result <> 0
    BEGIN
        PRINT 'Error creating HTTP object';
        RETURN;
    END
    
    -- Open connection
    EXEC @Result = sp_OAMethod @Object, 'open', NULL, 'GET', @url, false;
    IF @Result <> 0
    BEGIN
        PRINT 'Error opening connection';
        EXEC sp_OADestroy @Object;
        RETURN;
    END
    
    -- Set request headers
    EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
    
    -- Send request
    EXEC @Result = sp_OAMethod @Object, 'send';
    IF @Result <> 0
    BEGIN
        PRINT 'Error sending request';
        EXEC sp_OADestroy @Object;
        RETURN;
    END
    
    -- Get status code
    EXEC sp_OAGetProperty @Object, 'status', @StatusCode OUT;
    
    -- Get response text
    EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;
    
    -- Clean up
    EXEC sp_OADestroy @Object;
    
    -- Display results
    PRINT 'Status Code: ' + CAST(@StatusCode AS VARCHAR(10));
    PRINT 'Response: ' + LEFT(@ResponseText, 1000); -- Show first 1000 chars
    
    -- Parse JSON response (SQL Server 2016+)
    IF @StatusCode = 200
    BEGIN
        SELECT * 
        FROM OPENJSON(@ResponseText)
        WITH (
            count INT '$.count',
            entries NVARCHAR(MAX) '$.entries' AS JSON
        );
    END
END;
GO
