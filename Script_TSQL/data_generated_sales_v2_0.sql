SET NOCOUNT ON

USE [DiscontStores]
GO

DROP TABLE IF EXISTS [test].[test_sales_header]
DROP TABLE IF EXISTS [test].[test_sales_detail]
GO

-- Table (15): sales_header
CREATE TABLE [test].[test_sales_header] (
    sales_id bigint NOT NULL IDENTITY(1, 1),
    stores_id smallint NOT NULL,
    sales_date date NOT NULL,
    sub_total money NOT NULL,
    modified_date datetime2 CONSTRAINT DF_sh_modified_date_timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_sales_id PRIMARY KEY (sales_id),
    CONSTRAINT FK_sales_h_stores FOREIGN KEY (stores_id) REFERENCES stores (stores_id)
)

-- Table (16): sales_detail
CREATE TABLE [test].[test_sales_detail] (
    detail_id bigint NOT NULL IDENTITY(1, 1),
	sales_id bigint NOT NULL,
    product_id int NOT NULL,
    unit smallint NOT NULL,
    unit_price smallmoney NOT NULL,
    unit_price_discount smallmoney NOT NULL DEFAULT 0,
    sales_value AS (isnull((unit_price*((1.0)-unit_price_discount))*[unit],(0.0))),
    modified_date datetime2 CONSTRAINT DF_sd_modified_date_timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CHK_discount CHECK ([unit_price_discount] >= 0 AND [unit_price_discount] <= [unit_price]),
    CONSTRAINT PK_detail_id PRIMARY KEY (detail_id)
)

--TRUNCATE TABLE [dbo].[test_sales_header]
--TRUNCATE TABLE [dbo].[test_sales_detail]

DECLARE @json NVARCHAR(max)

DECLARE @Store_Counter_min INT
	,@stores_id INT
	,@customer SMALLINT
	,@customer_counter SMALLINT
	,@s_date date
	,@s_date_start date
	,@s_date_end date
	
SET @s_date_start = '2021.01.01'
SET @s_date_end = '2021.06.31'
SET @s_date = @s_date_start

WHILE(@s_date <= @s_date_end)
BEGIN
	PRINT 'Date:' + CONVERT(varchar,@s_date)
	
	DECLARE stores_cursor CURSOR FOR   
		SELECT [stores_id] 
		FROM [sales].[stores] AS a 
		ORDER BY [stores_id]

	OPEN stores_cursor

	FETCH NEXT FROM stores_cursor   
		INTO @stores_id

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SELECT 
			@customer = CASE
				WHEN b.[format_type_2] = 'SM' THEN [application].fn_GetRandomDefault(45,75)
				WHEN b.[format_type_2] = 'MM' THEN [application].fn_GetRandomDefault(75,125)
				WHEN b.[format_type_2] = 'HM' THEN [application].fn_GetRandomDefault(150,225)
				ELSE [application].fn_GetRandomDefault(45,75)
			END
		FROM [sales].[stores] AS a
		LEFT JOIN [sales].[stores_format] AS b
			ON a.[format_id] = b.[format_id]
		WHERE [stores_id] = @stores_id

		SET @customer_Counter = 1

		WHILE(@customer_Counter <= @customer)
		BEGIN

			EXEC [application].sp_sales_calculated_JSON @s_date, @stores_id, @json = @json OUTPUT
			EXEC [application].sp_sales_insert_JSON_test @s_date, @stores_id, @json
			
			SET @customer_counter = @customer_counter + 1
		END
		
		FETCH NEXT FROM stores_cursor   
			INTO @stores_id
	END

	CLOSE stores_cursor  
	DEALLOCATE stores_cursor

	SET @s_date  = DATEADD(day,1,@s_date)
END