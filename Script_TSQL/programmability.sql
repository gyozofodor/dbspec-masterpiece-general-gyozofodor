USE [DiscontStores]
GO

CREATE or ALTER FUNCTION [application].[fn_GetDateRange_To_Table] (@minDate DATE, @maxDate DATE)
RETURNS @Result TABLE(Date DATE NOT NULL)
AS
BEGIN

    INSERT INTO @Result(Date) VALUES(@minDate)
    
    WHILE @maxDate > @minDate
    BEGIN
        SET @minDate = (SELECT DATEADD(dd,1,@minDate))
        INSERT INTO @Result(Date) VALUES(@minDate)
    END

    RETURN
END
GO

CREATE or ALTER FUNCTION [application].[fn_GetRandomDefault] (@min_value INT, @max_value INT)
RETURNS int AS
BEGIN
  RETURN (SELECT FLOOR([Value] * (@max_value - @min_value + 1)) + @min_value AS Rand_Value 
  			FROM [application].[vw_getRANDValue])
END
GO

CREATE or ALTER FUNCTION [application].[fn_GetLogin_Name] (@session_id INT)
RETURNS varchar(255) AS
BEGIN
  RETURN (SELECT login_name FROM sys.dm_exec_sessions WHERE session_id = @session_id)
END
GO

CREATE or ALTER FUNCTION [application].[fn_GetTrigger_TableName] ( @proc_id INT)
RETURNS varchar(255) AS
BEGIN
  RETURN (SELECT object_schema_name(parent_id) + '.' + object_name(parent_id) 
    FROM sys.triggers where object_id = @proc_id)
END
GO

CREATE or ALTER PROCEDURE [application].[sp_product_range_count]
AS
	BEGIN TRY
		WITH product_CTE
		AS
		(
			SELECT 
				a.[product_id],	
				b.[DIV],	
				b.[DEP],	
				b.[SEC],
				b.[GRP],
				b.[DIV_name],	
				b.[DEP_name],
				b.[SEC_name],
				b.[GRP_name]
			FROM [production].[product] AS a
			INNER JOIN [production].[vw_GetCategory_4_dep] AS b
				ON a.[GRP] = b.[GRP]
		)
		,
		product_aggr_CTE
		AS
		(
			SELECT 
				b.[DIV],	
				b.[DEP],	
				b.[SEC],
				b.[GRP],
				b.[DIV_name],	
				b.[DEP_name],
				b.[SEC_name],
				b.[GRP_name],
				COUNT(*) AS number_of_product
			FROM [production].[product] AS a
			INNER JOIN [production].[vw_GetCategory_4_dep] AS b
				ON a.[GRP] = b.[GRP]
			GROUP BY b.[DIV], b.[DEP], b.[SEC],	b.[GRP], b.[DIV_name], b.[DEP_name], b.[SEC_name], b.[GRP_name]
		)
		,
		range_CTE
		AS
		(
			SELECT 
				a.[stores_id],
				a.[product_id],
				c.[format_type_2]
			FROM [availability].[product_range] AS a
			LEFT JOIN [sales].[stores] AS b
				ON a.[stores_id] = b.[stores_id]
			LEFT JOIN [sales].[stores_format] AS c
				ON b.[format_id] = c.[format_id]
			WHERE a.[range] = 'R'
		)
		,
		range_agg_store_format_CTE
		AS
		(
			SELECT 
				t1.DIV,
				t1.DEP,
				t1.SEC,
				t1.GRP,
				t1.format_type_2,
				AVG(t1.number_of_stores) AS number_of_product_in_format
			FROM
			(
				SELECT 
					cte1.stores_id,
					cte2.DIV,
					cte2.DEP,
					cte2.SEC,
					cte2.GRP,
					cte1.format_type_2,
					COUNT(*) AS	number_of_stores
				FROM range_CTE AS cte1
				LEFT JOIN product_CTE AS cte2
					ON cte1.product_id = cte2.product_id
				GROUP BY cte1.stores_id, cte2.DIV, cte2.DEP, cte2.SEC, cte2.GRP, cte1.format_type_2
			) AS t1
			GROUP BY t1.DIV, t1.DEP, t1.SEC, t1.GRP, t1.format_type_2
		)
		,
		range_pivote_CTE
		AS
		(
			SELECT *
			FROM
			(
			SELECT *
				FROM range_agg_store_format_CTE
			) AS SourceTable 
				PIVOT(MAX([number_of_product_in_format]) FOR [format_type_2] IN([SM],[MM],[HM])) AS PivotTable
		)

		SELECT 
			t1.[DIV_name],	
			t1.[DEP_name],
			t1.[SEC_name],
			t1.[GRP_name],
			t1.number_of_product,
			t2.SM AS number_of_SM,
			t2.MM AS number_of_MM,
			t2.HM AS number_of_HM
		FROM product_aggr_CTE AS t1
		LEFT JOIN range_pivote_CTE AS t2
			ON t1.DIV = t2.DIV AND t1.DEP = t2.DEP AND t1.SEC = t2.SEC AND t1.GRP = t2.GRP
		ORDER BY t1.DIV, t1.DEP, t1.SEC, t1.GRP

		RETURN 0
	END TRY
	BEGIN CATCH
		PRINT 'Select failed!'
		PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
		PRINT 'Error message: ' + ERROR_MESSAGE()
		
		RETURN 1
	END CATCH
GO

CREATE or ALTER PROCEDURE [application].[sp_sales_calculeted]
	@store_id SMALLINT
AS
	DECLARE @product_minId INT
		,@product_maxId INT
		,@cart_counter SMALLINT = 1

	DECLARE @product_table TABLE (
			product_id INT
		)
	
	SET NOCOUNT ON
		
	SELECT 
		@product_minId = min([product_id]),
		@product_MaxId = max([product_id])
	FROM [production].[product] AS a	

	WHILE(@cart_counter <= [application].fn_GetRandomDefault(8,50))
	BEGIN
		
		INSERT INTO @product_table(product_id) 
			VALUES([application].fn_GetRandomDefault(@product_minId,@product_MaxId))

		SET @cart_counter = @cart_counter + 1
	END
	
	;WITH sales_product_CTE
	AS
	(
	SELECT
		t1.*
	FROM (
		SELECT 
			ROW_NUMBER() over(partition by a.[stores_id] order by a.[stores_id],a.[product_id]) As rw_number,
			a.[stores_id],
			a.[product_id],
			CASE
			WHEN DIV = 3 THEN application.fn_GetRandomDefault(0,1)
			WHEN DEP = 21 THEN application.fn_GetRandomDefault(0,5)
			WHEN DEP = 22 THEN application.fn_GetRandomDefault(0,5)
			WHEN DEP = 23 THEN application.fn_GetRandomDefault(0,2)
			WHEN DEP = 24 THEN application.fn_GetRandomDefault(0,2)
			WHEN DEP = 25 THEN application.fn_GetRandomDefault(0,2)
			WHEN DEP = 26 THEN application.fn_GetRandomDefault(0,2)
			ELSE application.fn_GetRandomDefault(0,1)
			END unit,
			d.[price]
		FROM [availability].[product_range] AS a
		LEFT JOIN [production].[product] AS b
			ON a.[product_id] = b.[product_id]
		LEFT JOIN [production].[vw_GetCategory_4_dep] AS c
			ON b.[GRP] = c.[GRP]
		LEFT JOIN [production].[product_price] AS d
			ON b.[product_id] = d.[product_id]
		WHERE a.[stores_id] = @store_id
			AND a.[range] = 'R'
	) AS t1
	WHERE unit > 0
	)
	,
	sales_product_find_CTE
	AS
	(
		SELECT DISTINCT product_id FROM @product_table
	)

	SELECT 
		a.[product_id],
		a.[unit],
		a.[price] AS "unit_price",
		0 AS "unit_price_discount"
	FROM sales_product_CTE AS a
	INNER JOIN sales_product_find_CTE AS b
		ON a.product_id = b.product_id
GO

CREATE or ALTER PROCEDURE [application].[sp_sales_calculated_JSON]
	@date DATE
	,@store_id SMALLINT
	,@json NVARCHAR(max) OUTPUT
AS
	SET NOCOUNT ON
	
	BEGIN TRY

		DECLARE @product_minId INT
			,@product_maxId INT
			,@cart_counter SMALLINT = 1

		DECLARE @product_table TABLE (
				product_id INT
			)
			
		SELECT 
			@product_minId = min([product_id]),
			@product_MaxId = max([product_id])
		FROM [production].[product] AS a	

		WHILE(@cart_counter <= [application].fn_GetRandomDefault(12,65))
		BEGIN
			INSERT INTO @product_table(product_id) 
				VALUES([application].fn_GetRandomDefault(@product_minId,@product_MaxId))

			SET @cart_counter = @cart_counter + 1
		END
	
		;WITH sales_product_CTE
		AS
		(
		SELECT
			t1.*
		FROM (
			SELECT 
				ROW_NUMBER() over(partition by a.[stores_id] order by a.[stores_id],a.[product_id]) As rw_number,
				a.[stores_id],
				a.[product_id],
				CASE
				WHEN DIV = 3 THEN application.fn_GetRandomDefault(0,1)
				WHEN DEP = 21 THEN application.fn_GetRandomDefault(0,5)
				WHEN DEP = 22 THEN application.fn_GetRandomDefault(0,5)
				WHEN DEP = 23 THEN application.fn_GetRandomDefault(0,2)
				WHEN DEP = 24 THEN application.fn_GetRandomDefault(0,2)
				WHEN DEP = 25 THEN application.fn_GetRandomDefault(0,2)
				WHEN DEP = 26 THEN application.fn_GetRandomDefault(0,2)
				ELSE application.fn_GetRandomDefault(0,1)
				END unit,
				d.[price]
			FROM [availability].[product_range] AS a
			LEFT JOIN [production].[product] AS b
				ON a.[product_id] = b.[product_id]
			LEFT JOIN [production].[vw_GetCategory_4_dep] AS c
				ON b.[GRP] = c.[GRP]
			LEFT JOIN [production].[product_price] AS d
				ON b.[product_id] = d.[product_id]
			WHERE a.[stores_id] = @store_id
				AND a.[range] = 'R'
		) AS t1
		WHERE unit > 0
		)
		,
		sales_product_find_CTE
		AS
		(
			SELECT DISTINCT product_id FROM @product_table AS a
			WHERE NOT EXISTS 
				(SELECT product_id 
				FROM [availability].[scanned_gap] AS b
				WHERE a.product_id = b.product_id
					AND stores_id = @store_id
					AND CONVERT(date,scanned_date) = @date
	)
		)

		SELECT @json = 
			(
			SELECT 
				a.[product_id],
				a.[unit],
				a.[price] AS "unit_price",
				0 AS "unit_price_discount"
			FROM sales_product_CTE AS a 
			INNER JOIN sales_product_find_CTE AS b
				ON a.product_id = b.product_id
			FOR JSON PATH
			)
		RETURN 0
	END TRY
	BEGIN CATCH
		PRINT 'Select failed!'
		PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
		PRINT 'Error message: ' + ERROR_MESSAGE()
		
		RETURN 1
	END CATCH
GO

CREATE or ALTER PROCEDURE [application].[sp_sales_insert_JSON]
	@s_date DATE
	,@store_id INT
	,@json NVARCHAR(max)
	
AS
	IF ISJSON(@json) = 1
	BEGIN
		DECLARE @inserted TABLE (
			[sales_id] INT	
		)
		
		DECLARE @procedure TABLE (
			[sales_id] BIGINT,
			[product_id] INT, 
			[unit] SMALLINT,
			[unit_price] SMALLMONEY,
			[unit_price_discount] MONEY
		)

		INSERT INTO @procedure([product_id],[unit],[unit_price],[unit_price_discount])
		SELECT *
		FROM OPENJSON(@json)
		  WITH (
			product_id INT,
			unit SMALLINT,
			unit_price MONEY,
			unit_price_discount MONEY
		  )

		IF (SELECT COUNT(*) FROM @procedure) != 0
		BEGIN
			BEGIN TRANSACTION		
				BEGIN TRY
					
					INSERT INTO [sales].[sales_header]([stores_id],[sales_date],[sub_total]) 
						OUTPUT INSERTED.[sales_id]
						INTO @inserted
						VALUES(@store_id,@s_date,ISNULL((SELECT SUM(isnull((unit_price*((1.0)-unit_price_discount))*[unit],(0.0))) FROM @procedure),(0.0)))
					
					UPDATE @procedure SET [sales_id] = (SELECT [sales_id] FROM @inserted)
							
					INSERT INTO [sales].[sales_detail]([sales_id],[product_id],[unit],[unit_price],[unit_price_discount])
						SELECT * FROM @procedure

					COMMIT TRANSACTION
					RETURN 0
				END TRY
				BEGIN CATCH 
					IF (@@TRANCOUNT > 0)
					BEGIN
						ROLLBACK TRANSACTION
						PRINT 'Error detected, all changes reversed'
						PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
						PRINT 'Error message: ' + ERROR_MESSAGE()
					END
					RETURN 1
				END CATCH
		END
	END
GO

CREATE or ALTER PROCEDURE [application].[sp_query_sales_datepart]
	@date_start DATE
	,@date_end DATE
	,@date_part VARCHAR(10) = 'd'
	,@ObjectName VARCHAR(50) = 'dep2'
	,@ObjectQty VARCHAR(50) = 'unit'
AS
	--exec application.sp_query_sales_datepart '2021-01-01','2021-06-30','w','dep4','value'
	
	SET NOCOUNT ON
	
	DECLARE @sprdElements AS NVARCHAR(MAX)			--comma separated, delimited, distinct list of product attributes
				,@tSql AS NVARCHAR(MAX)				--query text
				,@ObjectName_str VARCHAR(255)		--specific product name
				,@date_part_str VARCHAR(200)		--specific date_part string
				,@ObjectQty_str VARCHAR(200)		--specific data qty string
				,@date_part_type VARCHAR(200)		--check date_part type
				,@ObjectName_type VARCHAR(200)		--check name type
				,@ObjectQty_type VARCHAR(200)		--check data qty type
				,@sprdPrefix VARCHAR(1)
			
	SET @date_part_type = '{d},{w},{m},{q},{y}'
	SET @ObjectName_type = '{name},{dep1},{dep2},{dep3},{dep4},{stores_name},{format_type_1},{format_type_2},{city_name}'
	SET @ObjectQty_type = '{unit},{value}'

	IF (SELECT CHARINDEX('{' + @date_part + '}', @date_part_type)) != 0 
		AND (SELECT CHARINDEX('{' + @ObjectName + '}', @ObjectName_type)) != 0
		AND (SELECT CHARINDEX('{' + @ObjectQty + '}', @ObjectQty_type)) != 0
	BEGIN
	
		SET @sprdPrefix =
			CASE 
				WHEN @date_part = 'w' THEN 'W'
				WHEN @date_part = 'm' THEN 'M'
				WHEN @date_part = 'q' THEN 'Q'
				WHEN @date_part = 'y' THEN 'Y'
			END

		SET @date_part_str =
			CASE 
				WHEN @date_part = 'd' 
					THEN 'CONVERT(varchar,CONVERT(date,sales_date))'
				WHEN @date_part = 'w' 
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,sales_date)),''' + @sprdPrefix + 
						''',IIF(LEN(CONVERT(varchar,DATEPART(ww,CONVERT(date,sales_date)))) = 1,''0'','''') + CONVERT(varchar,DATEPART(ww,CONVERT(date,sales_date))))'
				WHEN @date_part = 'm'
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,sales_date)),''' + @sprdPrefix + 
						''',IIF(LEN(CONVERT(varchar,DATEPART(mm,CONVERT(date,sales_date)))) = 1,''0'','''') + CONVERT(varchar,DATEPART(m,CONVERT(date,sales_date))))'
				WHEN @date_part = 'q' 
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,sales_date)),''' + @sprdPrefix + ''',CONVERT(varchar,DATEPART(q,CONVERT(date,sales_date))))'
				WHEN @date_part = 'y' 
					THEN 'CONCAT_WS(''-'',''' + @sprdPrefix + ''',CONVERT(varchar,DATEPART(yyyy,CONVERT(date,sales_date))))'
			END

		SET @ObjectName_str = 
			CASE 
				WHEN @ObjectName = 'name' 
					THEN 'TRIM(c.[product_name])'
				WHEN @ObjectName = 'dep1' 
					THEN 'TRIM(c.[DIV_name])'
				WHEN @ObjectName = 'dep2' 
					THEN 'CONCAT_WS(''_'',TRIM(c.[DIV_name]),TRIM(c.[DEP_name]))'
				WHEN @ObjectName = 'dep3' 
					THEN 'CONCAT_WS(''_'',TRIM(c.[DIV_name]),TRIM(c.[DEP_name]),TRIM(c.[SEC_name]))'
				WHEN @ObjectName = 'dep4' 
					THEN 'CONCAT_WS(''_'',TRIM(c.[DIV_name]),TRIM(c.[DEP_name]),TRIM(c.[SEC_name]),TRIM(c.[GRP_name]))'
				WHEN @ObjectName = 'stores_name'
					THEN 'TRIM(d.[stores_name])'
				WHEN @ObjectName = 'format_type_1'
					THEN 'TRIM(d.[format_type_1])'
				WHEN @ObjectName = 'format_type_2'
					THEN 'TRIM(d.[format_type_2])'
				WHEN @ObjectName = 'city_name'
					THEN 'TRIM(d.[city_name_ascii])'
			END

		SET @ObjectQty_str =
			CASE 
				WHEN @ObjectQty = 'unit' THEN 'a.[unit]'
				WHEN @ObjectQty = 'value' THEN 'CONVERT(MONEY,a.[sales_value])'
			END

		--comma separated list of attributes for a product
		;WITH dsitSpreadElList AS
		(
			SELECT 
				DISTINCT 
				CASE 
					WHEN @date_part = 'd' 
						THEN CONCAT_WS('-',@sprdPrefix,CONVERT(varchar,CONVERT(date,sales_date)))
					WHEN @date_part = 'w' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,sales_date)),@sprdPrefix,IIF(LEN(CONVERT(varchar,DATEPART(ww,CONVERT(date,sales_date)))) = 1,'0','') + CONVERT(varchar,DATEPART(ww,CONVERT(date,sales_date))))
					WHEN @date_part = 'm' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,sales_date)),@sprdPrefix,IIF(LEN(CONVERT(varchar,DATEPART(mm,CONVERT(date,sales_date)))) = 1,'0','') + CONVERT(varchar,DATEPART(mm,CONVERT(date,sales_date))))
					WHEN @date_part = 'q' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,sales_date)),@sprdPrefix,CONVERT(varchar,DATEPART(q,CONVERT(date,sales_date))))
					WHEN @date_part = 'y' 
						THEN CONCAT_WS('-',@sprdPrefix,CONVERT(varchar,DATEPART(yyyy,CONVERT(date,sales_date))))
				END "Attribute"
			FROM [sales].[sales_header]
			WHERE [sales_date] BETWEEN @date_start AND @date_end
		)

		SELECT @sprdElements = STRING_AGG('[' + CONVERT(varchar,Attribute) + ']',',') WITHIN GROUP (ORDER BY Attribute ASC)
		FROM dsitSpreadElList;
	
		PRINT @sprdElements

		SET @tSql =N';WITH TabExp AS
					(
					SELECT '
						+  @ObjectName_str + ' AS "ObjectName",'
						+ @date_part_str + ' AS "Attribute",'
						+ @ObjectQty_str + ' AS "Value"
					FROM [sales].[sales_detail] AS a
					INNER JOIN [sales].[sales_header] AS b
						ON a.[sales_id] = b.[sales_id]
					INNER JOIN [production].[vw_Product_Info] AS c
						ON a.[product_id] = c.[product_id]
					INNER JOIN [sales].[vw_Stores_Info] AS d
						ON b.[stores_id] = d.[stores_id]
					WHERE b.[sales_date] BETWEEN ''' + CONVERT(VARCHAR,@date_start) + 
						''' AND ''' + CONVERT(VARCHAR,@date_end) + '''
					)
			
					SELECT ObjectName,' + @sprdElements + N'
					FROM TabExp
					PIVOT (
							SUM([Value])
							FOR Attribute IN (' + @sprdElements + N') 
							) AS pvt
					ORDER BY "ObjectName"';

		PRINT @tSql

		BEGIN TRY
			EXEC sys.sp_executesql @stmt = @tSql
			RETURN 0
		END TRY
		BEGIN CATCH
			PRINT 'Select failed!'
			PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
			PRINT 'Error message: ' + ERROR_MESSAGE()

			RETURN 1
		END CATCH
	END
GO

CREATE or ALTER PROCEDURE [application].[sp_query_availability_datepart]
	@date_start DATE
	,@date_end DATE
	,@date_part VARCHAR(10) = 'd'
	,@ObjectName VARCHAR(50) = 'dep2'
AS
	--exec application.sp_query_availability_datepart '2021-01-01','2021-06-30','w','dep3'
	
	SET NOCOUNT ON
	
	DECLARE @sprdElements AS NVARCHAR(MAX)			--comma separated, delimited, distinct list of product attributes
				,@tSql AS NVARCHAR(MAX)				--query text
				,@ObjectName_str VARCHAR(255)		--specific product name
				,@date_part_str VARCHAR(200)		--specific date_part string
				,@ObjectQty_str VARCHAR(200)		--specific data qty string
				,@date_part_type VARCHAR(200)		--check date_part type
				,@ObjectName_type VARCHAR(200)		--check name type
				,@sprdPrefix VARCHAR(1)
			
	SET @date_part_type = '{d},{w},{m},{q},{y}'
	SET @ObjectName_type = '{name},{dep1},{dep2},{dep3},{dep4},{stores_name},{format_type_1},{format_type_2},{city_name}'

	IF (SELECT CHARINDEX('{' + @date_part + '}', @date_part_type)) != 0 
		AND (SELECT CHARINDEX('{' + @ObjectName + '}', @ObjectName_type)) != 0
	BEGIN
	
		SET @sprdPrefix =
			CASE 
				WHEN @date_part = 'w' THEN 'W'
				WHEN @date_part = 'm' THEN 'M'
				WHEN @date_part = 'q' THEN 'Q'
				WHEN @date_part = 'y' THEN 'Y'
			END

		SET @date_part_str =
			CASE 
				WHEN @date_part = 'd' 
					THEN 'CONVERT(varchar,CONVERT(date,date))'
				WHEN @date_part = 'w' 
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,date)),''' + @sprdPrefix + 
						''',IIF(LEN(CONVERT(varchar,DATEPART(ww,CONVERT(date,date)))) = 1,''0'','''') + CONVERT(varchar,DATEPART(ww,CONVERT(date,date))))'
				WHEN @date_part = 'm'
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,date)),''' + @sprdPrefix + 
						''',IIF(LEN(CONVERT(varchar,DATEPART(mm,CONVERT(date,date)))) = 1,''0'','''') + CONVERT(varchar,DATEPART(m,CONVERT(date,date))))'
				WHEN @date_part = 'q' 
					THEN 'CONCAT_WS(''-'',CONVERT(varchar,DATEPART(yyyy,date)),''' + @sprdPrefix + ''',CONVERT(varchar,DATEPART(q,CONVERT(date,date))))'
				WHEN @date_part = 'y' 
					THEN 'CONCAT_WS(''-'',''' + @sprdPrefix + ''',CONVERT(varchar,DATEPART(yyyy,CONVERT(date,date))))'
			END

		SET @ObjectName_str = 
			CASE 
				WHEN @ObjectName = 'name' 
					THEN 'TRIM(a.[product_name])'
				WHEN @ObjectName = 'dep1' 
					THEN 'TRIM(a.[DIV_name])'
				WHEN @ObjectName = 'dep2' 
					THEN 'CONCAT_WS(''_'',TRIM(a.[DIV_name]),TRIM(a.[DEP_name]))'
				WHEN @ObjectName = 'dep3' 
					THEN 'CONCAT_WS(''_'',TRIM(a.[DIV_name]),TRIM(a.[DEP_name]),TRIM(a.[SEC_name]))'
				WHEN @ObjectName = 'dep4' 
					THEN 'CONCAT_WS(''_'',TRIM(a.[DIV_name]),TRIM(a.[DEP_name]),TRIM(a.[SEC_name]),TRIM(a.[GRP_name]))'
				WHEN @ObjectName = 'stores_name'
					THEN 'TRIM(a.[stores_name])'
				WHEN @ObjectName = 'format_type_1'
					THEN 'TRIM(a.[format_type_1])'
				WHEN @ObjectName = 'format_type_2'
					THEN 'TRIM(a.[format_type_2])'
				WHEN @ObjectName = 'city_name'
					THEN 'TRIM(a.[city_name_ascii])'
			END

		--comma separated list of attributes for a product
		;WITH dsitSpreadElList AS
		(
			SELECT 
				DISTINCT 
				CASE 
					WHEN @date_part = 'd' 
						THEN CONCAT_WS('-',@sprdPrefix,CONVERT(varchar,CONVERT(date,date)))
					WHEN @date_part = 'w' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,date)),@sprdPrefix,IIF(LEN(CONVERT(varchar,DATEPART(ww,CONVERT(date,date)))) = 1,'0','') + CONVERT(varchar,DATEPART(ww,CONVERT(date,date))))
					WHEN @date_part = 'm' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,date)),@sprdPrefix,IIF(LEN(CONVERT(varchar,DATEPART(mm,CONVERT(date,date)))) = 1,'0','') + CONVERT(varchar,DATEPART(mm,CONVERT(date,date))))
					WHEN @date_part = 'q' 
						THEN CONCAT_WS('-',CONVERT(varchar,DATEPART(yyyy,date)),@sprdPrefix,CONVERT(varchar,DATEPART(q,CONVERT(date,date))))
					WHEN @date_part = 'y' 
						THEN CONCAT_WS('-',@sprdPrefix,CONVERT(varchar,DATEPART(yyyy,CONVERT(date,date))))
				END "Attribute"
			FROM [application].[fn_GetDateRange_To_Table] (@date_start,@date_end)
		)


		SELECT @sprdElements = STRING_AGG('[' + CONVERT(varchar,Attribute) + ']',',') 
			WITHIN GROUP (ORDER BY Attribute ASC)
		FROM dsitSpreadElList;
	
		PRINT @sprdElements
		
		SET @tSql =N';WITH range_CTE AS
			(
				SELECT 
					c.*,
					b.*
				FROM [availability].[product_range] AS a
				INNER JOIN [production].[vw_Product_Info] AS b
					ON a.[product_id] = b.[product_id]
				INNER JOIN [sales].[vw_Stores_Info] AS c
					ON a.[stores_id] = c.[stores_id]
				WHERE a.[range] = ''R''
			)
			,
			range_gap_CTE AS
			(
				SELECT 
					a.[date],
					b.*
				FROM [application].[fn_GetDateRange_To_Table] (''' + CONVERT(varchar,@date_start) + ''',''' + 
					CONVERT(varchar,@date_end) + ''') AS a, range_CTE As b
			)
			,
			TabExp_CTE AS
			(
				SELECT 
					t1.ObjectName,
					t1.Attribute,
					ROUND(100 - SUM(CAST(t1.gap AS decimal(4,2)))/COUNT(t1.ObjectName) * 100,2) AS "Value"
				FROM
				(
				SELECT '
					+ @ObjectName_str + ' AS "ObjectName",'
					+ @date_part_str + ' AS "Attribute",
					b.gap
				FROM range_gap_CTE AS a
				LEFT JOIN [availability].[scanned_gap] AS b
					ON a.[date] = b.[scanned_date] AND a.[stores_id] = b.[stores_id] AND a.[product_id] = b.[product_id]
				) AS t1
				GROUP BY t1.ObjectName,t1.Attribute
			)
	
			SELECT ObjectName,' + @sprdElements + N'
			FROM TabExp_CTE
			PIVOT (
					SUM([Value])
					FOR Attribute IN (' + @sprdElements + N') 
					) AS pvt
			ORDER BY "ObjectName"';
		
		PRINT @tSql

		BEGIN TRY
			EXEC sys.sp_executesql @stmt = @tSql
			RETURN 0
		END TRY
		BEGIN CATCH
			PRINT 'Select failed!'
			PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
			PRINT 'Error message: ' + ERROR_MESSAGE()
			
			RETURN 1
		END CATCH
	END
GO