USE [DiscontStores]
GO

DROP VIEW IF EXISTS [application].[vw_GetRANDValue]
DROP VIEW IF EXISTS [production].[vw_GetCategory_4_dep]
DROP VIEW IF EXISTS [production].[vw_Product_Info]
DROP VIEW IF EXISTS [sales].[vw_Stores_Info]
DROP VIEW IF EXISTS [production].[vw_Supplier_Info]
GO

CREATE VIEW [application].[vw_GetRANDValue]
AS
	SELECT RAND() AS Value
GO

CREATE VIEW [production].[vw_GetCategory_4_dep]
AS
	SELECT
		d.[DIV],
		b.[DEP],
		a.[SEC],
		a.[GRP],
		d.[DIV_name],
		c.[DEP_name],
		b.[SEC_name],
		a.[GRP_name]
	FROM [production].[product_category_GRP] AS a
	LEFT JOIN [production].[product_category_SEC] AS b
		ON a.SEC = b.SEC
	LEFT JOIN [production].[product_category_DEP] AS c
		ON b.DEP = c.DEP
	LEFT JOIN [production].[product_category_DIV] AS d
		ON c.DIV = d.DIV
GO

CREATE VIEW [production].[vw_Product_Info]
AS
	SELECT
		a.[product_id],
		a.[product_name],
		e.[DIV_name],
		d.[DEP_name],
		c.[SEC_name],
		b.[GRP_name],
		f.[brand_name],
		g.[supplier_name]
	FROM [production].[product] AS a
	LEFT JOIN [production].[product_category_GRP] AS b
		ON a.GRP = b.GRP
	LEFT JOIN [production].[product_category_SEC] AS c
		ON b.SEC = c.SEC
	LEFT JOIN [production].[product_category_DEP] AS d
		ON c.DEP = d.DEP
	LEFT JOIN [production].[product_category_DIV] AS e
		ON d.DIV = e.DIV
	LEFT JOIN [production].[product_brand] AS f
		ON a.[brand_id] = f.[brand_id]
	LEFT JOIN [production].[product_supplier] AS g
		ON a.[supplier_id] = g.[supplier_id]
GO

CREATE VIEW [sales].[vw_Stores_Info]
AS
	SELECT
		a.[stores_id],
		a.[stores_name],
		b.[format_type_1],
		b.[format_type_2],
		c.[city_name_ascii],
		d.[country_name],
		d.[country_code_iso2],
		d.[country_code_iso3]
	FROM [sales].[stores] AS a
	LEFT JOIN [sales].[stores_format] AS b
		ON a.[format_id] = b.[format_id]
	LEFT JOIN [location].[city] AS c
		ON a.[city_id] = c.[city_id]
	LEFT JOIN [location].[country] AS d
		ON c.[country_id] = d.[country_id]
GO

CREATE VIEW [production].[vw_Supplier_Info]
AS
	SELECT 
		t1.*,
		COUNT(*) AS "number_of_product"		
	FROM (
	SELECT
		a.[supplier_id],
		a.[supplier_name],
		STRING_AGG(TRIM(CONVERT(nvarchar(max),b.[brand_name])),' -- ') AS "brands"
	FROM [production].[product_supplier] AS a
	LEFT JOIN [production].[product_brand] AS b
		ON a.[supplier_id] = b.[supplier_id]
	GROUP BY a.[supplier_id],
		a.[supplier_name]
	) AS t1
	LEFT JOIN [production].[product] AS t2
		ON t1.[supplier_id] = t2.[supplier_id]	
	GROUP BY t1.[supplier_id], t1.[supplier_name], t1.[brands]
GO