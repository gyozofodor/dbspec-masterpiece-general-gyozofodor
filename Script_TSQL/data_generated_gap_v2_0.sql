USE [DiscontStores]
GO
	
SET NOCOUNT ON

DECLARE @gap_counter INT
	,@stores_id SMALLINT
	,@product_min SMALLINT
	,@product_max SMALLINT
	,@s_date DATE
	,@s_date_start DATE
	,@s_date_end DATE
	
SET @s_date_start = '2021.01.01'
SET @s_date_end = '2021.06.30'
SET @s_date = @s_date_start

DECLARE @product_table TABLE (
		rw_number INT
	)

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
		SET @gap_counter = 1
		DELETE FROM @product_table
		
		SELECT 
			@product_min = MIN(1),
			@product_max = COUNT([product_id])
		FROM [availability].[product_range] AS a
		WHERE a.[range] = 'R'
			AND a.[stores_id] = @stores_id

		WHILE(@gap_counter <= [application].fn_GetRandomDefault(ROUND(@product_max * 0.085,0),ROUND(@product_max * 0.15,0)))
		BEGIN
			INSERT INTO @product_table(rw_number) VALUES([application].fn_GetRandomDefault(@product_min,@product_max))

			SET @gap_counter = @gap_counter + 1
		END
		
		;WITH range_CTE
		AS
		(
			SELECT 
				ROW_NUMBER() over(partition by a.[stores_id] order by a.[stores_id],a.[product_id]) As rw_number,
				a.[stores_id],
				a.[product_id]
			FROM [availability].[product_range] AS a
			WHERE a.[range] = 'R'
				AND a.[stores_id] = @stores_id
		)
		,
		product_CTE
		AS
		(
			SELECT DISTINCT rw_number FROM @product_table
		)

		INSERT INTO [availability].[scanned_gap] ([scanned_date],[stores_id],[product_id])
			SELECT 
				@s_date AS "scanned_date",
				a.[stores_id],
				a.[product_id]
			FROM range_CTE AS a
			INNER JOIN product_CTE  AS b
				ON a.[rw_number] = b.[rw_number]
			ORDER BY a.[stores_id],	a.[product_id]

		FETCH NEXT FROM stores_cursor   
			INTO @stores_id
	END

	CLOSE stores_cursor  
	DEALLOCATE stores_cursor
		
	SET @s_date  = DATEADD(day,1,@s_date)
END