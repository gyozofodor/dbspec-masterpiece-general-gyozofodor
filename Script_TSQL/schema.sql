USE [master]
GO

DROP DATABASE IF EXISTS [DiscontStores]
GO

CREATE DATABASE [DiscontStores]
COLLATE Hungarian_CI_AS
--COLLATE Latin1_General_100_CS_AS_SC;
GO

USE [DiscontStores]
GO

EXEC('CREATE SCHEMA [production]')
EXEC('CREATE SCHEMA [sales]')
EXEC('CREATE SCHEMA [availability]')
EXEC('CREATE SCHEMA [location]')
EXEC('CREATE SCHEMA [log]')
EXEC('CREATE SCHEMA [application]')
GO

-- Table (01): country
CREATE TABLE [location].[country] (
    country_id int NOT NULL IDENTITY(1, 1),
    country_name nvarchar(128) NOT NULL,
    country_code_iso2 char(2) NOT NULL,
    country_code_iso3 char(3) NOT NULL,
    currency varchar(128),
    currency_code_iso char(3),
    CONSTRAINT AK_country_name UNIQUE (country_name),
    CONSTRAINT AK_country_code_2 UNIQUE (country_code_iso2),
    CONSTRAINT PK_country_id PRIMARY KEY (country_id)
)
GO

-- Table (02): city
CREATE TABLE [location].[city] (
    city_id smallint NOT NULL IDENTITY(1, 1),
    city_name nvarchar(128) NOT NULL,
    city_name_ascii nvarchar(128) NOT NULL,
    lat decimal(9,6) NOT NULL,
    long decimal(9,6) NOT NULL,
    population_number bigint, 
    country_id int NOT NULL,
    CONSTRAINT PK_city_id PRIMARY KEY (city_id),
    CONSTRAINT FK_city_country__country_id FOREIGN KEY (country_id) REFERENCES [location].[country] (country_id)
)

-- Table (03): supplier
CREATE TABLE [production].[product_supplier] (
    supplier_id smallint NOT NULL IDENTITY(1, 1),
    supplier_name nvarchar(128) NOT NULL,
    CONSTRAINT AK_supplier_name UNIQUE (supplier_name),
    CONSTRAINT PK_supplier_id PRIMARY KEY (supplier_id)
)

-- Table (04): brand
CREATE TABLE [production].[product_brand] (
    brand_id smallint NOT NULL IDENTITY(1, 1),
    brand_name nvarchar(128) NOT NULL,
    supplier_id smallint NOT NULL,
    CONSTRAINT AK_brand_name UNIQUE (brand_name),
    CONSTRAINT PK_brand_id PRIMARY KEY (brand_id)
)

-- Table (05): product_category
CREATE TABLE [production].[product_category_DIV] (
    DIV smallint NOT NULL,
    DIV_name nvarchar(100)  NOT NULL,
    CONSTRAINT PK_DIV PRIMARY KEY (DIV),
    CONSTRAINT AK_DIV_name UNIQUE (DIV_name)
)

-- Table (06): product_category
CREATE TABLE [production].[product_category_DEP] (
    DIV smallint NOT NULL,
    DEP smallint NOT NULL,
    DEP_name nvarchar(100)  NOT NULL,
    CONSTRAINT PK_DEP PRIMARY KEY (DEP),
    CONSTRAINT AK_DEP_name UNIQUE (DEP_name),
    CONSTRAINT FK_pr_cat_DEP__pr_cat_DIV__DIV FOREIGN KEY (DIV) REFERENCES [production].[product_category_DIV] (DIV)
)

-- Table (07): product_category
CREATE TABLE [production].[product_category_SEC] (
    DEP smallint NOT NULL,
    SEC smallint NOT NULL,
    SEC_name nvarchar(100)  NOT NULL,
    CONSTRAINT PK_SEC PRIMARY KEY (SEC),
    CONSTRAINT AK_SEC_name UNIQUE (SEC_name),
    CONSTRAINT FK_pr_cat_SEC__pr_cat_DEP__DEP FOREIGN KEY (DEP) REFERENCES [production].[product_category_DEP] (DEP)
)

-- Table (08): product_category
CREATE TABLE [production].[product_category_GRP] (
    SEC smallint NOT NULL,
    GRP smallint NOT NULL,
    GRP_name nvarchar(100)  NOT NULL,
    CONSTRAINT PK_GRP PRIMARY KEY (GRP),
    CONSTRAINT AK_GRP_name UNIQUE (GRP_name),
    CONSTRAINT FK_pr_cat_GRP__pr_cat_SEC__SEC FOREIGN KEY (SEC) REFERENCES [production].[product_category_SEC] (SEC)
)

-- Table (09): product
CREATE TABLE [production].[product] (
    product_id int NOT NULL IDENTITY(300000, 1),
    product_name nvarchar(128)  NOT NULL,
    GRP smallint NOT NULL,
    brand_id smallint NOT NULL,
    supplier_id smallint NOT NULL,
    CONSTRAINT PK_product_id PRIMARY KEY (product_id),
    CONSTRAINT AK_product_name UNIQUE (product_name),
    CONSTRAINT FK_product__product_supplier__supplier_id FOREIGN KEY (supplier_id) REFERENCES [production].[product_supplier] (supplier_id),
    CONSTRAINT FK_product__product_brand__brand_id FOREIGN KEY (brand_id) REFERENCES [production].[product_brand] (brand_id),
    CONSTRAINT FK_prpduct__product_category__GRP FOREIGN KEY (GRP) REFERENCES [production].[product_category_GRP] (GRP)
)

-- Table (10): price
CREATE TABLE [production].[product_price] (
    product_id int NOT NULL,
    country_id int NOT NULL,
    price decimal(9,2) NOT NULL,
    CONSTRAINT PK_product_country PRIMARY KEY (product_id,country_id),
    CONSTRAINT FK_product_price__product__product_id FOREIGN KEY (product_id) REFERENCES [production].[product] (product_id),
    CONSTRAINT FK_product_price__country__country_id FOREIGN KEY (country_id) REFERENCES [location].[country] (country_id)
)

-- Table (11): stores_format
CREATE TABLE [sales].[stores_format] (
    format_id tinyint NOT NULL IDENTITY(1, 1),
    format_type_1 varchar(20) NOT NULL,
    format_type_2 varchar(20) NOT NULL,
    CONSTRAINT AK_format_type_2 UNIQUE (format_type_1),
    CONSTRAINT CHK_format_type_2 CHECK (format_type_2 IN('SM','MM','HM')),
    CONSTRAINT PK_format_id PRIMARY KEY (format_id)
)

-- Table (12): stores
CREATE TABLE [sales].[stores] (
    stores_id smallint NOT NULL IDENTITY(10000, 1),
    stores_name nvarchar(128) NOT NULL,
    format_id tinyint NOT NULL,
    city_id smallint NOT NULL,
    CONSTRAINT PK_stores_id PRIMARY KEY (stores_id),
    CONSTRAINT FK_stores__stores_format__format_id FOREIGN KEY (format_id) REFERENCES [sales].[stores_format] (format_id),
    CONSTRAINT FK_stores__city__city_id FOREIGN KEY (city_id) REFERENCES [location].[city] (city_id)
)

-- Table (13): range
CREATE TABLE [availability].[product_range] (
    stores_id smallint NOT NULL,
    product_id int NOT NULL,
    [range] char(1) NOT NULL DEFAULT 'R',
    CONSTRAINT CHK_range CHECK ([range] IN('R','D')),
    CONSTRAINT PK_stores_product PRIMARY KEY (stores_id,product_id),
    CONSTRAINT FK_product_range__product__product_id FOREIGN KEY (product_id) REFERENCES [production].[product] (product_id),
    CONSTRAINT FK_product_range__stores__stores_id FOREIGN KEY (stores_id) REFERENCES [sales].[stores] (stores_id)
)

-- Table (14): scanned_gap
CREATE TABLE [availability].[scanned_gap] (
    scanned_date date NOT NULL,
    stores_id smallint NOT NULL,
    product_id int NOT NULL,
    gap bit NOT NULL DEFAULT '1',
    modified_date datetime2 CONSTRAINT DF_sg_modified_date_timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_date_stores_product PRIMARY KEY (scanned_date,stores_id,product_id),
    CONSTRAINT FK_scanned_gap__product__product_id FOREIGN KEY (product_id) REFERENCES [production].[product] (product_id),
    CONSTRAINT FK_scanned_gap__stores__stores_id FOREIGN KEY (stores_id) REFERENCES [sales].[stores] (stores_id)
)

-- Table (15): sales_header
CREATE TABLE [sales].[sales_header] (
    sales_id bigint NOT NULL IDENTITY(1, 1),
    stores_id smallint NOT NULL,
    sales_date date NOT NULL,
    sub_total money NOT NULL,
    modified_date datetime2 CONSTRAINT DF_sh_modified_date_timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_sales_id PRIMARY KEY (sales_id),
    CONSTRAINT FK_sales_header__stores__stores_id FOREIGN KEY (stores_id) REFERENCES [sales].[stores] (stores_id)
)

-- Table (16): sales_detail
    CREATE TABLE [sales].[sales_detail] (
    detail_id bigint NOT NULL IDENTITY(1, 1),
    sales_id bigint NOT NULL,
    product_id int NOT NULL,
    unit smallint NOT NULL,
    unit_price smallmoney NOT NULL,
    unit_price_discount smallmoney NOT NULL DEFAULT 0,
    sales_value AS (isnull((unit_price*((1.0)-unit_price_discount))*[unit],(0.0))),
    modified_date datetime2 CONSTRAINT DF_sd_modified_date_timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CHK_discount CHECK ([unit_price_discount] >= 0 AND [unit_price_discount] <= [unit_price]),
    CONSTRAINT PK_detail_id PRIMARY KEY (detail_id),
    CONSTRAINT FK_sales_d__sales_h__sales_id FOREIGN KEY (sales_id) REFERENCES [sales].[sales_header] (sales_id),
    CONSTRAINT FK_sales_d__product__product_id FOREIGN KEY (product_id) REFERENCES [production].[product] (product_id)
)

CREATE TABLE AuditLog
(
    Auditlog_id bigint NOT NULL IDENTITY(1, 1),
    TableName nvarchar(128) NOT NULL,
    OldRowData nvarchar(1000),
    NewRowData nvarchar(1000),
	DmlType varchar(10) NOT NULL,
    DmlTimestamp datetime2 NOT NULL,
    DmlCreatedBy varchar(255) NOT NULL,
    TrxTimestamp datetime2 NOT NULL,
    CONSTRAINT CHK_oldrowdata CHECK(ISJSON(OldRowData) = 1),
    CONSTRAINT CHK_newrowdata CHECK(ISJSON(NewRowData) = 1),
    CONSTRAINT CHK_dmltype CHECK(DmlType IN('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT PK_auditlog_id PRIMARY KEY (Auditlog_id)
) 
GO

IF EXISTS (SELECT name FROM sys.indexes  
            WHERE name = N'IX_Production_ProductNumber_Name')   
    DROP INDEX IX_Product_productID ON [production].[Product];   
GO

CREATE NONCLUSTERED INDEX IX_Production_ProductNumber_Name 
    ON [production].[Product] ([product_name] ASC,[product_id] ASC);
GO

IF EXISTS (SELECT name FROM sys.indexes  
                WHERE name = N'IX_Sales_Header_Date')   
    DROP INDEX IX_Sales_Header_Date ON [sales].[sales_header];   
GO

CREATE NONCLUSTERED INDEX IX_Sales_Header_Date 
    ON [sales].[sales_header] ([sales_date] ASC) INCLUDE([stores_id],[sub_total],[modified_date]);
GO

IF EXISTS (SELECT name FROM sys.indexes  
            WHERE name = N'IX_Sales_Detail_Product')   
    DROP INDEX IX_Sales_Detail_Product ON [sales].[sales_detail];   
GO

CREATE NONCLUSTERED INDEX IX_Sales_Detail_Product 
ON [sales].[sales_detail] ([product_id] ASC);
GO