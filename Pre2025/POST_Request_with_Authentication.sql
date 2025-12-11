CREATE OR ALTER PROCEDURE dbo.CallWebService_OldMethod_POST
    @url NVARCHAR(MAX),
    @jsonPayload NVARCHAR(MAX),
    @apiKey NVARCHAR(255) = NULL
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
        RAISERROR('Failed to create HTTP object', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        -- Open connection
        EXEC @Result = sp_OAMethod @Object, 'open', NULL, 'POST', @url, false;
        
        -- Set request headers
        EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
        
        -- Add API key if provided
        IF @apiKey IS NOT NULL
        BEGIN
            EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Authorization', @apiKey;
        END
        
        -- Send request with payload
        EXEC @Result = sp_OAMethod @Object, 'send', NULL, @jsonPayload;
        
        -- Get status code
        EXEC sp_OAGetProperty @Object, 'status', @StatusCode OUT;
        
        -- Get response text
        EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;
        
        -- Display results
        SELECT 
            @StatusCode AS StatusCode,
            @ResponseText AS ResponseText,
            CASE 
                WHEN @StatusCode BETWEEN 200 AND 299 THEN 'Success'
                WHEN @StatusCode BETWEEN 400 AND 499 THEN 'Client Error'
                WHEN @StatusCode BETWEEN 500 AND 599 THEN 'Server Error'
                ELSE 'Unknown'
            END AS StatusCategory;
            
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Clean up
    EXEC sp_OADestroy @Object;
END;
GO
