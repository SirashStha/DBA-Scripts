DBCC CHECKDB('database_name') WITH NO_INFOMSGS;
GO

USE [master]
GO

ALTER DATABASE [database_name] SET  SINGLE_USER WITH NO_WAIT
GO

DBCC CHECKDB('database_name', REPAIR_REBUILD) WITH NO_INFOMSGS;
GO

ALTER DATABASE [database_name] SET MULTI_USER
GO

-- Gatishil
--DBCC CHECKDB('FINSYS_007_001') WITH NO_INFOMSGS;
--GO

----USE [master]
----GO

----ALTER DATABASE FINSYS_007_001 SET  SINGLE_USER WITH NO_WAIT
----GO

--DBCC CHECKDB('FINSYS_007_001', REPAIR_REBUILD) WITH NO_INFOMSGS;
--GO

--ALTER DATABASE FINSYS_007_001 SET MULTI_USER
--GO