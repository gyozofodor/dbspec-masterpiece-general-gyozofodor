USE [DiscontStores]
GO

CREATE or Alter TRIGGER NoDropTableAllowed
ON DATABASE
    FOR DROP_TABLE
AS
        PRINT 'You must disable trigger ""NoDropTableAllowed"" to drop tables!'
        ROLLBACK
GO

CREATE or ALTER TRIGGER [production].TR_All_AuditLog__product ON [production].[product]
FOR INSERT, UPDATE, DELETE
AS
BEGIN
	
	DECLARE @TableName sysname = application.fn_GetTrigger_TableName(@@PROCID)
		,@DmlType varchar(10)
		,@transactionTimestamp datetime2 = SYSUTCdatetime()
		,@OldRowData NVARCHAR(max) = NULL
		,@NewRowData NVARCHAR(max) = NULL

	SET @DmlType = 
		CASE
			WHEN (SELECT COUNT(*) FROM deleted) = 0 THEN 'INSERT'
			WHEN (SELECT COUNT(*) FROM inserted) <> 0 AND (SELECT COUNT(*) FROM deleted) <> 0 THEN 'UPDATE'
			ELSE 'DELETE'
		END
	
	SET @OldRowData =
		CASE
			WHEN @DmlType = 'INSERT' THEN NULL
			ELSE (SELECT * FROM Deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
		END

	SET @NewRowData =
		CASE
			WHEN @DmlType IN('INSERT','UPDATE') THEN (SELECT * FROM Inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			ELSE NULL
		END

	INSERT INTO AuditLog (TableName, OldRowData, NewRowData, DmlType, DmlTimestamp, DmlCreatedBy, TrxTimestamp)
		VALUES(@TableName, @OldRowData, @NewRowData, @DmlType, CURRENT_TIMESTAMP, application.fn_GetLogin_Name(@@SPID),
        @transactionTimestamp)
END
GO

CREATE or ALTER TRIGGER [production].TR_All_AuditLog__product_price ON [production].[product_price]
FOR INSERT, UPDATE, DELETE
AS
BEGIN
	
	DECLARE @TableName sysname = application.fn_GetTrigger_TableName(@@PROCID)
		,@DmlType varchar(10)
		,@transactionTimestamp datetime2 = SYSUTCdatetime()
		,@OldRowData NVARCHAR(max) = NULL
		,@NewRowData NVARCHAR(max) = NULL

	SET @DmlType = 
		CASE
			WHEN (SELECT COUNT(*) FROM deleted) = 0 THEN 'INSERT'
			WHEN (SELECT COUNT(*) FROM inserted) <> 0 AND (SELECT COUNT(*) FROM deleted) <> 0 THEN 'UPDATE'
			ELSE 'DELETE'
		END
	
	SET @OldRowData =
		CASE
			WHEN @DmlType = 'INSERT' THEN NULL
			ELSE (SELECT * FROM Deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
		END

	SET @NewRowData =
		CASE
			WHEN @DmlType IN('INSERT','UPDATE') THEN (SELECT * FROM Inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			ELSE NULL
		END

	INSERT INTO AuditLog (TableName, OldRowData, NewRowData, DmlType, DmlTimestamp, DmlCreatedBy, TrxTimestamp)
		VALUES(@TableName, @OldRowData, @NewRowData, @DmlType, CURRENT_TIMESTAMP, application.fn_GetLogin_Name(@@SPID),
        @transactionTimestamp)
END
GO
--ENABLE TRIGGER TR_UPD_Locations2 on Locations
--DISABLE TRIGGER ALL ON Locations

DISABLE TRIGGER NoDropTableAllowed ON DATABASE

--ENABLE TRIGGER track_logins ON ALL SERVER
--sqlcmd –S 127.0.0.1,1434
--DISABLE TRIGGER triggername ON ALL SERVER;