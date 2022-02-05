/*********************************************************************************************
	Load data - START
**********************************************************************************************/

SET NOCOUNT ON

USE [DiscontStores]
GO

DELETE FROM [availability].[product_range]
DELETE FROM [availability].[scanned_gap]
DELETE FROM [production].[product_price]
DELETE FROM [sales].[sales_detail]
DELETE FROM [sales].[sales_header]
DELETE FROM [sales].[stores]
DELETE FROM [location].[city]
DELETE FROM [location].[country]
DELETE FROM [production].[product]
DELETE FROM [production].[product_supplier]
DELETE FROM [production].[product_brand]
DELETE FROM [production].[product_category_GRP]
DELETE FROM [production].[product_category_SEC]
DELETE FROM [production].[product_category_DEP]
DELETE FROM [production].[product_category_DIV]
DELETE FROM [sales].[stores_format]
GO

DECLARE @path_import VARCHAR(150) = 'c:\Users\gyozo\Work\git-clone\dbspec-masterpiece-general-gyozofodor\'

DECLARE @path_file VARCHAR(150) = ''
	,@path_full VARCHAR(150) = ''
	,@bulk_cmd VARCHAR(1000) = ''
	,@bulk_wth VARCHAR(1000) = ''
	,@table_name VARCHAR(50) = ''
	,@Counter INT
	,@MaxId INT

DECLARE @table_description TABLE
	(
	id INT IDENTITY(1,1),
	table_name VARCHAR(75),
	file_name VARCHAR(75),
	loading BIT
	)

INSERT @table_description VALUES('[location].[country]','data_place_country.csv',1)
INSERT @table_description VALUES('[location].[city]','data_place_city.csv',1)
INSERT @table_description VALUES('[production].[product_supplier]','data_product_supplier.csv',1)
INSERT @table_description VALUES('[production].[product_brand]','data_product_brand.csv',1)
INSERT @table_description VALUES('[production].[product_category_DIV]','data_product_category_DIV.csv',1)
INSERT @table_description VALUES('[production].[product_category_DEP]','data_product_category_DEP.csv',1)
INSERT @table_description VALUES('[production].[product_category_SEC]','data_product_category_SEC.csv',1)
INSERT @table_description VALUES('[production].[product_category_GRP]','data_product_category_GRP.csv',1)
INSERT @table_description VALUES('[production].[product]','data_product.csv',1)
INSERT @table_description VALUES('[production].[product_price]','data_product_price.csv',1)
INSERT @table_description VALUES('[sales].[stores_format]','data_stores_format.csv',1)
INSERT @table_description VALUES('[sales].[stores]','data_stores.csv',1)
INSERT @table_description VALUES('[availability].[product_range]','data_product_range.csv',1)
INSERT @table_description VALUES('[sales].[sales_header]','data_sales_header_Y2021Q1.csv',1)
INSERT @table_description VALUES('[sales].[sales_header]','data_sales_header_Y2021Q2.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M01.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M02.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M03.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M04.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M05.csv',1)
INSERT @table_description VALUES('[sales].[sales_detail]','data_sales_detail_Y2021M06.csv',1)
INSERT @table_description VALUES('[availability].[scanned_gap]','data_scanned_gap_Y2021Q1.csv',1)
INSERT @table_description VALUES('[availability].[scanned_gap]','data_scanned_gap_Y2021Q2.csv',1)

SET @bulk_wth = 'WITH (
		CODEPAGE = 65001,
		FIRSTROW = 2,
		DATAFILETYPE=''CHAR'',
		FORMAT = ''CSV'',
		FIELDTERMINATOR= '';'',
		ROWTERMINATOR = ''\n'',
		KEEPIDENTITY,
		TABLOCK
	)'

PRINT ''
PRINT '*** Loading Data ****'

BEGIN TRY
	SELECT 
		@Counter = min(Id),
		@MaxId = max(Id) 
	FROM @table_description
	WHERE loading = 1

	WHILE(@Counter <= @MaxId)
	BEGIN
		SELECT 
			@table_name = table_name,
			@path_file = file_name
		FROM @table_description
		WHERE Id = @Counter
		
		PRINT ''
		PRINT CONVERT(VARCHAR,@Counter) + '. Table name is ' + UPPER(@table_name)
		PRINT '	' +  UPPER(@table_name) + ' Table: loading..'

		SET @path_full = @path_import + 'Import\' + @path_file
		SET @bulk_cmd = 'BULK INSERT ' + @table_name + ' FROM ''' + @path_full + ''' ' + @bulk_wth

		EXEC(@bulk_cmd)

		PRINT '	' + UPPER(@table_name) + ' Table: (' + CAST(@@ROWCOUNT AS varchar) + ') rows affected.'
		
		SET @Counter  = @Counter  + 1        
	END
END TRY
BEGIN CATCH
	PRINT 'Insert failed!'
	PRINT 'Error number: ' + CONVERT(varchar,ERROR_NUMBER())
	PRINT 'Error message: ' + ERROR_MESSAGE()
END CATCH
/*********************************************************************************************
	Load data - END
**********************************************************************************************/