/*
FORMAT: This option used to specify whether to overwrite the media header information. 
    The FORMAT clause will create a new media backup set, whereas NOFORMAT will preserve all the information.

INIT: INIT is used to create a new backup set; NOINIT is used for appending the backup to the existing backup set.
    The NOINIT parameter is used mostly when you backup the database to a tape device.

NAME: The NAME parameter is used to identify the backup set.

SKIP: The skip parameter is used to skip the expiration check on the backup set.

NOREWIND: This parameter is used to keep a tape device open and ready for use

NOUNLOAD: This parameter is used to instruct SQL Server to not unload the tape from the drive upon completion of the backup operation.

STATS: The STATS option is useful to get the status of the backup operation at regular stages of its progress.
*/

-- FULL RECOVERY MODEL
-- create full database backup using T-SQL
BACKUP DATABASE [DiscontStores] 
	TO  DISK = N'DiscontStores.bak' 
	WITH RETAINDAYS = 14, NOFORMAT, NOINIT,  NAME = N'DiscontStores-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- create Differential database backup using T-SQL
BACKUP DATABASE [DiscontStores] 
	TO  DISK = N'DiscontStores.bak' 
	WITH  DIFFERENTIAL , RETAINDAYS = 7, NOFORMAT, NOINIT,  NAME = N'DiscontStores-Diff Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- create Transactional log backup using T-SQL
BACKUP LOG [DiscontStores] 
	TO  DISK = N'DiscontStores.bak' 
	WITH NOFORMAT, NOINIT,  NAME = N'DiscontStores-Log Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO





