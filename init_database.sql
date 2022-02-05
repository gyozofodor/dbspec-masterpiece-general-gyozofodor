sp_configure 'xp_cmdshell', 1
RECONFIGURE
GO

USE [master]
GO

SET NOCOUNT ON

DECLARE @cmd varchar(1000)
    ,@path_script VARCHAR(200) = 'c:\Users\gyozo\Work\git-clone\dbspec-masterpiece-general-gyozofodor\'
    ,@result int

DECLARE @script_id INT
    ,@script_name VARCHAR(50)
    ,@file_name VARCHAR(50)
    ,@message VARCHAR(1000)

DECLARE @script_description TABLE
	(
	id INT IDENTITY(1,1),
	script_name VARCHAR(50),
	file_name VARCHAR(50),
	message VARCHAR(1000),
	xp_execute BIT
	)

INSERT @script_description VALUES('schema','schema.sql','Create database schema.',1)
INSERT @script_description VALUES('data','data.sql','Load data in database.',1)
INSERT @script_description VALUES('programmability','programmability.sql','Create stored procedure and functional.',1)
INSERT @script_description VALUES('trigger','trigger.sql','Create DML trigger.',1)
INSERT @script_description VALUES('view','view.sql','Create view.',1)
INSERT @script_description VALUES('security','security.sql','Create security.',1)
INSERT @script_description VALUES('backup','backup_job.sql','Setting backup.',1)

/*
osql - arguments
    -E  Uses a trusted connection instead of requesting a password.
    -S  server_name[ \instance_name]
        Specifies the instance of SQL Server to connect to. Specify server_name to connect to the default 
        instance of SQL Server on that server. Specify server_name\instance_name to connect to a named 
        instance of SQL Server on that server. If no server is specified, osql connects to the default 
        instance of SQL Server on the local computer. This option is required when executing osql from a remote
        computer on the network.
    -d db_name
        Issues a USE db_name statement when osqlis started.
    -i input_file
        Identifies the file that contains a batch of SQL statements or stored procedures. 
        The less than (<) comparison operator can be used in place of -i.
    -U login_id
        Is the user login ID. Login IDs are case-sensitive.
    -P password
        Is a user-specified password. If the -P option is not used, osql prompts for a password.
        If the -P option is used at the end of the command prompt without any password, osql uses the default password (NULL).
*/

-- **************************************************************************************************************
-- EXECUTE T-SQL SCRIPT - START
-- **************************************************************************************************************

DECLARE script_cursor CURSOR FOR   
    SELECT 
		id,
		script_name, 
		file_name, 
		message
    FROM @script_description 
	WHERE xp_execute = 1
    ORDER BY id

OPEN script_cursor

FETCH NEXT FROM script_cursor   
INTO @script_id, @script_name, @file_name, @message

WHILE @@FETCH_STATUS = 0  
BEGIN  
    PRINT ' '  
    SELECT @message = 'Start executing script --- ' + UPPER(@script_name)
    
    SET @cmd = 'osql -E -i ' + @path_script + 'Script_TSQL\' + @file_name
	
	PRINT @message

    EXEC @result =  master..xp_cmdshell @cmd, no_output

    IF (@result = 0)  
        PRINT '		Success.'  
    ELSE  
        PRINT '		Failure.'

    FETCH NEXT FROM script_cursor   
    INTO @script_id, @script_name, @file_name, @message
END

CLOSE script_cursor;  
DEALLOCATE script_cursor;  

-- **************************************************************************************************************
-- EXECUTE T-SQL SCRIPT - END
-- **************************************************************************************************************