USE [DiscontStores]
GO

DROP USER IF EXISTS DiStor_User_all
DROP USER IF EXISTS DiStor_User_read
DROP USER IF EXISTS DiStor_User_write
DROP USER IF EXISTS DiStor_User_app
DROP USER IF EXISTS DiStor_User_exec

CREATE ROLE db_executor
GRANT EXECUTE TO db_executor

-- DiStor_User_all
IF Exists (SELECT loginname FROM master.dbo.syslogins WHERE name = 'DiStor_User_all' and dbname = 'DiscontStores')
BEGIN
	DROP LOGIN DiStor_User_all;  
END

CREATE LOGIN DiStor_User_all WITH PASSWORD = '123', DEFAULT_DATABASE=[DiscontStores], DEFAULT_LANGUAGE=[us_english]
CREATE USER DiStor_User_all FOR LOGIN DiStor_User_all WITH DEFAULT_SCHEMA = [production]
ALTER ROLE db_datareader ADD MEMBER DiStor_User_all
ALTER ROLE db_datawriter ADD MEMBER DiStor_User_all
ALTER ROLE db_executor ADD MEMBER DiStor_User_all

-- DiStor_User_read
IF Exists (SELECT loginname FROM master.dbo.syslogins WHERE name = 'DiStor_User_read' and dbname = 'DiscontStores')
BEGIN
	DROP LOGIN DiStor_User_read;  
END

CREATE LOGIN DiStor_User_read WITH PASSWORD = '123', DEFAULT_DATABASE=[DiscontStores], DEFAULT_LANGUAGE=[us_english]
CREATE USER DiStor_User_read FOR LOGIN DiStor_User_read WITH DEFAULT_SCHEMA = [production]
ALTER ROLE db_datareader ADD MEMBER DiStor_User_read

-- DiStor_User_write
IF Exists (SELECT loginname FROM master.dbo.syslogins WHERE name = 'DiStor_User_write' and dbname = 'DiscontStores')
BEGIN
	DROP LOGIN DiStor_User_write;  
END

CREATE LOGIN DiStor_User_write WITH PASSWORD = '123', DEFAULT_DATABASE=[DiscontStores], DEFAULT_LANGUAGE=[us_english]
CREATE USER DiStor_User_write FOR LOGIN DiStor_User_write WITH DEFAULT_SCHEMA = [sales]
ALTER ROLE db_datawriter ADD MEMBER DiStor_User_write

CREATE LOGIN DiStor_User_exec WITH PASSWORD = '123', DEFAULT_DATABASE=[DiscontStores], DEFAULT_LANGUAGE=[us_english]
CREATE USER DiStor_User_exec FOR LOGIN DiStor_User_exec WITH DEFAULT_SCHEMA = [sales]
ALTER ROLE db_executor ADD MEMBER DiStor_User_exec
ALTER ROLE db_datareader ADD MEMBER DiStor_User_exec

-- DiStor_User_app
CREATE USER DiStor_User_app WITHOUT LOGIN WITH DEFAULT_SCHEMA = [application]
GRANT IMPERSONATE ON USER::DiStor_User_app TO DiStor_User_exec
--GRANT EXECUTE ON [application].[sp_query_sales_datepart] TO [USER DiStor_User_app]  

--ALTER ROLE db_executor ADD MEMBER DiStor_User_app