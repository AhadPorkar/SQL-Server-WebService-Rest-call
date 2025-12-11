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


-- Create table for weather data
CREATE TABLE IF NOT EXISTS dbo.WeatherData (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    City NVARCHAR(100),
    Temperature DECIMAL(5,2),
    Humidity INT,
    Description NVARCHAR(200),
    FetchedAt DATETIME2 DEFAULT GETDATE()
);
GO

CREATE OR ALTER PROCEDURE dbo.FetchWeatherData
    @city NVARCHAR(100),
    @apiKey NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @url NVARCHAR(MAX);
    DECLARE @response NVARCHAR(MAX);
    DECLARE @retcode INT;
    
    -- Build the API URL (example: OpenWeatherMap API)
    SET @url = CONCAT(
        'https://api.openweathermap.org/data/2.5/weather?q=',
        @city,
        '&appid=',
        @apiKey,
        '&units=metric'
    );
    
    BEGIN TRY
        -- Call the weather API
        EXEC @retcode = sp_invoke_external_rest_endpoint
            @url = @url,
            @method = 'GET',
            @timeout = 15,
            @response = @response OUTPUT;
        
        -- Check status
        DECLARE @statusCode INT = JSON_VALUE(@response, '$.response.status.http.code');
        
        IF @statusCode = 200
        BEGIN
            -- Extract weather data
            DECLARE @temperature DECIMAL(5,2) = JSON_VALUE(@response, '$.result.main.temp');
            DECLARE @humidity INT = JSON_VALUE(@response, '$.result.main.humidity');
            DECLARE @description NVARCHAR(200) = JSON_VALUE(@response, '$.result.weather[0].description');
            
            -- Store in table
            INSERT INTO dbo.WeatherData (City, Temperature, Humidity, Description)
            VALUES (@city, @temperature, @humidity, @description);
            
            -- Return results
            SELECT 
                @city AS City,
                @temperature AS Temperature,
                @humidity AS Humidity,
                @description AS Description,
                'Data stored successfully' AS Status;
        END
        ELSE
        BEGIN
            RAISERROR('API call failed with status code: %d', 16, 1, @statusCode);
        END
        
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            'Failed to fetch weather data' AS Status;
    END CATCH
END;
GO
