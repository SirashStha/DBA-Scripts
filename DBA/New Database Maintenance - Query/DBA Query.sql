DECLARE @MSG VARCHAR(100)
SET @MSG='DBA Process Start....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

--Get Database Name
DECLARE @NAME VARCHAR(50) =(SELECT DB_NAME() )

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

ALTER DATABASE INFINITY_NI_97		--Change Database Name
SET RECOVERY SIMPLE 

SET @MSG='Recovery Model Changed to SIMPLE....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO

--==============================================================================================

-- Create Missing Indexes in Database
USE [INFINITY_NI_97]				--Change Database Name
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Begining Create Missing Index Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

EXEC USP_INDEX_CREATE_MISSING 1

SET @MSG='Finished Missing Index Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--=============================================================================================

--Rebuild All Indexes in Database
USE [INFINITY_NI_97]				--Change Database Name
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Rebuilding All Indexes in Database....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT


BEGIN TRY   

DECLARE @TABLE NVARCHAR(MAX)
,@CMD NVARCHAR(MAX)
,@DATABASE NVARCHAR(MAX)

SET @DATABASE=DB_NAME() 

SET @CMD = 'DECLARE TABLECURSOR CURSOR READ_ONLY FOR SELECT ''['' + TABLE_CATALOG + ''].['' + TABLE_SCHEMA + ''].[''+TABLE_NAME+'']'' AS TABLENAME FROM [' + @DATABASE + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = ''BASE TABLE'' ORDER BY ''['' + TABLE_CATALOG + ''].['' + TABLE_SCHEMA + ''].[''+TABLE_NAME+'']'''
EXEC (@CMD)OPEN TABLECURSOR   

FETCH NEXT FROM TABLECURSOR INTO @TABLE 
WHILE @@FETCH_STATUS = 0 
BEGIN
	SET @CMD ='ALTER INDEX ALL ON ' + @TABLE + ' REORGANIZE'
	SET @MSG=N''+@CMD+' TIME '+CONVERT(VARCHAR(50),GETDATE(),113); RAISERROR(@MSG, 0, 1) WITH NOWAIT;
	EXEC (@CMD)

    FETCH NEXT FROM TABLECURSOR INTO @TABLE
END
CLOSE TABLECURSOR   
DEALLOCATE TABLECURSOR 

END TRY
     
BEGIN CATCH
	SET @MSG=ERROR_MESSAGE()
	SET @MSG=@MSG + ' COMMAND : '+@CMD 
	SET @MSG=N' TIME '+@MSG+CONVERT(VARCHAR(50),GETDATE(),113); RAISERROR(@MSG, 0, 1) WITH NOWAIT;
END CATCH


SET @MSG='Rebuilding All Indexes Finished....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

GO


--==============================================================================================

-- Execute defragDB 
USE INFINITY_NI_97					--Change Database Name
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Begining Degrag DB Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

EXEC usp_defrag_db

SET @MSG='Finished Degrag DB Process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO

--===============================================================================================

-- Execute updatestats
USE [INFINITY_NI_97]				-- Change Database Name
GO

DECLARE @MSG VARCHAR(100)
SET @MSG='Begining sp_updatestats process....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT

EXEC sp_updatestats

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

ALTER DATABASE INFINITY_NI_97		-- Change Database Name
SET RECOVERY FULL 

SET @MSG='Recovery Model Changed to FULL....'+CONVERT(varchar(50),GETDATE(),113)
RAISERROR (@MSG,0,1) WITH NOWAIT
GO
--=================================================================================================

--Changing Database Compatibility level
USE [master]
GO
ALTER DATABASE [INFINITY_NI_97]		-- Change Database Name
SET COMPATIBILITY_LEVEL = 140		-- Change Compatibility Level as per instruction
GO
--=================================================================================================