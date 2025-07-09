DECLARE @MSG VARCHAR(100)
SET @MSG='DBA Process Start....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

--Get Database Name
DECLARE @NAME VARCHAR(50) =(SELECT DB_NAME() ) --Change Value for database
DECLARE @COMPATIBILITY_LEVEL VARCHAR(10) = 140
-- Inserting Database Name to Global Temp Table
DROP TABLE IF EXISTS ##TEMP
CREATE TABLE ##TEMP(DBNAME VARCHAR(50), COMPATIBILITY VARCHAR(10))
INSERT INTO ##TEMP(DBNAME, COMPATIBILITY) VALUES (@NAME, @COMPATIBILITY_LEVEL)

--DBCC CHECKDB
SET @MSG='DBCC CHECKDB('+@NAME+')....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
DBCC CHECKDB (@NAME) WITH NO_INFOMSGS

SET @MSG='DBCC CHECKDB('+@NAME+').... Process Completed....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--===========================================================================================

--Change Recovery Model to Simple Of Database
USE [master]
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Changing Recovery Model to SIMPLE....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'ALTER DATABASE '+@NAME+' SET RECOVERY SIMPLE WITH NO_WAIT'
EXEC (@SQL)

SET @MSG='Recovery Model Changed to SIMPLE....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--=============================================================================================

----Rebuild All Indexes in Database
--DECLARE @MSG VARCHAR(100)
--SET @MSG='Rebuilding All Indexes in Database....'+CONVERT(varchar(50),GETDATE(),113)
--RAISERROR (@MSG,0,1) WITH NOWAIT

--DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
--DECLARE @SQL VARCHAR(8000) = '	USE ['+@NAME+']
--								DECLARE @TableName VARCHAR(255)
--								DECLARE @sql NVARCHAR(500)
--								DECLARE @fillfactor INT
--								SET @fillfactor = 90 
--								DECLARE TableCursor CURSOR FOR
--								SELECT QUOTENAME(OBJECT_SCHEMA_NAME([object_id]))+''.'' + QUOTENAME(name) AS TableName
--								FROM sys.tables
--								OPEN TableCursor
--								FETCH NEXT FROM TableCursor INTO @TableName
--								WHILE @@FETCH_STATUS = 0
--								BEGIN
--								SET @sql = ''ALTER INDEX ALL ON '' + @TableName + '' REBUILD WITH (FILLFACTOR = '' + CONVERT(VARCHAR(3),@fillfactor) + '')''
--								EXEC (@sql)
--								FETCH NEXT FROM TableCursor INTO @TableName
--								END
--								CLOSE TableCursor
--								DEALLOCATE TableCursor
--							'
--EXEC (@SQL)

--SET @MSG='Rebuilding All Indexes Finished....'+CONVERT(varchar(50),GETDATE(),113)
--RAISERROR (@MSG,0,1) WITH NOWAIT
--GO

--==============================================================================================

-- Create Missing Indexes in Database
DECLARE @MSG VARCHAR(100)
SET @MSG='Begining Create Missing Index Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'USE ['+@NAME+']'+'EXEC USP_INDEX_CREATE_MISSING 1'
EXEC (@SQL)

SET @MSG='Finished Missing Index Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--==============================================================================================

-- Execute defragDB 
DECLARE @MSG VARCHAR(100)
SET @MSG='Begining Degrag DB Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'USE ['+@NAME+']'+'EXEC usp_defrag_db'
EXEC (@SQL)

SET @MSG='Finished Degrag DB Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--===============================================================================================

-- Execute updatestats
DECLARE @MSG VARCHAR(100)
SET @MSG='Begining sp_updatestats process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'USE ['+@NAME+'] EXEC sp_updatestats'
EXEC (@SQL)

SET @MSG='Completed sp_updatestats process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--===============================================================================================

--Change Recovery Model to Full Of Database
USE [master]
GO
DECLARE @MSG VARCHAR(100)
SET @MSG='Changing Recovery Model to FULL....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'ALTER DATABASE '+@NAME+' SET RECOVERY FULL WITH NO_WAIT'
EXEC (@SQL)

SET @MSG='Recovery Model Changed to FULL....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--=================================================================================================

--Changing Database Compatibility level
USE [master]
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Changing Compatibility Level....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

DECLARE @NAME VARCHAR(50)= (SELECT DBNAME FROM ##TEMP)
DECLARE @COMPATIBILITY_LEVEL VARCHAR(10) = (SELECT COMPATIBILITY FROM ##TEMP)
DECLARE @SQL VARCHAR(5000)= 'ALTER DATABASE '+@NAME+' SET COMPATIBILITY_LEVEL = '+@COMPATIBILITY_LEVEL
EXEC (@SQL)

SET @MSG='Compatibility Level Changed....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

GO
--=================================================================================================